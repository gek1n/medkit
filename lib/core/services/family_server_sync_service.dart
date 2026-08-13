import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/app_database.dart';
import '../../data/db/creator_info.dart';
import '../../data/repositories/family_peers_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../../data/repositories/reminders_repository.dart';
import 'activity_log_generator.dart';
import 'app_logger.dart';
import 'family_account.dart';
import 'family_api_client.dart';
import 'family_key_service.dart';
import 'family_visibility_service.dart';
import 'intake_generator.dart';
import 'notification_service.dart';
import 'peer_photo_service.dart';
import 'photo_service.dart';
import 'sync_crypto_service.dart';

/// Крок 11: сервер як джерело правди для сім'ї — заміна архівного
/// `FamilyPeerSyncService` (2363 рядки, star-topology hub-relay). Значна
/// частина СТАРОЇ складності (`_ping`, `known_member`/`request_introduction`/
/// `introduction`, `photo_request`/`photo_response`, `kickPeer`'s relay-фан-
/// аут через `_sendCard`, `_tombstoneEverythingFor`) тут просто НЕ ІСНУЄ —
/// не тому, що недороблено, а тому, що сама причина цієї складності
/// (анонімний capability-канал, який треба було встановлювати вручну через
/// пінги/картки) зникла:
/// - Канали більше не "знайомляться" — `FamilyController.materializeChannelsFor`
///   на сервері й [FamilyKeyService]+[_deterministicChannelId] на клієнті
///   НЕЗАЛЕЖНО обчислюють той самий канал+ключ через ECDH для БУДЬ-ЯКОЇ пари
///   активних учасників, щойно обидва бачать одне одного в `/family/status`.
/// - "Пір вийшов/виключений" більше не сигналізується relay-повідомленням —
///   сервер сам блокує push/pull для неактивних (`FamilySyncV2Controller::
///   requireChannelMember`), а цей сервіс сам помічає зникнення з
///   `/family/status` і прибирає локальний кеш (`_applyMembershipDiff`).
/// - Гранти пушаться/тягнуться напряму через сервер (`FamilyApiClient.
///   grantsPush`/`grantsPull`), не через вбудовану 'grants_summary' сутність.
/// - Фото — пряме `GET`-подібне `/family/photo` на вимогу, без
///   request/response-танцю через сутності.
///
/// Те, що ЛИШАЄТЬСЯ портованим майже без змін (транспорт-незалежна логіка,
/// перевірена в проді Кроками 5-7): [_rowsFor]/[_assignMissingUuids]
/// (які поля пушити), [proposeEdit]/[proposeRecord] (compare-and-swap
/// правки "за іншого").
class FamilyServerSyncService {
  final AppDatabase _db;
  final IntakeGenerator? _intakeGenerator;
  final ActivityLogGenerator? _activityLogGenerator;
  final RemindersRepository? _remindersRepository;
  final _api = const FamilyApiClient();

  // #320: три необов'язкові Riverpod-залежні сервіси — лише щоб одразу
  // після застосування record_proposal (створення "за іншого") запланувати
  // сповіщення для щойно вставленого запису (замість очікування наступного
  // відкриття Сьогодні/Розкладу, де ліки/рутини й так лінькво підхоплюються
  // IntakeGenerator/ActivityLogGenerator, а нагадування — ні, взагалі
  // ніколи без цього виклику). Приймаємо ГОТОВІ інстанси (а не `Ref`) —
  // `WidgetRef` (звідки конструюється цей сервіс на більшості call site'ів)
  // НЕ присвоюється до типу `Ref`, тож викликач сам робить
  // `ref.read(...Provider)` і передає результат. Виклики без цих
  // параметрів (є й досі) просто пропускають миттєве планування — без
  // регресії, лише без миттєвого сповіщення (ліки/рутини все одно
  // підхопляться лінивими генераторами пізніше).
  FamilyServerSyncService(
    this._db, {
    this._intakeGenerator,
    this._activityLogGenerator,
    this._remindersRepository,
  });

  static const _entityTypes = [
    'medication',
    'schedule',
    'intake',
    'activity',
    'activity_slot',
    'activity_assignee',
    'activity_log',
    'wellbeing_log',
    'wellbeing_schedule',
    'doctor_appointment',
    'reminder_log',
    'reminder_slot',
    'medcard_section',
    'medcard_entry',
  ];

  static const _alwaysSyncedTypes = {
    'medication',
    'schedule',
    'intake',
    'activity',
    'activity_slot',
    'activity_assignee',
    'activity_log',
    'doctor_appointment',
    'reminder_log',
    'reminder_slot',
  };

  static const _recentWindow = Duration(days: 2);
  static const _wellbeingWindow = Duration(days: 7);
  static const _windowedTypes = {'intake', 'activity_log', 'reminder_log', 'wellbeing_log'};

  static const _recordProposalTypes = {
    'medication',
    'activity',
    'doctor_appointment',
    'wellbeing_schedule',
    'medcard_entry',
    'medcard_section',
    'activity_log',
  };

  static const Map<String, String> _notesFields = {
    'medication': 'instructions',
    'doctor_appointment': 'notes',
  };

  // Типи із власними вкладеннями (фото/PDF) — назва поля, де JSON-список
  // відносних шляхів (той самий формат, що DocumentsSection/PhotoService
  // всюди в застосунку). Самі БАЙТИ пушаться окремо від entity-json (див.
  // _pushToChannel нижче) — entity-json і так уже несе ці шляхи як текст,
  // тут лише додатково довантажуємо байти під ті самі шляхи.
  static const Map<String, String> _photoPathFields = {
    'medication': 'photoPaths',
    'medcard_entry': 'documentPaths',
    'activity': 'documentPaths',
    'doctor_appointment': 'documentPaths',
  };

  static const _uuid = Uuid();

  // ── Точка входу ──────────────────────────────────────────────────────

  /// Один повний раунд синку: status() → push у кожен активний канал →
  /// один /family/sync pull → apply → гранти → покидьки, чиї канали
  /// зникли з status(). Викликається на тих самих тригерах, що вже
  /// перевірені в проді для білінгу (`_billingSyncIfNeeded`, resume/
  /// cold-start) — `main.dart` за прапорцем `AppEnv.isTestBuild` (Крок 11.2/C3).
  Future<void> syncAll() async {
    final account = await ensureFamilyAccount();
    FamilyStatusResult status;
    try {
      status = await _api.status(accountId: account.accountId, recoveryKeyHash: account.recoveryKeyHash);
    } catch (e, st) {
      AppLogger.logError('FamilyServerSyncService.syncAll.status', e, st);
      return;
    }
    await _cacheStatus(status);
    if (status.families.isEmpty) {
      await _applyMembershipDiff(status);
      return;
    }

    // Навмисно ПОСЛІДОВНО (await у циклі, не Future.wait) — бекенд це
    // звичайний PHP-FPM на shared cPanel-хостингу з обмеженою кількістю
    // воркерів; паралельні запити з ОДНОГО пристрою множаться на кількість
    // пристроїв, що синкаються одночасно (напр. усі відкрили застосунок
    // зранку) — послідовні запити розтягують навантаження в часі замість
    // пікового сплеску. `_pushToChannel` і так рано виходить без мережевого
    // виклику, якщо для каналу нічого нового (entities.isEmpty), тож
    // "порожні" канали не додають реальної затримки.
    for (final family in status.families) {
      for (final channel in family.channels) {
        final counterpart = family.members.where((m) => m.accountId == channel.counterpartAccountId).firstOrNull;
        if (counterpart == null || counterpart.publicKeyHex.isEmpty) continue;
        try {
          final key = await FamilyKeyService.sharedChannelKey(counterpart.publicKeyHex);
          await _pushToChannel(channel.channelId, key, account.accountId, counterpart.personUuid);
        } catch (e, st) {
          AppLogger.logError(
              'FamilyServerSyncService.syncAll.push(channelId=${channel.channelId})', e, st);
        }
      }
    }
    try {
      final since = await _lastSyncCursor();
      final result = await _api.sync(accountId: account.accountId, since: since);
      await _applyPulledEntities(result, status);
      await _setLastSyncCursor(DateTime.now());
    } catch (e, st) {
      AppLogger.logError('FamilyServerSyncService.syncAll.pull', e, st);
    }

    await _syncGrants(account.accountId, status);
    await _applyMembershipDiff(status);
    await _scheduleMissedChecksAll(status);
  }

  // ── Курсор синку (SharedPreferences, той самий підхід, що вже був
  // у `_previouslyPushed`/`FamilyPeerSyncService`) ────────────────────────

  static const _lastSyncKey = 'family_v2_last_sync_iso';

  Future<DateTime?> _lastSyncCursor() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSyncKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> _setLastSyncCursor(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, value.toUtc().toIso8601String());
  }

  // ── Кеш останнього /family/status — читає UI (family_status_provider.dart)
  // ── без мережевого виклику ────────────────────────────────────────────
  // На відміну від архівної FamilyPeers-таблиці (окрема Drift-таблиця,
  // потребувала б власної міграції) — простий SharedPreferences-кеш,
  // той самий підхід, що вже виправдав себе для SubscriptionService.
  // cachedPlan()/refreshFromServer(): провайдер читає лише кеш (синхронно,
  // без мережі), а syncAll()/pushGrantsNow() оновлюють кеш і викликач
  // (main.dart) інвалідує провайдер — той самий контракт, що й realPlanProvider.

  static const _statusCacheKey = 'family_v2_status_cache';

  Future<void> _cacheStatus(FamilyStatusResult status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusCacheKey, jsonEncode(status.toJson()));
  }

  static Future<FamilyStatusResult?> cachedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statusCacheKey);
    if (raw == null) return null;
    try {
      return FamilyStatusResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Push: мої субʼєкти → цей канал, лише те, що дозволено ───────────────
  // Портовано майже 1:1 з архівного _push() — грант-фільтрація й формат
  // payload'у транспорт-незалежні, змінюється лише сам виклик push().

  String _pushedKey(String channelId) => 'family_v2_pushed_$channelId';

  DateTime? _parseDateAny(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // id → значення updatedAt рядка НА МОМЕНТ останнього успішного пуша (не
  // просто "чи пушили колись") — інакше жодна ЗМІНА вже раз запушеної
  // сутності (markAttended/markTaken, редагування нотатки, дози тощо)
  // ніколи більше не пуситься: uuid рядка не міняється при UPDATE, тож
  // "чи є id в сеті" лишалось би true назавжди після першого пуша. Формат
  // старого кешу (JSON-список id) читаємо як порожню мапу — самолікується
  // одним зайвим повним пушем при першому запуску після оновлення.
  Future<Map<String, String>> _previouslyPushed(String channelId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pushedKey(channelId));
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded.cast<String, String>();
    } catch (_) {}
    return {};
  }

  Future<void> _setPreviouslyPushed(String channelId, Map<String, String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pushedKey(channelId), jsonEncode(ids));
  }

  // ── Той самий diff-принцип, окремо для байтів фото/вкладень — photo_id
  // (не uuid запису) — стабільний ключ, байти під ним ніколи не міняються
  // "на місці" (нове фото = новий шлях = новий photo_id), тож досить
  // множини (не потрібна версія на кшталт updatedAt для entity-diff вище).

  String _pushedPhotosKey(String channelId) => 'family_v2_pushed_photos_$channelId';

  Future<Set<String>> _previouslyPushedPhotos(String channelId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pushedPhotosKey(channelId));
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as List).cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _setPreviouslyPushedPhotos(String channelId, Set<String> photoIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pushedPhotosKey(channelId), jsonEncode(photoIds.toList()));
  }

  /// [counterpartPersonUuid]/[channelId] однозначно ідентифікують піра — на
  /// відміну від архіву тут немає окремого FamilyPeer-рядка з lastSyncedAt
  /// per-channel: since тепер ОДИН глобальний курсор (`_lastSyncCursor`)
  /// для всього /family/sync, тож diff нижче спирається лише на
  /// previouslyPushed (не на since) — так само надійно, трохи менш
  /// економно (у гіршому разі перепушить трохи зайвого після довгої
  /// перерви), прийнятний компроміс заради простоти.
  Future<void> _pushToChannel(
    String channelId,
    SecretKey key,
    String myAccountId,
    String counterpartPersonUuid,
  ) async {
    // Пір автономного члена сім'ї бачить ЛИШЕ мій власний профіль (role ==
    // 'owner'), ніколи локальних dependent'ів — навіть якщо суб'єктом гранту
    // технічно міг би бути dependent, у Кроку 11 dependent'и взагалі не
    // мають персонального account_id/каналу, тож ділитись їхніми даними з
    // автономним учасником немає сенсу і небезпечно (їхні дані лишаються
    // виключно на цьому пристрої).
    final owner = await MembersRepository(_db).getOwner();
    final previouslyPushed = await _previouslyPushed(channelId);
    final currentIds = <String, String>{};
    final entities = <Map<String, dynamic>>[];
    // Відносні шляхи фото/вкладень, на які зараз посилаються дозволені
    // записи — зібрані тут же, в тому самому проході по рядках, щоб не
    // робити другий прохід/другий запит до бази.
    final currentPhotoPaths = <String>{};

    if (owner != null && owner.personUuid != null) {
      final subjectUuid = owner.personUuid!;
      await _assignMissingUuids(owner.id);

      for (final type in _entityTypes) {
        final section = _alwaysSyncedTypes.contains(type)
            ? FamilySection.schedule
            : (type == 'medcard_entry' || type == 'medcard_section')
                ? FamilySection.shelves
                : FamilySection.medcard;
        final allowed = await FamilyVisibilityService.isSectionAllowed(
          _db,
          subjectUuid,
          counterpartPersonUuid,
          section,
          edit: false,
        );
        if (!allowed) continue;

        final photoField = _photoPathFields[type];

        final rows = await _rowsFor(type, owner.id);
        for (final row in rows) {
          if (photoField != null) {
            try {
              final paths = List<String>.from(jsonDecode(row[photoField] as String? ?? '[]') as List);
              currentPhotoPaths.addAll(paths);
            } catch (_) {}
          }

          final id = '$subjectUuid|$type|${row['uuid']}';
          // '' (немає власного updatedAt, напр. ActivityAssignees) завжди
          // трактується як "змінилось" — безпечний дефолт замість вигаданої
          // версії, цей рядок просто пуситься щоразу (дешево, малий обсяг).
          final version = row['updatedAt']?.toString() ?? '';
          currentIds[id] = version;
          final changed = version.isEmpty || previouslyPushed[id] != version;
          if (!changed) continue;

          final json = Map<String, dynamic>.from(row)
            ..['subjectPersonUuid'] = subjectUuid
            ..['subjectName'] = owner.name
            ..['subjectAvatarIndex'] = owner.avatarIndex;
          entities.add({
            'type': type,
            'uuid': row['uuid'],
            'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
          });
        }
        if (_windowedTypes.contains(type)) {
          for (final uuid in await _existingUuidsFor(type, owner.id)) {
            final id = '$subjectUuid|$type|$uuid';
            // Поза поточним вікном _rowsFor, але ще існує локально — лишаємо
            // в currentIds (щоб не потрапив у tombstone-diff нижче), версію
            // переносимо з попереднього разу як є, без переоцінки "чи змінився".
            currentIds[id] = previouslyPushed[id] ?? '';
          }
        }
      }
    }

    for (final goneId in previouslyPushed.keys.toSet().difference(currentIds.keys.toSet())) {
      final parts = goneId.split('|');
      if (parts.length != 3) continue;
      entities.add({'type': parts[1], 'uuid': parts[2], 'ciphertext': '', 'deleted': true});
    }

    // ── Фото: байти НЕ входять у entity-json вище (те саме, що вже й так
    // містить самі шляхи як текст) — окремий "photos" payload під тим самим
    // ключем /family/push уже приймає. Пушимо лише НОВІ (ще не пушені)
    // photo_id — байти зображення ніколи не змінюються "на місці", тож
    // повторний пуш того самого шляху не потрібен; зниклі (видалені з усіх
    // записів) — тумбстоунимо так само, як і сутності.
    final previouslyPushedPhotos = await _previouslyPushedPhotos(channelId);
    final currentPhotoIds = <String>{};
    final photos = <Map<String, dynamic>>[];
    for (final path in currentPhotoPaths) {
      final photoId = await photoIdFor(path);
      currentPhotoIds.add(photoId);
      if (previouslyPushedPhotos.contains(photoId)) continue;
      try {
        final plainBytes = await PhotoService.decryptedBytes(path);
        final encryptedBytes = await SyncCryptoService.encryptBytes(key, plainBytes);
        // Сервер відкидає ВЕСЬ чанк, якщо хоч одне фото завелике
        // (FamilySyncV2Controller::MAX_PHOTO_BYTES = 8МБ) — пропускаємо
        // саме це фото заздалегідь, а не ламаємо пуш решти через один
        // застарий/нестиснутий PDF чи оригінал.
        if (encryptedBytes.length <= 8 * 1024 * 1024) {
          photos.add({'photo_id': photoId, 'bytes': base64Encode(encryptedBytes)});
        }
      } catch (e, st) {
        // Файл міг бути видалений з диска, ще не докачаний тощо — пропускаємо
        // це ОДНЕ фото, не обриваємо пуш решти сутностей/фото.
        AppLogger.logError('FamilyServerSyncService.pushPhoto(path=$path)', e, st);
      }
    }
    for (final goneId in previouslyPushedPhotos.difference(currentPhotoIds)) {
      photos.add({'photo_id': goneId, 'deleted': true});
    }

    if (entities.isEmpty && photos.isEmpty) return;

    for (var i = 0; i < entities.length; i += 500) {
      final chunk = entities.sublist(i, i + 500 > entities.length ? entities.length : i + 500);
      await _api.push(accountId: myAccountId, channelId: channelId, entities: chunk);
    }
    for (var i = 0; i < photos.length; i += 100) {
      final chunk = photos.sublist(i, i + 100 > photos.length ? photos.length : i + 100);
      await _api.push(accountId: myAccountId, channelId: channelId, photos: chunk);
    }
    await _setPreviouslyPushed(channelId, currentIds);
    await _setPreviouslyPushedPhotos(channelId, currentPhotoIds);
  }

  // ── Присвоєння syncUuid — портовано 1:1 з архіву ─────────────────────

  Future<void> _assignMissingUuids(int memberId) async {
    Future<void> medications() async {
      final rows = await (_db.select(_db.medications)
            ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
          .get();
      for (final r in rows) {
        await (_db.update(_db.medications)..where((t) => t.id.equals(r.id)))
            .write(MedicationsCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> schedules() async {
      final query = _db.select(_db.schedules).join([
        innerJoin(_db.medications, _db.medications.id.equalsExp(_db.schedules.medicationId)),
      ])
        ..where(_db.medications.memberId.equals(memberId) & _db.schedules.syncUuid.isNull());
      for (final r in await query.get()) {
        final s = r.readTable(_db.schedules);
        await (_db.update(_db.schedules)..where((t) => t.id.equals(s.id)))
            .write(SchedulesCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> intakes() async {
      final rows = await (_db.select(_db.intakes)
            ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
          .get();
      for (final r in rows) {
        await (_db.update(_db.intakes)..where((t) => t.id.equals(r.id)))
            .write(IntakesCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> activities() async {
      final rows = await (_db.select(_db.activities)
            ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
          .get();
      for (final r in rows) {
        await (_db.update(_db.activities)..where((t) => t.id.equals(r.id)))
            .write(ActivitiesCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> activitySlots() async {
      final query = _db.select(_db.activitySlots).join([
        innerJoin(_db.activities, _db.activities.id.equalsExp(_db.activitySlots.activityId)),
      ])
        ..where(_db.activities.memberId.equals(memberId) & _db.activitySlots.syncUuid.isNull());
      for (final r in await query.get()) {
        final s = r.readTable(_db.activitySlots);
        await (_db.update(_db.activitySlots)..where((t) => t.id.equals(s.id)))
            .write(ActivitySlotsCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> activityLogs() async {
      final rows = await (_db.select(_db.activityLogs)
            ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
          .get();
      for (final r in rows) {
        await (_db.update(_db.activityLogs)..where((t) => t.id.equals(r.id)))
            .write(ActivityLogsCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> wellbeingLogs() async {
      final rows = await (_db.select(_db.wellbeingLogs)
            ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
          .get();
      for (final r in rows) {
        await (_db.update(_db.wellbeingLogs)..where((t) => t.id.equals(r.id)))
            .write(WellbeingLogsCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> wellbeingSchedules() async {
      final rows = await (_db.select(_db.wellbeingSchedules)
            ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
          .get();
      for (final r in rows) {
        await (_db.update(_db.wellbeingSchedules)..where((t) => t.id.equals(r.id)))
            .write(WellbeingSchedulesCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> flat(String table) async {
      switch (table) {
        case 'doctor_appointment':
          final rows = await (_db.select(_db.reminders)
                ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
              .get();
          for (final r in rows) {
            await (_db.update(_db.reminders)..where((t) => t.id.equals(r.id)))
                .write(RemindersCompanion(syncUuid: Value(_uuid.v4())));
          }
        case 'medcard_section':
          final rows = await (_db.select(_db.medcardSections)
                ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
              .get();
          for (final r in rows) {
            await (_db.update(_db.medcardSections)..where((t) => t.id.equals(r.id)))
                .write(MedcardSectionsCompanion(syncUuid: Value(_uuid.v4())));
          }
        case 'reminder_log':
          final rows = await (_db.select(_db.reminderLogs)
                ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
              .get();
          for (final r in rows) {
            await (_db.update(_db.reminderLogs)..where((t) => t.id.equals(r.id)))
                .write(ReminderLogsCompanion(syncUuid: Value(_uuid.v4())));
          }
      }
    }

    Future<void> medcardEntries() async {
      final rows = await (_db.select(_db.medcardEntries)
            ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
          .get();
      for (final r in rows) {
        await (_db.update(_db.medcardEntries)..where((t) => t.id.equals(r.id)))
            .write(MedcardEntriesCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> reminderSlots() async {
      final query = _db.select(_db.reminderSlots).join([
        innerJoin(_db.reminders, _db.reminders.id.equalsExp(_db.reminderSlots.reminderId)),
      ])
        ..where(_db.reminders.memberId.equals(memberId) & _db.reminderSlots.syncUuid.isNull());
      for (final r in await query.get()) {
        final s = r.readTable(_db.reminderSlots);
        await (_db.update(_db.reminderSlots)..where((t) => t.id.equals(s.id)))
            .write(ReminderSlotsCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    await medications();
    await schedules();
    await intakes();
    await activities();
    await activitySlots();
    await activityLogs();
    await wellbeingLogs();
    await wellbeingSchedules();
    await medcardEntries();
    await reminderSlots();
    for (final t in const ['doctor_appointment', 'medcard_section', 'reminder_log']) {
      await flat(t);
    }
  }

  Future<String?> _medicationSyncUuidFor(int medicationId) async {
    final row = await (_db.select(_db.medications)..where((t) => t.id.equals(medicationId))).getSingleOrNull();
    return row?.syncUuid;
  }

  Future<String?> _scheduleSyncUuidFor(int scheduleId) async {
    final row = await (_db.select(_db.schedules)..where((t) => t.id.equals(scheduleId))).getSingleOrNull();
    return row?.syncUuid;
  }

  Future<String?> _reminderSyncUuidFor(int reminderId) async {
    final row = await (_db.select(_db.reminders)..where((t) => t.id.equals(reminderId))).getSingleOrNull();
    return row?.syncUuid;
  }

  Future<String?> _medcardSectionSyncUuidFor(int sectionId) async {
    final row = await (_db.select(_db.medcardSections)..where((t) => t.id.equals(sectionId))).getSingleOrNull();
    return row?.syncUuid;
  }

  Future<String?> _sectionSyncUuidOrNull(int? sectionId) =>
      sectionId == null ? Future.value(null) : _medcardSectionSyncUuidFor(sectionId);

  Map<String, dynamic> _withUuid(Map<String, dynamic> json, String uuid) {
    json['uuid'] = uuid;
    json.remove('id');
    json.remove('memberId');
    json.remove('syncUuid');
    return json;
  }

  /// Портовано 1:1 з архівного `family_peer_sync_service.dart::_rowsFor` —
  /// транспорт-незалежна, вже перевірена в проді Кроками 5-7 (Полички,
  /// позначки виконано/пропущено, побічні ефекти, ротація).
  Future<List<Map<String, dynamic>>> _rowsFor(String type, int memberId) async {
    final recentCutoff = DateTime.now().subtract(_recentWindow);
    final wellbeingCutoff = DateTime.now().subtract(_wellbeingWindow);

    switch (type) {
      case 'medication':
        final rows = await (_db.select(_db.medications)..where((t) => t.memberId.equals(memberId))).get();
        final result = <Map<String, dynamic>>[];
        for (final r in rows) {
          if (r.syncUuid == null) continue;
          final json = _withUuid(r.toJson(), r.syncUuid!)..remove('sectionId');
          json['sectionSyncUuid'] = await _sectionSyncUuidOrNull(r.sectionId);
          await _addCreatorFields(json, 'medication', r.id);
          result.add(json);
        }
        return result;
      case 'schedule':
        final query = _db.select(_db.schedules).join([
          innerJoin(_db.medications, _db.medications.id.equalsExp(_db.schedules.medicationId)),
        ])
          ..where(_db.medications.memberId.equals(memberId));
        final result = <Map<String, dynamic>>[];
        for (final r in await query.get()) {
          final s = r.readTable(_db.schedules);
          final med = r.readTable(_db.medications);
          if (s.syncUuid == null || med.syncUuid == null) continue;
          final json = _withUuid(s.toJson(), s.syncUuid!)..remove('medicationId');
          json['medicationSyncUuid'] = med.syncUuid;
          result.add(json);
        }
        return result;
      case 'intake':
        final rows = await (_db.select(_db.intakes)
              ..where((t) =>
                  t.memberId.equals(memberId) &
                  (t.scheduledAt.isBiggerOrEqualValue(recentCutoff) |
                      t.updatedAt.isBiggerOrEqualValue(recentCutoff))))
            .get();
        final result = <Map<String, dynamic>>[];
        for (final i in rows) {
          if (i.syncUuid == null) continue;
          final medUuid = await _medicationSyncUuidFor(i.medicationId);
          final schedUuid = await _scheduleSyncUuidFor(i.scheduleId);
          if (medUuid == null || schedUuid == null) continue;
          final json = _withUuid(i.toJson(), i.syncUuid!)
            ..remove('medicationId')
            ..remove('scheduleId');
          json['medicationSyncUuid'] = medUuid;
          json['scheduleSyncUuid'] = schedUuid;
          result.add(json);
        }
        return result;
      case 'activity':
        final rows = await (_db.select(_db.activities)..where((t) => t.memberId.equals(memberId))).get();
        final result = <Map<String, dynamic>>[];
        for (final r in rows) {
          if (r.syncUuid == null) continue;
          final json = _withUuid(r.toJson(), r.syncUuid!)..remove('sectionId');
          json['sectionSyncUuid'] = await _sectionSyncUuidOrNull(r.sectionId);
          await _addCreatorFields(json, 'activity', r.id);
          result.add(json);
        }
        return result;
      case 'activity_slot':
        final query = _db.select(_db.activitySlots).join([
          innerJoin(_db.activities, _db.activities.id.equalsExp(_db.activitySlots.activityId)),
        ])
          ..where(_db.activities.memberId.equals(memberId));
        final result = <Map<String, dynamic>>[];
        for (final r in await query.get()) {
          final slot = r.readTable(_db.activitySlots);
          final act = r.readTable(_db.activities);
          if (slot.syncUuid == null || act.syncUuid == null) continue;
          final json = _withUuid(slot.toJson(), slot.syncUuid!)..remove('activityId');
          json['activitySyncUuid'] = act.syncUuid;
          result.add(json);
        }
        return result;
      case 'activity_assignee':
        final query = _db.select(_db.activityAssignees).join([
          innerJoin(_db.activities, _db.activities.id.equalsExp(_db.activityAssignees.activityId)),
          innerJoin(_db.members, _db.members.id.equalsExp(_db.activityAssignees.memberId)),
        ])
          ..where(_db.activities.memberId.equals(memberId));
        final result = <Map<String, dynamic>>[];
        for (final r in await query.get()) {
          final assignee = r.readTable(_db.activityAssignees);
          final act = r.readTable(_db.activities);
          final assigneeMember = r.readTable(_db.members);
          if (act.syncUuid == null) continue;
          final identity = assigneeMember.linkedPeerPersonUuid ?? 'm${assigneeMember.id}';
          result.add({
            'uuid': _stableUuid('${act.syncUuid}:$identity'),
            'activitySyncUuid': act.syncUuid,
            'sortOrder': assignee.sortOrder,
            'name': assigneeMember.name,
            'avatarIndex': assigneeMember.avatarIndex,
            'assigneeLinkedPeerPersonUuid': assigneeMember.linkedPeerPersonUuid,
            'updatedAt': act.updatedAt.toIso8601String(),
          });
        }
        return result;
      case 'activity_log':
        final query = _db.select(_db.activityLogs).join([
          innerJoin(_db.activities, _db.activities.id.equalsExp(_db.activityLogs.activityId)),
        ])
          ..where(_db.activities.memberId.equals(memberId) &
              (_db.activityLogs.scheduledAt.isBiggerOrEqualValue(recentCutoff) |
                  _db.activityLogs.updatedAt.isBiggerOrEqualValue(recentCutoff)));
        final result = <Map<String, dynamic>>[];
        for (final r in await query.get()) {
          final l = r.readTable(_db.activityLogs);
          final act = r.readTable(_db.activities);
          if (l.syncUuid == null || act.syncUuid == null) continue;
          final assigneeMember =
              await (_db.select(_db.members)..where((t) => t.id.equals(l.memberId))).getSingleOrNull();
          final json = _withUuid(l.toJson(), l.syncUuid!)..remove('activityId');
          json['activitySyncUuid'] = act.syncUuid;
          json['assigneeIdentity'] = assigneeMember?.linkedPeerPersonUuid ?? 'm${l.memberId}';
          json['assigneeName'] = assigneeMember?.name;
          json['assigneeAvatarIndex'] = assigneeMember?.avatarIndex;
          result.add(json);
        }
        return result;
      case 'wellbeing_log':
        final rows = await (_db.select(_db.wellbeingLogs)
              ..where((t) =>
                  t.memberId.equals(memberId) &
                  (t.loggedAt.isBiggerOrEqualValue(wellbeingCutoff) |
                      t.updatedAt.isBiggerOrEqualValue(wellbeingCutoff))))
            .get();
        return rows.where((r) => r.syncUuid != null).map((r) => _withUuid(r.toJson(), r.syncUuid!)).toList();
      case 'wellbeing_schedule':
        final rows = await (_db.select(_db.wellbeingSchedules)..where((t) => t.memberId.equals(memberId))).get();
        final wsResult = <Map<String, dynamic>>[];
        for (final r in rows) {
          if (r.syncUuid == null) continue;
          final json = _withUuid(r.toJson(), r.syncUuid!)..remove('sectionId');
          json['sectionSyncUuid'] = await _sectionSyncUuidOrNull(r.sectionId);
          wsResult.add(json);
        }
        return wsResult;
      case 'doctor_appointment':
        final rows = await (_db.select(_db.reminders)..where((t) => t.memberId.equals(memberId))).get();
        final daResult = <Map<String, dynamic>>[];
        for (final r in rows) {
          if (r.syncUuid == null) continue;
          final json = _withUuid(r.toJson(), r.syncUuid!)..remove('sectionId');
          json['sectionSyncUuid'] = await _sectionSyncUuidOrNull(r.sectionId);
          await _addCreatorFields(json, 'doctor_appointment', r.id);
          daResult.add(json);
        }
        return daResult;
      case 'reminder_log':
        final rows = await (_db.select(_db.reminderLogs)
              ..where((t) =>
                  t.memberId.equals(memberId) &
                  (t.scheduledAt.isBiggerOrEqualValue(recentCutoff) |
                      t.updatedAt.isBiggerOrEqualValue(recentCutoff))))
            .get();
        final result = <Map<String, dynamic>>[];
        for (final l in rows) {
          if (l.syncUuid == null) continue;
          final reminderUuid = await _reminderSyncUuidFor(l.reminderId);
          if (reminderUuid == null) continue;
          final json = _withUuid(l.toJson(), l.syncUuid!)..remove('reminderId');
          json['reminderSyncUuid'] = reminderUuid;
          result.add(json);
        }
        return result;
      case 'reminder_slot':
        final rows = await (_db.select(_db.reminderSlots).join([
          innerJoin(_db.reminders, _db.reminders.id.equalsExp(_db.reminderSlots.reminderId)),
        ])..where(_db.reminders.memberId.equals(memberId))).get();
        final slotResult = <Map<String, dynamic>>[];
        for (final r in rows) {
          final s = r.readTable(_db.reminderSlots);
          if (s.syncUuid == null) continue;
          final reminderUuid = await _reminderSyncUuidFor(s.reminderId);
          if (reminderUuid == null) continue;
          final json = _withUuid(s.toJson(), s.syncUuid!)..remove('reminderId');
          json['reminderSyncUuid'] = reminderUuid;
          slotResult.add(json);
        }
        return slotResult;
      case 'medcard_section':
        final rows = await (_db.select(_db.medcardSections)..where((t) => t.memberId.equals(memberId))).get();
        return rows.where((r) => r.syncUuid != null).map((r) => _withUuid(r.toJson(), r.syncUuid!)).toList();
      case 'medcard_entry':
        final rows = await (_db.select(_db.medcardEntries)..where((t) => t.memberId.equals(memberId))).get();
        final result = <Map<String, dynamic>>[];
        for (final e in rows) {
          if (e.syncUuid == null) continue;
          final sectionUuid = await _medcardSectionSyncUuidFor(e.sectionId);
          if (sectionUuid == null) continue;
          final json = _withUuid(e.toJson(), e.syncUuid!)..remove('sectionId');
          json['sectionSyncUuid'] = sectionUuid;
          await _addCreatorFields(json, 'medcard_entry', e.id);
          result.add(json);
        }
        return result;
    }
    return const [];
  }

  /// #324 (доробка "видно піру"): createdByPersonUuid/createdByName/
  /// createdByAvatarIndex НЕ фізичні колонки цих таблиць (окрема
  /// record_creators, див. lib/data/db/creator_info.dart — codegen у цьому
  /// середовищі зламаний, детальніше там), тож r.toJson() їх не підхоплює
  /// автоматично — домальовуємо вручну в те саме json, яке й так вже
  /// патчиться (..remove('sectionId') і т.п.) для кожного з 4 типів, що
  /// мають footer "Створив(ла)" на екрані перегляду.
  Future<void> _addCreatorFields(Map<String, dynamic> json, String entityType, int localId) async {
    final creator = await lookupCreator(_db, entityType, localId);
    if (creator == null) return;
    json['createdByPersonUuid'] = creator.personUuid;
    json['createdByName'] = creator.name;
    json['createdByAvatarIndex'] = creator.avatarIndex;
  }

  Future<Set<String>> _existingUuidsFor(String type, int memberId) async {
    switch (type) {
      case 'intake':
        final rows = await (_db.select(_db.intakes)..where((t) => t.memberId.equals(memberId))).get();
        return rows.where((r) => r.syncUuid != null).map((r) => r.syncUuid!).toSet();
      case 'activity_log':
        final query = _db.select(_db.activityLogs).join([
          innerJoin(_db.activities, _db.activities.id.equalsExp(_db.activityLogs.activityId)),
        ])
          ..where(_db.activities.memberId.equals(memberId));
        final result = <String>{};
        for (final r in await query.get()) {
          final l = r.readTable(_db.activityLogs);
          if (l.syncUuid != null) result.add(l.syncUuid!);
        }
        return result;
      case 'reminder_log':
        final rows = await (_db.select(_db.reminderLogs)..where((t) => t.memberId.equals(memberId))).get();
        return rows.where((r) => r.syncUuid != null).map((r) => r.syncUuid!).toSet();
      case 'wellbeing_log':
        final rows = await (_db.select(_db.wellbeingLogs)..where((t) => t.memberId.equals(memberId))).get();
        return rows.where((r) => r.syncUuid != null).map((r) => r.syncUuid!).toSet();
    }
    return const {};
  }

  static String _stableUuid(String seed) => const Uuid().v5(Namespace.url.value, seed);

  // ── Pull: entities з /family/sync → SharedSubjects/SharedEntities ───────

  Future<void> _applyPulledEntities(FamilySyncPullResult result, FamilyStatusResult status) async {
    final repo = FamilyPeersRepository(_db);
    final pendingDeletes = <String>[];
    final pendingUpserts = <({SharedSubjectsCompanion subject, SharedEntitiesCompanion entity})>[];
    final proposalsToApply = <(String type, Map<String, dynamic> json, String fromChannelId)>[];

    // channel_id → account_id контрагента (для record_proposal/edit_proposal
    // атрибуції "від кого") — з усіх моїх сімей одразу.
    final counterpartByChannel = <String, String>{};
    for (final family in status.families) {
      for (final channel in family.channels) {
        counterpartByChannel[channel.channelId] = channel.counterpartAccountId;
      }
    }

    if (result.entities.isNotEmpty) {
      AppLogger.log(
          'FamilyServerSyncService._applyPulledEntities: got ${result.entities.length} entities across ${result.entities.map((e) => e.channelId).toSet().length} channel(s)');
    }

    for (final entity in result.entities) {
      final counterpartAccountId = counterpartByChannel[entity.channelId];
      if (counterpartAccountId == null) continue; // канал більше не мій (вийшов/виключений)

      if (entity.type == 'edit_proposal' || entity.type == 'record_proposal') {
        if (entity.deleted) continue;
        proposalsToApply.add((entity.type, {'ciphertext': entity.ciphertext}, entity.channelId));
        continue;
      }
      if (entity.deleted) {
        pendingDeletes.add(entity.uuid);
        continue;
      }

      // Розшифрувати можемо, лише знаючи ключ каналу — обчислюємо з
      // public_key контрагента (той самий, що й при push).
      final counterpart = status.families
          .expand((f) => f.members)
          .where((m) => m.accountId == counterpartAccountId)
          .firstOrNull;
      if (counterpart == null || counterpart.publicKeyHex.isEmpty) continue;
      final key = await FamilyKeyService.sharedChannelKey(counterpart.publicKeyHex);

      Map<String, dynamic> json;
      try {
        json = await SyncCryptoService.decryptEntity(key, entity.ciphertext);
      } catch (_) {
        continue;
      }

      if (entity.type == 'remind_now') {
        await _handleRemoteReminder(json, entity.updatedAt);
        continue;
      }

      final subjectUuid = json['subjectPersonUuid'] as String?;
      if (subjectUuid == null) continue;

      pendingUpserts.add((
        subject: SharedSubjectsCompanion.insert(
          personUuid: subjectUuid,
          peerChannelId: entity.channelId,
          name: json['subjectName'] as String? ?? counterpart.name,
          avatarIndex: Value(json['subjectAvatarIndex'] as int? ?? counterpart.avatarIndex),
        ),
        entity: SharedEntitiesCompanion.insert(
          subjectPersonUuid: subjectUuid,
          entityType: entity.type,
          uuid: entity.uuid,
          dataJson: jsonEncode(json),
          updatedAt: Value(DateTime.now()),
        ),
      ));
    }

    // Один transaction() — один коміт (07.08 фікс "миготіння" на Сьогодні/
    // Розкладі, той самий підхід, що й в архіві).
    if (pendingDeletes.isNotEmpty || pendingUpserts.isNotEmpty) {
      await _db.transaction(() async {
        for (final uuid in pendingDeletes) {
          await repo.deleteSharedEntity(uuid);
        }
        for (final p in pendingUpserts) {
          await repo.upsertSharedSubject(p.subject);
          await repo.upsertSharedEntity(p.entity);
        }
      });
    }

    // proposal-обробка — окремо, ПІСЛЯ основного транзакшена (може сама
    // писати в Members-повʼязані таблиці, не лише в SharedEntities).
    for (final (type, wrapped, channelId) in proposalsToApply) {
      final counterpartAccountId = counterpartByChannel[channelId];
      if (counterpartAccountId == null) continue;
      final counterpart =
          status.families.expand((f) => f.members).where((m) => m.accountId == counterpartAccountId).firstOrNull;
      if (counterpart == null || counterpart.publicKeyHex.isEmpty) continue;
      final key = await FamilyKeyService.sharedChannelKey(counterpart.publicKeyHex);
      Map<String, dynamic> json;
      try {
        json = await SyncCryptoService.decryptEntity(key, wrapped['ciphertext'] as Uint8List);
      } catch (_) {
        continue;
      }
      if (type == 'edit_proposal') {
        await _applyEditProposal(json, counterpart);
      } else {
        await _applyRecordProposal(json, counterpart);
      }
    }
  }

  // ── Гранти: сервер тепер джерело правди, не вбудована сутність ─────────

  /// Викликається наприкінці [syncAll], а також окремо одразу після
  /// редагування на екрані "Видимість для сім'ї" (той самий принцип
  /// негайного push, що вже був у `proposeRecord`). Тут (на відміну від
  /// [syncAll]) немає щойно отриманого [FamilyStatusResult] під рукою —
  /// звертаємось по свіжий, дешевий виклик (`status()` — легкий lookup,
  /// не похід до Apple/Google).
  Future<void> pushGrantsNow() async {
    final account = await ensureFamilyAccount();
    try {
      final status = await _api.status(accountId: account.accountId, recoveryKeyHash: account.recoveryKeyHash);
      await _cacheStatus(status);
      await _syncGrants(account.accountId, status);
    } catch (e, st) {
      AppLogger.logError('FamilyServerSyncService.pushGrantsNow', e, st);
    }
  }

  /// Мапінг viewer personUuid → account_id береться напряму з [status]
  /// (кожен активний учасник сім'ї вже приходить туди безкоштовно) — не
  /// потребує жодного окремого локального кешу чи зміни схеми БД.
  Future<void> _syncGrants(String accountId, FamilyStatusResult status) async {
    try {
      final accountByPersonUuid = <String, String>{
        for (final m in status.families.expand((f) => f.members)) m.personUuid: m.accountId,
      };
      if (accountByPersonUuid.isEmpty) return;

      final mySubjects = await _db.select(_db.members).get();
      final grants = <Map<String, dynamic>>[];
      for (final subject in mySubjects) {
        final subjectUuid = subject.personUuid;
        if (subjectUuid == null) continue;
        for (final entry in accountByPersonUuid.entries) {
          final viewerPersonUuid = entry.key;
          if (viewerPersonUuid == subjectUuid) continue;
          final viewerAccountId = entry.value;
          for (final section in FamilySection.values) {
            final canView =
                await FamilyVisibilityService.isSectionAllowed(_db, subjectUuid, viewerPersonUuid, section, edit: false);
            final canEdit =
                await FamilyVisibilityService.isSectionAllowed(_db, subjectUuid, viewerPersonUuid, section, edit: true);
            final notify =
                await FamilyVisibilityService.isAllowed(_db, subjectUuid, viewerPersonUuid, FamilyPermission.notify);
            if (!canView && !canEdit && !notify) continue;
            grants.add({
              'subject_person_uuid': subjectUuid,
              'viewer_account_id': viewerAccountId,
              'section': section.name,
              'can_view': canView,
              'can_edit': canEdit,
              'notify': notify,
            });
          }
        }
      }
      if (grants.isEmpty) return;
      await _api.grantsPush(accountId: accountId, grants: grants);
    } catch (e, st) {
      AppLogger.logError('FamilyServerSyncService._syncGrants', e, st);
    }
  }

  // ── Членство: покидьки, чиї канали зникли з /family/status ─────────────

  static const _knownMembersKey = 'family_v2_known_active_accounts';

  /// Порівнює поточний [status] із попереднім знімком (SharedPreferences —
  /// той самий підхід, що вже давно виправдав себе для `_previouslyPushed`).
  /// Для кожного акаунта, що БУВ активним і зник (вийшов) чи змінив статус
  /// на 'kicked' — прибирає SharedEntities/SharedSubjects/FamilyGrants,
  /// той самий локальний purge, що й архівний `removePeer` (Крок 3.4),
  /// просто тригер тепер серверний статус, а не relay-сигнал.
  Future<void> _applyMembershipDiff(FamilyStatusResult status) async {
    final prefs = await SharedPreferences.getInstance();
    final previousRaw = prefs.getString(_knownMembersKey);
    final previous = previousRaw == null ? <String>{} : (jsonDecode(previousRaw) as List).cast<String>().toSet();

    final currentActive = <String>{};
    final currentKicked = <String>{};
    for (final family in status.families) {
      for (final m in family.members) {
        if (m.status == 'active') {
          currentActive.add(m.accountId);
        } else if (m.status == 'kicked') {
          currentKicked.add(m.accountId);
        }
      }
    }

    // Хтось, хто раніше був активний, тепер або зник (пішов) або kicked.
    final departed = previous.difference(currentActive)..addAll(currentKicked.intersection(previous));
    for (final accountId in departed) {
      await _purgeAccountData(accountId, status);
    }

    await prefs.setString(_knownMembersKey, jsonEncode(currentActive.toList()));
  }

  Future<void> _purgeAccountData(String departedAccountId, FamilyStatusResult status) async {
    // personUuid цієї людини можемо знати лише з КОЛИШНЬОГО status() —
    // якщо його вже зовсім не видно (сім'ю розпущено/сам я вийшов), шукаємо
    // серед SharedSubjects за каналом, збереженим у dataJson.
    final repo = FamilyPeersRepository(_db);
    final subjects = await _db.select(_db.sharedSubjects).get();
    // channel_id, з яким асоційований departedAccountId, нам відомий лише
    // якщо канал ще присутній у status(); якщо його вже нема — прибираємо
    // по всіх SharedSubjects, чий peerChannelId більше не входить у жоден
    // активний канал (найнадійніше — окрема звірка, не по accountId напряму).
    final activeChannelIds = status.families.expand((f) => f.channels).map((c) => c.channelId).toSet();
    final orphanedSubjects = subjects.where((s) => !activeChannelIds.contains(s.peerChannelId)).toList();
    if (orphanedSubjects.isEmpty) return;

    for (final subject in orphanedSubjects) {
      final entities =
          await (_db.select(_db.sharedEntities)..where((t) => t.subjectPersonUuid.equals(subject.personUuid))).get();
      for (final e in entities) {
        switch (e.entityType) {
          case 'intake':
            await NotificationService.cancelPeerIntakeCheck(e.uuid);
          case 'activity_log':
            await NotificationService.cancelPeerActivityCheck(e.uuid);
          case 'doctor_appointment':
            await NotificationService.cancelPeerAppointmentCheck(e.uuid);
        }
      }
      await NotificationService.cancelTodayPeerWellbeingChecks(subject.personUuid);
      await repo.deleteSharedEntitiesForSubjects([subject.personUuid]);
      await (_db.delete(_db.familyGrants)
            ..where((t) => t.viewerPersonUuid.equals(subject.personUuid) | t.subjectPersonUuid.equals(subject.personUuid)))
          .go();
    }
    await repo.deleteSharedSubjectsForChannel(orphanedSubjects.first.peerChannelId);
  }

  // ── Пропущені перевірки — портовано з архіву, driven по SharedSubjects
  // (не по FamilyPeer-рядку, якого тут більше немає) ──────────────────────

  Future<void> _scheduleMissedChecksAll(FamilyStatusResult status) async {
    final subjects = await _db.select(_db.sharedSubjects).get();
    for (final subject in subjects) {
      await _scheduleMissedChecksForSubject(subject);
    }
  }

  Future<void> _scheduleMissedChecksForSubject(SharedSubject subject) async {
    final entities =
        await (_db.select(_db.sharedEntities)..where((t) => t.subjectPersonUuid.equals(subject.personUuid))).get();
    if (entities.isEmpty) return;

    Map<String, dynamic>? decode(SharedEntity e) {
      try {
        return jsonDecode(e.dataJson) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }

    String? nameFor(String entityType, String? uuid) {
      if (uuid == null) return null;
      for (final e in entities) {
        if (e.entityType == entityType && e.uuid == uuid) return decode(e)?['name'] as String?;
      }
      return null;
    }

    var hasWellbeingLogToday = false;
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    for (final e in entities) {
      if (e.entityType == 'wellbeing_log') {
        final loggedAt = _parseDateAny(decode(e)?['loggedAt']);
        if (loggedAt != null && !loggedAt.isBefore(todayStart)) hasWellbeingLogToday = true;
      }
    }
    if (hasWellbeingLogToday) {
      await NotificationService.cancelTodayPeerWellbeingChecks(subject.personUuid);
    }

    for (final e in entities) {
      final json = decode(e);
      if (json == null) continue;
      switch (e.entityType) {
        case 'intake':
          final status = json['status'] as String?;
          if (status == null || status == 'pending') {
            final scheduledAt = _parseDateAny(json['scheduledAt']);
            if (scheduledAt == null) break;
            final medName = nameFor('medication', json['medicationSyncUuid'] as String?) ?? 'Ліки';
            final doseAmount = json['doseAmount'];
            final doseUnit = json['doseUnit'] as String? ?? '';
            await NotificationService.schedulePeerIntakeCheck(
              uuid: e.uuid,
              subjectName: subject.name,
              medName: medName,
              dose: doseAmount != null ? '$doseAmount $doseUnit' : '',
              scheduledAt: scheduledAt,
            );
          } else {
            await NotificationService.cancelPeerIntakeCheck(e.uuid);
          }
        case 'activity_log':
          final status = json['status'] as String?;
          if (status == null || status == 'pending') {
            final scheduledAt = _parseDateAny(json['scheduledAt']);
            if (scheduledAt == null) break;
            final activityName = nameFor('activity', json['activitySyncUuid'] as String?) ?? 'Активність';
            await NotificationService.schedulePeerActivityCheck(
              uuid: e.uuid,
              subjectName: subject.name,
              activityName: activityName,
              scheduledAt: scheduledAt,
            );
          } else {
            await NotificationService.cancelPeerActivityCheck(e.uuid);
          }
        case 'doctor_appointment':
          final status = json['status'] as String?;
          if (status == null || status == 'pending') {
            final scheduledAt = _parseDateAny(json['scheduledAt']);
            if (scheduledAt == null) break;
            final doctorType = json['doctorType'] as String? ?? 'Лікар';
            await NotificationService.schedulePeerAppointmentCheck(
              uuid: e.uuid,
              subjectName: subject.name,
              doctorType: doctorType,
              scheduledAt: scheduledAt,
            );
          } else {
            await NotificationService.cancelPeerAppointmentCheck(e.uuid);
          }
        case 'wellbeing_schedule':
          if (hasWellbeingLogToday) break;
          final now = DateTime.now();
          final day = DateTime(now.year, now.month, now.day);
          final cutoff = now.subtract(const Duration(hours: 1));
          List<String> times;
          try {
            times = List<String>.from(json['times'] as List);
          } catch (_) {
            break;
          }
          for (var i = 0; i < times.length; i++) {
            final parts = times[i].split(':');
            final scheduledAt = DateTime(day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1]));
            if (scheduledAt.isBefore(cutoff)) continue;
            await NotificationService.schedulePeerWellbeingCheck(
              subjectPersonUuid: subject.personUuid,
              subjectName: subject.name,
              slotIndex: i,
              scheduledAt: scheduledAt,
            );
          }
      }
    }
  }

  // ── "🔔 Нагадати" — портовано, мінус _ping (сервер сам відповідає за
  // "розбудити", коли B6/FCM-nudge буде повністю підключено) ─────────────

  Future<void> sendRemoteReminder({
    required String channelId,
    required String counterpartPublicKeyHex,
    required String title,
    required String body,
  }) async {
    final account = await ensureFamilyAccount();
    final key = await FamilyKeyService.sharedChannelKey(counterpartPublicKeyHex);
    final entity = {
      'type': 'remind_now',
      'uuid': _uuid.v4(),
      'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, {'title': title, 'body': body})),
    };
    await _api.push(accountId: account.accountId, channelId: channelId, entities: [entity]);
  }

  Future<void> _handleRemoteReminder(Map<String, dynamic> json, String updatedAtRaw) async {
    final updatedAt = DateTime.tryParse(updatedAtRaw);
    if (updatedAt == null || DateTime.now().difference(updatedAt) > const Duration(minutes: 5)) return;
    await NotificationService.showRemoteReminder(
      title: json['title'] as String? ?? '🔔 Вам нагадують',
      body: json['body'] as String? ?? '',
    );
  }

  // ── Edit: контрагент → subject, тільки поле нотаток, compare-and-swap ──
  // Портовано 1:1 з архіву — сама логіка транспорт-незалежна.

  Future<void> proposeEdit({
    required String channelId,
    required String counterpartPublicKeyHex,
    required String subjectPersonUuid,
    required String entityType,
    required String targetUuid,
    required String? value,
    required DateTime baseUpdatedAt,
  }) async {
    final account = await ensureFamilyAccount();
    final key = await FamilyKeyService.sharedChannelKey(counterpartPublicKeyHex);
    final json = {
      'subjectPersonUuid': subjectPersonUuid,
      'entityType': entityType,
      'uuid': targetUuid,
      'field': _notesFields[entityType] ?? 'notes',
      'value': value,
      'baseUpdatedAt': baseUpdatedAt.toIso8601String(),
    };
    final entity = {
      'type': 'edit_proposal',
      'uuid': _uuid.v4(),
      'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
    };
    await _api.push(accountId: account.accountId, channelId: channelId, entities: [entity]);
  }

  Future<void> _applyEditProposal(Map<String, dynamic> json, FamilyMemberEntry fromCounterpart) async {
    final subjectUuid = json['subjectPersonUuid'] as String?;
    final entityType = json['entityType'] as String?;
    final targetUuid = json['uuid'] as String?;
    final field = json['field'] as String?;
    final baseUpdatedAtRaw = json['baseUpdatedAt'] as String?;
    if (subjectUuid == null || entityType == null || targetUuid == null || field == null || baseUpdatedAtRaw == null) {
      return;
    }
    final baseUpdatedAt = DateTime.tryParse(baseUpdatedAtRaw);
    if (baseUpdatedAt == null) return;

    final subject = await (_db.select(_db.members)..where((t) => t.personUuid.equals(subjectUuid))).getSingleOrNull();
    if (subject == null) return;

    final section = _alwaysSyncedTypes.contains(entityType)
        ? FamilySection.schedule
        : (entityType == 'medcard_entry' || entityType == 'medcard_section')
            ? FamilySection.shelves
            : FamilySection.medcard;
    final sectionAllowed = await FamilyVisibilityService.isSectionAllowed(
      _db,
      subjectUuid,
      fromCounterpart.personUuid,
      section,
      edit: true,
    );
    if (!sectionAllowed) return;

    final value = json['value'] as String?;
    await _applyFieldIfUnchanged(entityType, targetUuid, subject.id, field, value, baseUpdatedAt);
  }

  bool _sameVersion(DateTime a, DateTime b) => a.millisecondsSinceEpoch ~/ 1000 == b.millisecondsSinceEpoch ~/ 1000;

  Future<void> _applyFieldIfUnchanged(
    String entityType,
    String targetUuid,
    int memberId,
    String field,
    String? value,
    DateTime baseUpdatedAt,
  ) async {
    final trimmed = value?.trim();
    final normalized = (trimmed == null || trimmed.isEmpty) ? null : trimmed;

    switch (entityType) {
      case 'medication':
        final row = await (_db.select(_db.medications)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return;
        await (_db.update(_db.medications)..where((t) => t.id.equals(row.id))).write(
            MedicationsCompanion(instructions: Value(normalized), updatedAt: Value(DateTime.now())));
      case 'doctor_appointment':
        final row = await (_db.select(_db.reminders)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return;
        await (_db.update(_db.reminders)..where((t) => t.id.equals(row.id)))
            .write(RemindersCompanion(notes: Value(normalized), updatedAt: Value(DateTime.now())));
    }
  }

  // ── Крок 4.4: справжнє створення/редагування "за іншого" ────────────────
  // Портовано 1:1 з архіву.

  Future<void> proposeRecord({
    required String channelId,
    required String counterpartPublicKeyHex,
    required String subjectPersonUuid,
    required String entityType,
    required String action,
    required String targetUuid,
    DateTime? baseUpdatedAt,
    String? sectionSyncUuid,
    required Map<String, dynamic> fields,
  }) async {
    assert(_recordProposalTypes.contains(entityType));
    assert(action == 'create' || action == 'edit');
    final account = await ensureFamilyAccount();
    final key = await FamilyKeyService.sharedChannelKey(counterpartPublicKeyHex);

    final json = <String, dynamic>{
      'subjectPersonUuid': subjectPersonUuid,
      'entityType': entityType,
      'action': action,
      'uuid': targetUuid,
      if (baseUpdatedAt != null) 'baseUpdatedAt': baseUpdatedAt.toIso8601String(),
      if (sectionSyncUuid != null) 'sectionSyncUuid': sectionSyncUuid,
      'fields': fields,
    };
    final entity = {
      'type': 'record_proposal',
      'uuid': _uuid.v4(),
      'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
    };
    await _api.push(accountId: account.accountId, channelId: channelId, entities: [entity]);
  }

  Future<void> _applyRecordProposal(Map<String, dynamic> json, FamilyMemberEntry fromCounterpart) async {
    final subjectUuid = json['subjectPersonUuid'] as String?;
    final entityType = json['entityType'] as String?;
    final action = json['action'] as String?;
    final targetUuid = json['uuid'] as String?;
    final fields = json['fields'] as Map<String, dynamic>?;
    if (subjectUuid == null ||
        entityType == null ||
        !_recordProposalTypes.contains(entityType) ||
        action == null ||
        targetUuid == null ||
        fields == null) {
      return;
    }

    final subject = await (_db.select(_db.members)..where((t) => t.personUuid.equals(subjectUuid))).getSingleOrNull();
    if (subject == null) return;

    final section = _alwaysSyncedTypes.contains(entityType)
        ? FamilySection.schedule
        : (entityType == 'medcard_entry' || entityType == 'medcard_section')
            ? FamilySection.shelves
            : FamilySection.medcard;
    // #323: 'create' тепер перевіряється окремим грантом (не 'edit') — той,
    // хто має лише право створювати (без перегляду/редагування ЧУЖИХ
    // існуючих записів), однобічно штовхає нові записи суб'єкту.
    final sectionAllowed = action == 'create'
        ? await FamilyVisibilityService.isCreateAllowed(_db, subjectUuid, fromCounterpart.personUuid, section)
        : await FamilyVisibilityService.isSectionAllowed(_db, subjectUuid, fromCounterpart.personUuid, section, edit: true);
    if (!sectionAllowed) return;

    final sectionSyncUuid = json['sectionSyncUuid'] as String?;
    final localSectionId = await _localSectionIdFor(sectionSyncUuid, subject.id);
    if (entityType == 'medcard_entry' && localSectionId == null) return;

    String? title;
    if (action == 'create') {
      if (await _recordExistsByUuid(entityType, targetUuid, subject.id)) return;
      title = await _insertRecord(entityType, subject.id, localSectionId, targetUuid, fields, fromCounterpart);
    } else if (action == 'edit') {
      final baseUpdatedAtRaw = json['baseUpdatedAt'] as String?;
      final baseUpdatedAt = baseUpdatedAtRaw != null ? DateTime.tryParse(baseUpdatedAtRaw) : null;
      if (baseUpdatedAt == null) return;
      title = await _updateRecordIfUnchanged(entityType, targetUuid, subject.id, localSectionId, fields, baseUpdatedAt);
    } else {
      return;
    }
    if (title == null) return;

    await NotificationService.showPeerRecordApplied(
      peerName: fromCounterpart.name,
      recordTitle: title,
      isNew: action == 'create',
    );
  }

  Future<int?> _localSectionIdFor(String? sectionSyncUuid, int memberId) async {
    if (sectionSyncUuid == null) return null;
    final row = await (_db.select(_db.medcardSections)
          ..where((t) => t.syncUuid.equals(sectionSyncUuid) & t.memberId.equals(memberId)))
        .getSingleOrNull();
    return row?.id;
  }

  Future<bool> _recordExistsByUuid(String entityType, String uuid, int memberId) async {
    switch (entityType) {
      case 'medication':
        return await (_db.select(_db.medications)
                  ..where((t) => t.syncUuid.equals(uuid) & t.memberId.equals(memberId)))
                .getSingleOrNull() !=
            null;
      case 'activity':
        return await (_db.select(_db.activities)
                  ..where((t) => t.syncUuid.equals(uuid) & t.memberId.equals(memberId)))
                .getSingleOrNull() !=
            null;
      case 'doctor_appointment':
        return await (_db.select(_db.reminders)
                  ..where((t) => t.syncUuid.equals(uuid) & t.memberId.equals(memberId)))
                .getSingleOrNull() !=
            null;
      case 'wellbeing_schedule':
        return await (_db.select(_db.wellbeingSchedules)
                  ..where((t) => t.syncUuid.equals(uuid) & t.memberId.equals(memberId)))
                .getSingleOrNull() !=
            null;
      case 'medcard_entry':
        return await (_db.select(_db.medcardEntries)
                  ..where((t) => t.syncUuid.equals(uuid) & t.memberId.equals(memberId)))
                .getSingleOrNull() !=
            null;
      case 'medcard_section':
        return await (_db.select(_db.medcardSections)
                  ..where((t) => t.syncUuid.equals(uuid) & t.memberId.equals(memberId)))
                .getSingleOrNull() !=
            null;
    }
    return false;
  }

  String? _fS(Map<String, dynamic> f, String k) => f[k] as String?;
  String _fSReq(Map<String, dynamic> f, String k, String fallback) => (f[k] as String?) ?? fallback;
  double _fD(Map<String, dynamic> f, String k, double fallback) => (f[k] as num?)?.toDouble() ?? fallback;
  int _fI(Map<String, dynamic> f, String k, int fallback) => (f[k] as num?)?.toInt() ?? fallback;
  bool _fB(Map<String, dynamic> f, String k, bool fallback) => (f[k] as bool?) ?? fallback;
  DateTime? _fDtN(Map<String, dynamic> f, String k) {
    final v = f[k] as String?;
    return v == null ? null : DateTime.tryParse(v);
  }

  DateTime _fDtReq(Map<String, dynamic> f, String k, DateTime fallback) => _fDtN(f, k) ?? fallback;

  Future<String?> _insertRecord(
    String entityType,
    int memberId,
    int? sectionId,
    String syncUuid,
    Map<String, dynamic> f,
    FamilyMemberEntry fromCounterpart,
  ) async {
    final now = DateTime.now();
    final creator = CreatorInfo(
      personUuid: fromCounterpart.personUuid,
      name: fromCounterpart.name,
      avatarIndex: fromCounterpart.avatarIndex,
    );
    switch (entityType) {
      case 'medication':
        final name = _fSReq(f, 'name', '');
        if (name.isEmpty) return null;
        final medId = await _db.into(_db.medications).insert(MedicationsCompanion.insert(
              memberId: memberId,
              sectionId: Value(sectionId),
              name: name,
              form: Value(_fSReq(f, 'form', '')),
              doseAmount: _fD(f, 'doseAmount', 1),
              doseUnit: Value(_fSReq(f, 'doseUnit', 'мг')),
              repeatType: Value(_fSReq(f, 'repeatType', 'daily')),
              repeatConfig: Value(_fSReq(f, 'repeatConfig', '{}')),
              startDate: _fDtReq(f, 'startDate', now),
              endDate: Value(_fDtN(f, 'endDate')),
              totalCount: Value(_fI(f, 'totalCount', 0)),
              remainingCount: Value(_fI(f, 'remainingCount', 0)),
              photoPaths: Value(_fSReq(f, 'photoPaths', '[]')),
              instructions: Value(_fS(f, 'instructions')),
              phases: Value(_fS(f, 'phases')),
              trackStock: Value(_fB(f, 'trackStock', false)),
              stockUnit: Value(_fS(f, 'stockUnit')),
              iconKey: Value(_fS(f, 'iconKey')),
              color: Value(_fS(f, 'color')),
              sideEffects: Value(_fS(f, 'sideEffects')),
              updatedAt: Value(now),
              syncUuid: Value(syncUuid),
            ));
        await recordCreator(_db, 'medication', medId, creator);
        await _scheduleAfterInsert(() => _intakeGenerator!.generateForDay(now));
        return name;
      case 'activity':
        final name = _fSReq(f, 'name', '');
        if (name.isEmpty) return null;
        final activityId = await _db.into(_db.activities).insert(ActivitiesCompanion.insert(
              memberId: memberId,
              sectionId: Value(sectionId),
              name: name,
              type: const Value('routine'),
              durationMin: Value(_fI(f, 'durationMin', 30)),
              repeatDays: Value(_fSReq(f, 'repeatDays', '[1,2,3,4,5]')),
              reminderBeforeMin: Value(_fI(f, 'reminderBeforeMin', 10)),
              color: Value(_fS(f, 'color')),
              repeatType: Value(_fSReq(f, 'repeatType', 'weekly')),
              repeatDayOfMonth: Value(f['repeatDayOfMonth'] as int?),
              repeatIntervalDays: Value(f['repeatIntervalDays'] as int?),
              weeklyGoalCount: Value(f['weeklyGoalCount'] as int?),
              rotationAnchorDate: Value(now),
              rotationMode: const Value('fixed'),
              stepsJson: Value(_fS(f, 'stepsJson')),
              tags: Value(_fSReq(f, 'tags', '[]')),
              documentPaths: Value(_fSReq(f, 'documentPaths', '[]')),
              location: Value(_fS(f, 'location')),
              iconKey: Value(_fSReq(f, 'iconKey', 'task_routine')),
              updatedAt: Value(now),
              syncUuid: Value(syncUuid),
            ));
        await recordCreator(_db, 'activity', activityId, creator);
        await _scheduleAfterInsert(() => _activityLogGenerator!.generateForDay(now));
        return name;
      case 'doctor_appointment':
        final title = _fSReq(f, 'doctorType', '');
        if (title.isEmpty) return null;
        final reminderId = await _db.into(_db.reminders).insert(RemindersCompanion.insert(
              memberId: memberId,
              sectionId: Value(sectionId),
              doctorType: title,
              tags: Value(_fSReq(f, 'tags', '[]')),
              location: Value(_fS(f, 'location')),
              scheduledAt: _fDtReq(f, 'scheduledAt', now),
              remindBeforeMin: Value(_fI(f, 'remindBeforeMin', 60)),
              notes: Value(_fS(f, 'notes')),
              documentPaths: Value(_fSReq(f, 'documentPaths', '[]')),
              color: Value(_fS(f, 'color')),
              iconKey: Value(_fSReq(f, 'iconKey', 'calendar')),
              repeatType: Value(_fSReq(f, 'repeatType', 'none')),
              repeatConfig: Value(_fSReq(f, 'repeatConfig', '{}')),
              updatedAt: Value(now),
              syncUuid: Value(syncUuid),
            ));
        await recordCreator(_db, 'doctor_appointment', reminderId, creator);
        await _replaceReminderSlots(reminderId, f);
        await _scheduleAfterInsert(() async {
          final row = await (_db.select(_db.reminders)..where((t) => t.id.equals(reminderId))).getSingle();
          final rawSlots = f['slotTimes'] as String?;
          final slotTimes = rawSlots == null
              ? const <String>[]
              : List<String>.from(jsonDecode(rawSlots) as List);
          await _remindersRepository!.scheduleNotificationsForReminder(row, slotTimes: slotTimes);
        });
        return title;
      case 'wellbeing_schedule':
        await _db.into(_db.wellbeingSchedules).insert(WellbeingSchedulesCompanion.insert(
              memberId: memberId,
              sectionId: Value(sectionId),
              timesPerDay: Value(_fI(f, 'timesPerDay', 2)),
              times: Value(_fSReq(f, 'times', '["08:00","20:00"]')),
              isActive: Value(_fB(f, 'isActive', true)),
              color: Value(_fS(f, 'color')),
              updatedAt: Value(now),
              syncUuid: Value(syncUuid),
            ));
        return null;
      case 'medcard_entry':
        if (sectionId == null) return null;
        final title = _fSReq(f, 'title', '');
        if (title.isEmpty) return null;
        final entryId = await _db.into(_db.medcardEntries).insert(MedcardEntriesCompanion.insert(
              sectionId: sectionId,
              memberId: memberId,
              title: title,
              recordDate: _fDtReq(f, 'recordDate', now),
              notes: Value(_fS(f, 'notes')),
              tags: Value(_fSReq(f, 'tags', '[]')),
              location: Value(_fS(f, 'location')),
              documentPaths: Value(_fSReq(f, 'documentPaths', '[]')),
              updatedAt: Value(now),
              syncUuid: Value(syncUuid),
            ));
        await recordCreator(_db, 'medcard_entry', entryId, creator);
        return title;
      case 'medcard_section':
        final name = _fSReq(f, 'name', '');
        if (name.isEmpty) return null;
        await _db.into(_db.medcardSections).insert(MedcardSectionsCompanion.insert(
              memberId: memberId,
              name: name,
              iconKey: Value(_fSReq(f, 'iconKey', 'folder')),
              color: Value(_fSReq(f, 'color', '#F5A65C')),
              comment: Value(_fS(f, 'comment')),
              updatedAt: Value(now),
              syncUuid: Value(syncUuid),
            ));
        return name;
    }
    return null;
  }

  // #320: відповідний Riverpod-сервіс відсутній у частини викликів (див.
  // коментар при конструкторі) — тоді `!` кине null-check exception, який
  // тут же й гаситься (мовчки пропускаємо миттєве планування; ліки/рутини
  // все одно підхоплюються лінивими генераторами при наступному відкритті
  // Сьогодні/Розкладу, нагадування — ні, але це не гірше за поведінку до
  // цього фіксу). Так само гаситься й будь-яка інша невдала спроба
  // планування (напр. брак дозволу на точні будильники) — не повинна
  // ламати сам факт застосування record_proposal, запис уже вставлено.
  Future<void> _scheduleAfterInsert(Future<void> Function() schedule) async {
    try {
      await schedule();
    } catch (e, st) {
      AppLogger.logError('FamilyServerSyncService._scheduleAfterInsert', e, st);
    }
  }

  Future<String?> _updateRecordIfUnchanged(
    String entityType,
    String targetUuid,
    int memberId,
    int? sectionId,
    Map<String, dynamic> f,
    DateTime baseUpdatedAt,
  ) async {
    final now = DateTime.now();
    switch (entityType) {
      case 'medication':
        final row = await (_db.select(_db.medications)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return null;
        final name = _fSReq(f, 'name', row.name);
        await (_db.update(_db.medications)..where((t) => t.id.equals(row.id))).write(MedicationsCompanion(
          sectionId: Value(sectionId),
          name: Value(name),
          form: Value(_fSReq(f, 'form', row.form)),
          doseAmount: Value(_fD(f, 'doseAmount', row.doseAmount)),
          doseUnit: Value(_fSReq(f, 'doseUnit', row.doseUnit)),
          repeatType: Value(_fSReq(f, 'repeatType', row.repeatType)),
          repeatConfig: Value(_fSReq(f, 'repeatConfig', row.repeatConfig)),
          startDate: Value(_fDtReq(f, 'startDate', row.startDate)),
          endDate: Value(_fDtN(f, 'endDate')),
          totalCount: Value(_fI(f, 'totalCount', row.totalCount)),
          remainingCount: Value(_fI(f, 'remainingCount', row.remainingCount)),
          photoPaths: Value(_fSReq(f, 'photoPaths', row.photoPaths)),
          instructions: Value(_fS(f, 'instructions') ?? row.instructions),
          phases: Value(_fS(f, 'phases') ?? row.phases),
          trackStock: Value(_fB(f, 'trackStock', row.trackStock)),
          stockUnit: Value(_fS(f, 'stockUnit') ?? row.stockUnit),
          iconKey: Value(_fS(f, 'iconKey') ?? row.iconKey),
          color: Value(_fS(f, 'color') ?? row.color),
          sideEffects: Value(_fS(f, 'sideEffects') ?? row.sideEffects),
          updatedAt: Value(now),
        ));
        return name;
      case 'activity':
        final row = await (_db.select(_db.activities)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return null;
        final name = _fSReq(f, 'name', row.name);
        await (_db.update(_db.activities)..where((t) => t.id.equals(row.id))).write(ActivitiesCompanion(
          sectionId: Value(sectionId),
          name: Value(name),
          durationMin: Value(_fI(f, 'durationMin', row.durationMin)),
          repeatDays: Value(_fSReq(f, 'repeatDays', row.repeatDays)),
          reminderBeforeMin: Value(_fI(f, 'reminderBeforeMin', row.reminderBeforeMin)),
          color: Value(_fS(f, 'color') ?? row.color),
          repeatType: Value(_fSReq(f, 'repeatType', row.repeatType)),
          repeatDayOfMonth: Value(f['repeatDayOfMonth'] as int? ?? row.repeatDayOfMonth),
          repeatIntervalDays: Value(f['repeatIntervalDays'] as int? ?? row.repeatIntervalDays),
          weeklyGoalCount: Value(f['weeklyGoalCount'] as int? ?? row.weeklyGoalCount),
          stepsJson: Value(_fS(f, 'stepsJson') ?? row.stepsJson),
          tags: Value(_fSReq(f, 'tags', row.tags)),
          documentPaths: Value(_fSReq(f, 'documentPaths', row.documentPaths)),
          location: Value(_fS(f, 'location') ?? row.location),
          iconKey: Value(_fSReq(f, 'iconKey', row.iconKey)),
          updatedAt: Value(now),
        ));
        return name;
      case 'doctor_appointment':
        final row = await (_db.select(_db.reminders)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return null;
        final title = _fSReq(f, 'doctorType', row.doctorType);
        await (_db.update(_db.reminders)..where((t) => t.id.equals(row.id))).write(RemindersCompanion(
          sectionId: Value(sectionId),
          doctorType: Value(title),
          tags: Value(_fSReq(f, 'tags', row.tags)),
          location: Value(_fS(f, 'location') ?? row.location),
          scheduledAt: Value(_fDtReq(f, 'scheduledAt', row.scheduledAt)),
          remindBeforeMin: Value(_fI(f, 'remindBeforeMin', row.remindBeforeMin)),
          notes: Value(_fS(f, 'notes') ?? row.notes),
          documentPaths: Value(_fSReq(f, 'documentPaths', row.documentPaths)),
          color: Value(_fS(f, 'color') ?? row.color),
          iconKey: Value(_fSReq(f, 'iconKey', row.iconKey)),
          repeatType: Value(_fSReq(f, 'repeatType', row.repeatType)),
          repeatConfig: Value(_fSReq(f, 'repeatConfig', row.repeatConfig)),
          updatedAt: Value(now),
        ));
        if (f.containsKey('slotTimes')) await _replaceReminderSlots(row.id, f);
        return title;
      case 'wellbeing_schedule':
        final row = await (_db.select(_db.wellbeingSchedules)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return null;
        await (_db.update(_db.wellbeingSchedules)..where((t) => t.id.equals(row.id))).write(
            WellbeingSchedulesCompanion(
          sectionId: Value(sectionId),
          timesPerDay: Value(_fI(f, 'timesPerDay', row.timesPerDay)),
          times: Value(_fSReq(f, 'times', row.times)),
          isActive: Value(_fB(f, 'isActive', row.isActive)),
          color: Value(_fS(f, 'color') ?? row.color),
          updatedAt: Value(now),
        ));
        return null;
      case 'medcard_entry':
        final row = await (_db.select(_db.medcardEntries)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return null;
        final title = _fSReq(f, 'title', row.title);
        await (_db.update(_db.medcardEntries)..where((t) => t.id.equals(row.id))).write(MedcardEntriesCompanion(
          sectionId: Value(sectionId ?? row.sectionId),
          title: Value(title),
          recordDate: Value(_fDtReq(f, 'recordDate', row.recordDate)),
          notes: Value(_fS(f, 'notes') ?? row.notes),
          tags: Value(_fSReq(f, 'tags', row.tags)),
          location: Value(_fS(f, 'location') ?? row.location),
          documentPaths: Value(_fSReq(f, 'documentPaths', row.documentPaths)),
          updatedAt: Value(now),
        ));
        return title;
      case 'medcard_section':
        final row = await (_db.select(_db.medcardSections)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return null;
        final name = _fSReq(f, 'name', row.name);
        await (_db.update(_db.medcardSections)..where((t) => t.id.equals(row.id))).write(
            MedcardSectionsCompanion(
          name: Value(name),
          iconKey: Value(_fSReq(f, 'iconKey', row.iconKey)),
          color: Value(_fSReq(f, 'color', row.color)),
          comment: Value(_fS(f, 'comment') ?? row.comment),
          updatedAt: Value(now),
        ));
        return name;
      case 'activity_log':
        final row = await (_db.select(_db.activityLogs)..where((t) => t.syncUuid.equals(targetUuid))).getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return null;
        final act = await (_db.select(_db.activities)
              ..where((t) => t.id.equals(row.activityId) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (act == null) return null;
        final identity = _fS(f, 'assigneeIdentity');
        if (identity == null) return null;
        final newAssigneeId = await _resolveAssigneeIdentity(identity);
        if (newAssigneeId == null) return null;
        await (_db.update(_db.activityLogs)..where((t) => t.id.equals(row.id)))
            .write(ActivityLogsCompanion(memberId: Value(newAssigneeId), updatedAt: Value(now)));
        return act.name;
    }
    return null;
  }

  Future<int?> _resolveAssigneeIdentity(String identity) async {
    if (identity.startsWith('m')) {
      final id = int.tryParse(identity.substring(1));
      if (id != null) return id;
    }
    final row = await (_db.select(_db.members)..where((t) => t.linkedPeerPersonUuid.equals(identity))).getSingleOrNull();
    return row?.id;
  }

  Future<void> _replaceReminderSlots(int reminderId, Map<String, dynamic> f) async {
    final raw = f['slotTimes'] as String?;
    if (raw == null) return;
    List<String> times;
    try {
      times = List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return;
    }
    await (_db.delete(_db.reminderSlots)..where((t) => t.reminderId.equals(reminderId))).go();
    for (var i = 0; i < times.length; i++) {
      await _db.into(_db.reminderSlots).insert(ReminderSlotsCompanion.insert(
            reminderId: reminderId,
            timeOfDay: times[i],
            sortOrder: Value(i),
            syncUuid: Value(_uuid.v4()),
          ));
    }
  }
}
