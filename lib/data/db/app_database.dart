import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart' as sqlite3_open;
import 'package:uuid/uuid.dart';

import '../../core/services/app_logger.dart';
import '../../core/services/db_encryption_service.dart';
import '../../core/services/symptom_library_service.dart';
import 'tables/members_table.dart';
import 'tables/medications_table.dart';
import 'tables/schedules_table.dart';
import 'tables/intakes_table.dart';
import 'tables/symptoms_table.dart';
import 'tables/wellbeing_logs_table.dart';
import 'tables/wellbeing_schedules_table.dart';
import 'tables/activities_table.dart';
import 'tables/doctor_appointments_table.dart';
import 'tables/reminders_table.dart';
import 'tables/lab_results_table.dart';
import 'tables/allergies_table.dart';
import 'tables/chronic_conditions_table.dart';
import 'tables/vaccinations_table.dart';
import 'tables/surgeries_table.dart';
import 'tables/shared_channels_table.dart';
import 'tables/family_peers_table.dart';
import 'tables/family_grants_table.dart';
import 'tables/ai_usage_table.dart';
import 'tables/medcard_sections_table.dart';
import 'tables/medcard_entries_table.dart';

part 'app_database.g.dart';

// LabResults/Allergies/ChronicConditions/Vaccinations/Surgeries: сутності
// видалені з продукту (замінені довільними розділами архіву —
// MedcardSections/MedcardEntries, міграція 29) і фізично дропаються для
// всіх у міграції 30 нижче (та одразу після createAll на новому
// пристрої). Класи лишаються в схемі й у списку тут ЛИШЕ тому, що
// історичні кроки onUpgrade (from < 10..14) звертаються до їхніх
// згенерованих гетерів (createTable(labResults) тощо) — прибрати їх
// звідси означало б неможливість скомпілювати ці старі кроки, а вони
// потрібні для будь-кого, хто оновлюється зі старої версії застосунку.
//
// DoctorAppointments/Reminders: те саме, але перейменування, не видалення —
// клас "DoctorAppointments" лишається в схемі й у списку лише тому, що
// історичні кроки onUpgrade (from < 9, 12, 13, 20, 27) звертаються до його
// гетера; фізична таблиця перейменовується на "reminders" для всіх у
// міграції 31 (m.renameTable), новий код усюди використовує лише [Reminders].
@DriftDatabase(tables: [
  Members,
  Medications,
  Schedules,
  Intakes,
  Symptoms,
  WellbeingLogs,
  WellbeingSchedules,
  Activities,
  ActivitySlots,
  ActivityLogs,
  ActivityAssignees,
  DoctorAppointments,
  Reminders,
  ReminderSlots,
  ReminderLogs,
  SharedChannels,
  LabResults,
  Allergies,
  ChronicConditions,
  Vaccinations,
  Surgeries,
  FamilyPeers,
  PendingGroupInvites,
  FamilyGrants,
  SharedSubjects,
  SharedEntities,
  KnownFamilyMembers,
  AiUsage,
  MedcardSections,
  MedcardEntries,
])
// Реальний баг у продакшені (04.08): попри те, що v48/v50 (onUpgrade)
// мали б виправити старі NULL/зіпсовані updated_at в цих таблицях, у
// логах користувача той самий крах лишався і після onUpgrade-оновлення
// "на місці", і після повного видалення застосунку + відновлення з
// хмарного бекапу. Справжня причина виявилась глибшою — лог з build 67
// (з активним beforeOpen, коли помилки вже НЕ ковтались мовчки) показав
// пряме `SqliteException: no such column: updated_at` на reminder_slots:
// колонка на цьому пристрої фізично відсутня, попри те, що user_version
// вже давно перейшов позначку 45 (де мав відпрацювати
// `m.addColumn(reminderSlots, reminderSlots.updatedAt)`). Той addColumn
// сам колись мовчки впав (той самий `catch (_) {}` — ADD COLUMN з
// виразом-DEFAULT (`currentDateAndTime`) підтримується не на кожній
// платформі/версії sqlite3) — тож саму UPDATE-репарацію запускати
// нема на чому. `doctor_appointments` прибрано зі списку зовсім: ця
// таблиця перейменована на "reminders" для всіх у міграції 31, на
// жодному сучасному пристрої її фізично більше не існує.
const _kUpdatedAtRepairTables = [
  'reminder_slots',
  'members',
  'medications',
  'schedules',
  'intakes',
  'symptoms',
  'wellbeing_logs',
  'wellbeing_schedules',
  'activities',
  'activity_slots',
  'activity_logs',
];

class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 51;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Свіжий пристрій одразу отримує схему без застарілих таблиць
          // медкартки — createAll створює все з tables: вище (включно з
          // LabResults/Allergies/...), тож прибираємо їх тут же.
          await m.deleteTable('lab_results');
          await m.deleteTable('allergies');
          await m.deleteTable('chronic_conditions');
          await m.deleteTable('vaccinations');
          await m.deleteTable('surgeries');
          // Те саме для legacy-класу DoctorAppointments — createAll створює
          // й порожню "doctor_appointments" (вона теж у tables: вище), а
          // новий код скрізь працює лише з "reminders".
          await m.deleteTable('doctor_appointments');
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Guard against tables already containing this column
            // (can happen if DB was created with createAll at schema 1)
            try {
              await m.addColumn(medications, medications.phases);
            } catch (_) {}
          }
          if (from < 3) {
            // stockPercent/openedAt більше не поля таблиці (видалені в v41,
            // див. нижче) — колонки вже не мають Dart-геттера, тож для цього
            // історичного кроку лишається лише сирий SQL.
            try {
              await customStatement(
                  'ALTER TABLE medications ADD COLUMN stock_percent INTEGER');
            } catch (_) {}
            try {
              await customStatement(
                  'ALTER TABLE medications ADD COLUMN opened_at DATETIME');
            } catch (_) {}
          }
          if (from < 4) {
            try {
              await m.addColumn(members, members.contact);
            } catch (_) {}
          }
          if (from < 5) {
            // updatedAt для майбутньої синхронізації — колонка з DEFAULT
            // currentDateAndTime сама підставить значення для вже наявних рядків.
            try {
              await m.addColumn(members, members.updatedAt);
            } catch (_) {}
            try {
              await m.addColumn(medications, medications.updatedAt);
            } catch (_) {}
            try {
              await m.addColumn(schedules, schedules.updatedAt);
            } catch (_) {}
            try {
              await m.addColumn(intakes, intakes.updatedAt);
            } catch (_) {}
            try {
              await m.addColumn(symptoms, symptoms.updatedAt);
            } catch (_) {}
            try {
              await m.addColumn(wellbeingLogs, wellbeingLogs.updatedAt);
            } catch (_) {}
            try {
              await m.addColumn(wellbeingSchedules, wellbeingSchedules.updatedAt);
            } catch (_) {}
            try {
              await m.addColumn(activities, activities.updatedAt);
            } catch (_) {}
            try {
              await m.addColumn(activitySlots, activitySlots.updatedAt);
            } catch (_) {}
            try {
              await m.addColumn(activityLogs, activityLogs.updatedAt);
            } catch (_) {}
            try {
              await m.addColumn(doctorAppointments, doctorAppointments.updatedAt);
            } catch (_) {}
          }
          if (from < 6) {
            // syncUuid — глобально унікальний ідентифікатор для family_sync
            // (бідирекційна синхронізація одного члена сім'ї між двома
            // пристроями); null, поки рядок ще не синхронізований жодного разу.
            try {
              await m.addColumn(medications, medications.syncUuid);
            } catch (_) {}
            try {
              await m.addColumn(schedules, schedules.syncUuid);
            } catch (_) {}
            try {
              await m.addColumn(intakes, intakes.syncUuid);
            } catch (_) {}
            try {
              await m.addColumn(symptoms, symptoms.syncUuid);
            } catch (_) {}
            try {
              await m.createTable(sharedChannels);
            } catch (_) {}
          }
          if (from < 7) {
            try {
              await m.addColumn(activities, activities.youtubeUrl);
            } catch (_) {}
          }
          if (from < 8) {
            // Кастомний колір картки — окремо для кожного типу завдання.
            try {
              await m.addColumn(medications, medications.color);
            } catch (_) {}
            try {
              await m.addColumn(activities, activities.color);
            } catch (_) {}
            try {
              await m.addColumn(doctorAppointments, doctorAppointments.color);
            } catch (_) {}
            try {
              await m.addColumn(wellbeingSchedules, wellbeingSchedules.color);
            } catch (_) {}
          }
          if (from < 9) {
            // Статус запису до лікаря (Зараз/Пропущено на головному екрані) і
            // позначка "пропущено" для зрізу самопочуття.
            try {
              await m.addColumn(doctorAppointments, doctorAppointments.status);
            } catch (_) {}
            try {
              await m.addColumn(wellbeingLogs, wellbeingLogs.skipped);
            } catch (_) {}
          }
          if (from < 10) {
            // Аналізи, прив'язані до напрямку лікаря — окрема сутність
            // медкартки, не заміна DoctorAppointments.
            try {
              await m.createTable(labResults);
            } catch (_) {}
          }
          if (from < 11) {
            // Решта категорій медкартки: алергії, хронічні захворювання,
            // щеплення, операції/госпіталізації.
            try {
              await m.createTable(allergies);
            } catch (_) {}
            try {
              await m.createTable(chronicConditions);
            } catch (_) {}
            try {
              await m.createTable(vaccinations);
            } catch (_) {}
            try {
              await m.createTable(surgeries);
            } catch (_) {}
          }
          if (from < 12) {
            // syncUuid для family_sync — решта медкартки (окрім Medications/
            // Schedules/Intakes/Symptoms, які отримали його в 6) наздоганяє.
            try {
              await m.addColumn(doctorAppointments, doctorAppointments.syncUuid);
            } catch (_) {}
            try {
              await m.addColumn(labResults, labResults.syncUuid);
            } catch (_) {}
            try {
              await m.addColumn(allergies, allergies.syncUuid);
            } catch (_) {}
            try {
              await m.addColumn(chronicConditions, chronicConditions.syncUuid);
            } catch (_) {}
            try {
              await m.addColumn(vaccinations, vaccinations.syncUuid);
            } catch (_) {}
            try {
              await m.addColumn(surgeries, surgeries.syncUuid);
            } catch (_) {}
          }
          if (from < 13) {
            // Кілька документів (фото + PDF) на запис замість одиночного
            // вкладення — documentPaths (json-список), той самий підхід, що
            // й Medications.photoPaths. Старі одиночні значення переносимо
            // в новий список, щоб не загубити вже прикріплені файли.
            try {
              await m.addColumn(labResults, labResults.documentPaths);
            } catch (_) {}
            try {
              await m.addColumn(doctorAppointments, doctorAppointments.documentPaths);
            } catch (_) {}
            try {
              await m.addColumn(surgeries, surgeries.documentPaths);
            } catch (_) {}
            try {
              final rows = await (select(labResults)..where((t) => t.attachmentPath.isNotNull())).get();
              for (final r in rows) {
                await (update(labResults)..where((t) => t.id.equals(r.id)))
                    .write(LabResultsCompanion(documentPaths: Value(jsonEncode([r.attachmentPath]))));
              }
            } catch (_) {}
            try {
              final rows =
                  await (select(doctorAppointments)..where((t) => t.pdfPath.isNotNull())).get();
              for (final r in rows) {
                await (update(doctorAppointments)..where((t) => t.id.equals(r.id))).write(
                    DoctorAppointmentsCompanion(documentPaths: Value(jsonEncode([r.pdfPath]))));
              }
            } catch (_) {}
            try {
              final rows = await (select(surgeries)..where((t) => t.attachmentPath.isNotNull())).get();
              for (final r in rows) {
                await (update(surgeries)..where((t) => t.id.equals(r.id)))
                    .write(SurgeriesCompanion(documentPaths: Value(jsonEncode([r.attachmentPath]))));
              }
            } catch (_) {}
          }
          if (from < 14) {
            // documentPaths для решти медкартки — алергії (напр. висновок
            // алерголога), хронічні захворювання (підтвердження діагнозу),
            // щеплення (сертифікати).
            try {
              await m.addColumn(allergies, allergies.documentPaths);
            } catch (_) {}
            try {
              await m.addColumn(chronicConditions, chronicConditions.documentPaths);
            } catch (_) {}
            try {
              await m.addColumn(vaccinations, vaccinations.documentPaths);
            } catch (_) {}
          }
          if (from < 15) {
            // Фундамент для повноцінної сімейної групи (кілька незалежних
            // акаунтів замість одиночного пейрингу 1:1): стабільний
            // крос-пристроєвий ідентифікатор людини замість локального id.
            try {
              await m.addColumn(members, members.personUuid);
            } catch (_) {}
            try {
              await m.addColumn(members, members.familyId);
            } catch (_) {}
            // Заднім числом видаємо personUuid усім рядкам, які існували
            // до цієї міграції — інакше вони лишаться без ідентичності.
            try {
              final rows = await (select(members)..where((t) => t.personUuid.isNull())).get();
              for (final r in rows) {
                await (update(members)..where((t) => t.id.equals(r.id)))
                    .write(MembersCompanion(personUuid: Value(const Uuid().v4())));
              }
            } catch (_) {}
          }
          if (from < 16) {
            // Сімейна група: локальний кеш "хто ще в групі" (FamilyPeers) і
            // черга власних запрошень, що очікують відповіді
            // (PendingGroupInvites) — нові таблиці, createAll їх не
            // створить на апгрейді, тому явно.
            try {
              await m.createTable(familyPeers);
            } catch (_) {}
            try {
              await m.createTable(pendingGroupInvites);
            } catch (_) {}
          }
          if (from < 17) {
            // Явні дозволи видимості за personUuid — заміна старого
            // локального SharedPreferences-механізму (family_vis_*), який
            // працював лише в межах одного пристрою й не давав жодного
            // реального бар'єру між пристроями сім'ї.
            try {
              await m.createTable(familyGrants);
            } catch (_) {}
          }
          if (from < 18) {
            // Реальний N-way обмін даними між учасниками сімейної групи
            // (Фаза 4): курсор синку на FamilyPeers + окремі таблиці для
            // отриманих "чужих" даних (свідомо не Members/Medications/etc,
            // щоб не змішувати з профілями, якими керує цей пристрій).
            try {
              await m.addColumn(familyPeers, familyPeers.lastSyncedAt);
            } catch (_) {}
            try {
              await m.createTable(sharedSubjects);
            } catch (_) {}
            try {
              await m.createTable(sharedEntities);
            } catch (_) {}
          }
          if (from < 19) {
            // Пір повинен дізнатись, що йому дозволено (FamilyGrants живе
            // лише на пристрої субʼєкта) — інакше "Сповіщення" не може
            // показати, хто з автономних учасників реально дозволив собі
            // слати сповіщення.
            try {
              await m.addColumn(familyPeers, familyPeers.notifyGranted);
            } catch (_) {}
            try {
              await m.addColumn(familyPeers, familyPeers.viewGranted);
            } catch (_) {}
            try {
              await m.addColumn(familyPeers, familyPeers.editGranted);
            } catch (_) {}
          }
          if (from < 20) {
            // Активності й самопочуття тепер теж дзеркалюються на пейрингу
            // автономного профілю (family_sync) — раніше синхронізувались
            // лише ліки й медкартка, тож пропущену активність чи відсутній
            // зріз самопочуття інший пристрій просто не міг побачити.
            try {
              await m.addColumn(activities, activities.syncUuid);
            } catch (_) {}
            try {
              await m.addColumn(activitySlots, activitySlots.syncUuid);
            } catch (_) {}
            try {
              await m.addColumn(activityLogs, activityLogs.syncUuid);
            } catch (_) {}
            try {
              await m.addColumn(wellbeingLogs, wellbeingLogs.syncUuid);
            } catch (_) {}
            try {
              await m.addColumn(wellbeingSchedules, wellbeingSchedules.syncUuid);
            } catch (_) {}
          }
          if (from < 21) {
            // "Локальний → Автономний": запрошення тепер може нести не лише
            // звичайне членство в групі, а й перетворення існуючого
            // локального профілю — convertingMemberId позначає, який саме.
            try {
              await m.addColumn(pendingGroupInvites, pendingGroupInvites.convertingMemberId);
            } catch (_) {}
          }
          if (from < 22) {
            // Напрямок звʼязку: хто кого запросив. Потрібно для коректного
            // підрахунку слотів (вхідні запрошення не мають витрачати МІЙ
            // ліміт) і щоб знати, хто може дарувати Family-плюшки. Існуючі
            // (вже засинкані) рядки — напрямок невідомий, false за
            // замовчуванням: безпечний варіант, просто не порахує чужий слот
            // як свій, поки звʼязок не пересоздасться.
            try {
              await m.addColumn(familyPeers, familyPeers.invitedMe);
            } catch (_) {}
          }
          if (from < 23) {
            // Автопредставлення: "візитівки" людей, яких я знаю через сім'ю,
            // але з якими ще нема справжнього зашифрованого каналу.
            try {
              await m.createTable(knownFamilyMembers);
            } catch (_) {}
          }
          if (from < 24) {
            // Реальний білінг: чи активна Family-підписка піра, який мене
            // запросив — прилітає через grants_summary, той самий канал, що
            // й notify/view/editGranted.
            try {
              await m.addColumn(familyPeers, familyPeers.payerPlanActive);
            } catch (_) {}
          }
          if (from < 25) {
            // Побічні ефекти, знайдені ІІ під час сканування рецепта —
            // раніше показувались лише на екрані перегляду сканування й
            // губились одразу після збереження ліків.
            try {
              await m.addColumn(medications, medications.sideEffects);
            } catch (_) {}
          }
          if (from < 26) {
            // Лічильники безкоштовних AI-викликів переїхали з SharedPreferences
            // (не потрапляє в резервну копію — див. ai_usage_table.dart) сюди.
            try {
              await m.createTable(aiUsage);
            } catch (_) {}
          }
          if (from < 27) {
            // Теги для нагадувань (колишні "Візити до лікарів", тепер
            // довільні нагадування) — вільні мітки замість контрольованого
            // словника напрямків лікаря.
            try {
              await m.addColumn(doctorAppointments, doctorAppointments.tags);
            } catch (_) {}
          }
          if (from < 28) {
            // Теги самопочуття — вільні мітки замість контрольованого
            // словника симптомів. Старі записи переносимо: ключі симптомів
            // (напр. "headache") перекладаємо в людяні назви одноразово,
            // щоб історія лишилась читабельною, далі новий код пише лише в
            // tagsJson.
            try {
              await m.addColumn(wellbeingLogs, wellbeingLogs.tagsJson);
            } catch (_) {}
            try {
              final rows = await (select(wellbeingLogs)
                    ..where((t) => t.symptomsJson.isNotValue('[]')))
                  .get();
              for (final r in rows) {
                try {
                  final keys = (jsonDecode(r.symptomsJson) as List).cast<String>();
                  if (keys.isEmpty) continue;
                  final labels = keys.map(SymptomLibraryService.labelFor).toList();
                  await (update(wellbeingLogs)..where((t) => t.id.equals(r.id)))
                      .write(WellbeingLogsCompanion(tagsJson: Value(jsonEncode(labels))));
                } catch (_) {}
              }
            } catch (_) {}
          }
          if (from < 29) {
            // Довільні розділи архіву (заміна фіксованих сутностей медкартки —
            // алергії/хронічні захворювання/щеплення/операції/аналізи).
            try {
              await m.createTable(medcardSections);
            } catch (_) {}
            try {
              await m.createTable(medcardEntries);
            } catch (_) {}
          }
          if (from < 30) {
            // Аналізи/алергії/хронічні захворювання/щеплення/операції —
            // фіксовані медичні сутності повністю видалені (замінені
            // довільними розділами архіву з міграції 29). Перш ніж дропнути
            // самі таблиці — переносимо наявні записи в звичайний розділ
            // архіву (по одному розділу на категорію на члена сім'ї, лише
            // якщо в нього реально були записи), щоб апгрейд не з'їдав
            // історію користувача мовчки. Один шлях коду для обох сценаріїв
            // мовчання даних — і звичайне оновлення застосунку, і
            // відновлення старого бекапу на новій версії — обидва йдуть
            // через onUpgrade.
            Future<int> ensureSection(int memberId, String name, String iconKey) {
              return into(medcardSections).insert(MedcardSectionsCompanion.insert(
                memberId: memberId,
                name: name,
                iconKey: Value(iconKey),
              ));
            }

            try {
              final rows = await select(labResults).get();
              final byMember = <int, List<LabResult>>{};
              for (final r in rows) {
                (byMember[r.memberId] ??= []).add(r);
              }
              for (final e in byMember.entries) {
                final sectionId = await ensureSection(e.key, 'Аналізи (архів)', 'document');
                for (final r in e.value) {
                  final title = (r.testName?.isNotEmpty ?? false)
                      ? r.testName!
                      : (r.specialty.isNotEmpty ? r.specialty : 'Аналіз');
                  await into(medcardEntries).insert(MedcardEntriesCompanion.insert(
                    sectionId: sectionId,
                    memberId: e.key,
                    title: title,
                    recordDate: r.takenAt,
                    notes: Value(r.notes),
                    documentPaths: Value(r.documentPaths),
                  ));
                }
              }
            } catch (_) {}

            try {
              final rows = await select(allergies).get();
              final byMember = <int, List<Allergy>>{};
              for (final r in rows) {
                (byMember[r.memberId] ??= []).add(r);
              }
              for (final e in byMember.entries) {
                final sectionId = await ensureSection(e.key, 'Алергії (архів)', 'tag');
                for (final r in e.value) {
                  final notesParts = <String>[
                    if (r.reaction?.isNotEmpty ?? false) 'Реакція: ${r.reaction}',
                    if (r.severity.isNotEmpty) 'Тяжкість: ${r.severity}',
                    if (r.notes?.isNotEmpty ?? false) r.notes!,
                  ];
                  await into(medcardEntries).insert(MedcardEntriesCompanion.insert(
                    sectionId: sectionId,
                    memberId: e.key,
                    title: r.allergen,
                    recordDate: r.createdAt,
                    notes: Value(notesParts.isEmpty ? null : notesParts.join('\n')),
                    documentPaths: Value(r.documentPaths),
                  ));
                }
              }
            } catch (_) {}

            try {
              final rows = await select(chronicConditions).get();
              final byMember = <int, List<ChronicCondition>>{};
              for (final r in rows) {
                (byMember[r.memberId] ??= []).add(r);
              }
              for (final e in byMember.entries) {
                final sectionId = await ensureSection(e.key, 'Хронічні захворювання (архів)', 'folder');
                for (final r in e.value) {
                  await into(medcardEntries).insert(MedcardEntriesCompanion.insert(
                    sectionId: sectionId,
                    memberId: e.key,
                    title: r.name,
                    recordDate: r.diagnosedAt ?? r.createdAt,
                    notes: Value(r.notes),
                    documentPaths: Value(r.documentPaths),
                  ));
                }
              }
            } catch (_) {}

            final vaccinationIdsToCancel = <int>[];
            try {
              final rows = await select(vaccinations).get();
              final byMember = <int, List<Vaccination>>{};
              for (final r in rows) {
                (byMember[r.memberId] ??= []).add(r);
                vaccinationIdsToCancel.add(r.id);
              }
              for (final e in byMember.entries) {
                final sectionId = await ensureSection(e.key, 'Щеплення (архів)', 'calendar');
                for (final r in e.value) {
                  final notesParts = <String>[
                    if (r.nextDoseAt != null)
                      'Наступна доза: ${r.nextDoseAt!.toIso8601String().split('T').first}',
                    if (r.notes?.isNotEmpty ?? false) r.notes!,
                  ];
                  await into(medcardEntries).insert(MedcardEntriesCompanion.insert(
                    sectionId: sectionId,
                    memberId: e.key,
                    title: r.name,
                    recordDate: r.givenAt,
                    notes: Value(notesParts.isEmpty ? null : notesParts.join('\n')),
                    documentPaths: Value(r.documentPaths),
                  ));
                }
              }
            } catch (_) {}

            try {
              final rows = await select(surgeries).get();
              final byMember = <int, List<Surgery>>{};
              for (final r in rows) {
                (byMember[r.memberId] ??= []).add(r);
              }
              for (final e in byMember.entries) {
                final sectionId = await ensureSection(e.key, 'Операції (архів)', 'box');
                for (final r in e.value) {
                  await into(medcardEntries).insert(MedcardEntriesCompanion.insert(
                    sectionId: sectionId,
                    memberId: e.key,
                    title: r.name,
                    recordDate: r.performedAt,
                    notes: Value(r.notes),
                    documentPaths: Value(r.documentPaths),
                  ));
                }
              }
            } catch (_) {}

            // Заплановані OS-нагадування про ревакцинацію міграція сама
            // скасувати не може (тут лише SQL, немає доступу до плагіна
            // сповіщень) — залишаємо id на одноразове прибирання при
            // наступному старті застосунку, див.
            // NotificationService.cancelVaccinationReminder + виклик у
            // main.dart.
            if (vaccinationIdsToCancel.isNotEmpty) {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setStringList(
                  'pending_cancel_vaccination_notification_ids',
                  vaccinationIdsToCancel.map((id) => id.toString()).toList(),
                );
              } catch (_) {}
            }

            try {
              await m.deleteTable('lab_results');
            } catch (_) {}
            try {
              await m.deleteTable('allergies');
            } catch (_) {}
            try {
              await m.deleteTable('chronic_conditions');
            } catch (_) {}
            try {
              await m.deleteTable('vaccinations');
            } catch (_) {}
            try {
              await m.deleteTable('surgeries');
            } catch (_) {}
          }
          if (from < 31) {
            // DoctorAppointments → Reminders: чисте перейменування (не
            // видалення) — назва відповідала старій клінічній фічі "Візити
            // до лікарів", хоча ще з міграції 27 сутність уже стала
            // довільним нагадуванням (вільні теги замість словника
            // напрямків лікаря). RENAME TABLE зберігає всі рядки й колонки
            // як є — жодних даних не втрачається, лише фізична назва
            // таблиці стає чесною.
            try {
              await m.renameTable(reminders, 'doctor_appointments');
            } catch (_) {}
          }
          if (from < 32) {
            // Користувач сам обирає іконку нагадування (нейтральний набір
            // medcard_icons.dart) при додаванні — раніше картка завжди мала
            // жорстко зашитий медичний значок.
            try {
              await m.addColumn(reminders, reminders.iconKey);
            } catch (_) {}
          }
          if (from < 33) {
            // Простір — необов'язковий зв'язок із розділом архіву
            // (MedcardSections), який тепер може містити не лише нотатки,
            // а й самі завдання (ліки/активності/нагадування/самопочуття).
            // setNull при видаленні розділу — сам запис не зникає, просто
            // втрачає прив'язку.
            try {
              await m.addColumn(medications, medications.sectionId);
            } catch (_) {}
            try {
              await m.addColumn(activities, activities.sectionId);
            } catch (_) {}
            try {
              await m.addColumn(reminders, reminders.sectionId);
            } catch (_) {}
            try {
              await m.addColumn(wellbeingSchedules, wellbeingSchedules.sectionId);
            } catch (_) {}
          }
          if (from < 34) {
            // Об'єднана форма "Нагадування" (замінила окремі Зустрічі/
            // Спорт/Прості завдання) — розва подія (none), щоденний/
            // щотижневий повтор (час(и) у новій ReminderSlots) або щорічний
            // (наприклад дні народження, повтор нативний через
            // matchDateTimeComponents.dateAndTime — див. NotificationService).
            try {
              await m.addColumn(reminders, reminders.repeatType);
            } catch (_) {}
            try {
              await m.addColumn(reminders, reminders.repeatConfig);
            } catch (_) {}
            try {
              await m.createTable(reminderSlots);
            } catch (_) {}
          }
          if (from < 35) {
            // Нотатка без явно обраного Простору — падає в автостворений
            // розділ "Нотатки" (isDefaultNotes) замість блокування створення.
            try {
              await m.addColumn(medcardSections, medcardSections.isDefaultNotes);
            } catch (_) {}
          }
          if (from < 36) {
            // Per-occurrence стан виконання для повторюваних нагадувань —
            // див. коментар над класом ReminderLogs.
            try {
              await m.createTable(reminderLogs);
            } catch (_) {}
          }
          if (from < 37) {
            // Рутинні справи v2 — гнучкі повтори, сімейна ротація, чек-лист
            // підкроків, м'який статус partial. Див. коментарі над
            // Activities/ActivityAssignees/ActivityLogs у activities_table.dart.
            try {
              await m.addColumn(activities, activities.repeatType);
            } catch (_) {}
            try {
              await m.addColumn(activities, activities.repeatDayOfMonth);
            } catch (_) {}
            try {
              await m.addColumn(activities, activities.repeatIntervalDays);
            } catch (_) {}
            try {
              await m.addColumn(activities, activities.weeklyGoalCount);
            } catch (_) {}
            try {
              await m.addColumn(activities, activities.rotationAnchorDate);
            } catch (_) {}
            try {
              await m.addColumn(activities, activities.rotationMode);
            } catch (_) {}
            try {
              await m.addColumn(activities, activities.stepsJson);
            } catch (_) {}
            try {
              await m.createTable(activityAssignees);
            } catch (_) {}
            try {
              await m.addColumn(
                  activityLogs, activityLogs.completedByMemberId);
            } catch (_) {}
            try {
              await m.addColumn(
                  activityLogs, activityLogs.completedStepsJson);
            } catch (_) {}
            // Існуючі рядки Activities не мають rotationAnchorDate — без
            // нього формули ротації/everyNDays не мають точки відліку.
            // Бекфілимо значенням createdAt (== момент створення рутини,
            // той самий сенс, що заклав би новий запис).
            try {
              await customStatement(
                  'UPDATE activities SET rotation_anchor_date = created_at '
                  'WHERE rotation_anchor_date IS NULL');
            } catch (_) {}
          }
          if (from < 38) {
            // Прибираємо дублікати ReminderLogs, що назбирались через race
            // condition у ReminderLogGenerator (дві паралельні генерації
            // могли обидві вставити запис на те саме нагадування+час, перш
            // ніж сам генератор отримав захист від цього) — лишаємо лише
            // найстаріший (мінімальний id) рядок на кожну пару
            // reminder_id+scheduled_at.
            try {
              await customStatement(
                  'DELETE FROM reminder_logs WHERE id NOT IN '
                  '(SELECT MIN(id) FROM reminder_logs GROUP BY reminder_id, scheduled_at)');
            } catch (_) {}
          }
          if (from < 39) {
            // Прибираємо "сирітські" pending-записи, чиї ліки/рутина вже
            // видалені (isActive=false) чи фізично зникли — до фіксу в
            // ActivitiesRepository/MedicationsRepository.softDelete() (яка
            // раніше лише скасовувала сповіщення, а не сам pending-рядок)
            // такі записи лишались назавжди й показувались на Сьогодні як
            // картка-привид із заглушкою замість назви, що не реагує на
            // тап (перегляд шукає вже неіснуючий/неактивний батьківський
            // рядок). Минулі (done/skipped/taken) записи не чіпаємо — це
            // реальна історія.
            try {
              await customStatement(
                  "DELETE FROM activity_logs WHERE status = 'pending' AND "
                  'activity_id NOT IN (SELECT id FROM activities WHERE is_active = 1)');
            } catch (_) {}
            try {
              await customStatement(
                  "DELETE FROM intakes WHERE status IN ('pending', 'snoozed') AND "
                  'medication_id NOT IN (SELECT id FROM medications WHERE is_active = 1)');
            } catch (_) {}
          }
          if (from < 40) {
            // Вирівнюємо форму рутини з формою нагадування — теги/фото/
            // локація/іконка раніше існували лише в Reminders.
            await m.addColumn(activities, activities.tags);
            await m.addColumn(activities, activities.documentPaths);
            await m.addColumn(activities, activities.location);
            await m.addColumn(activities, activities.iconKey);
          }
          if (from < 41) {
            // "Ліки" -> "Інвентар": прибираємо режим відстеження залишку у
            // відсотках (stockPercent/openedAt) — лишається лише один,
            // явний прапорець trackStock. form стає вільним текстом (уже
            // був TextColumn, дефолт міняється лише для нових рядків);
            // додаємо stockUnit (одиниця виміру залишку) та iconKey
            // (спільний реєстр MedcardIcon, той самий, що й у розділах
            // Полички/рутинах).
            await m.addColumn(medications, medications.trackStock);
            await m.addColumn(medications, medications.stockUnit);
            await m.addColumn(medications, medications.iconKey);
            // Відсотковий режим видалено — такі записи просто лишаються без
            // відстеження (trackStock=0 за замовчуванням), користувач може
            // ввімкнути наново й обрати вже новий (кількісний) варіант.
            // Ті, хто вже мав кількісний режим (total_count>0), лишаються
            // з відстеженням увімкненим — цю поведінку не чіпаємо.
            try {
              await customStatement(
                  "UPDATE medications SET track_stock = 1 WHERE stock_percent IS NULL AND total_count > 0");
            } catch (_) {}
            // DROP COLUMN потребує SQLite 3.35+ (бандлований sqlcipher тут
            // новіший) — якщо раптом ні, колонки просто лишаються
            // невикористаним сміттям, не ламаючи міграцію.
            try {
              await customStatement(
                  'ALTER TABLE medications DROP COLUMN stock_percent');
            } catch (_) {}
            try {
              await customStatement(
                  'ALTER TABLE medications DROP COLUMN opened_at');
            } catch (_) {}
          }
          if (from < 42) {
            // "Відносно їжі" прибрано з форми Інвентарю — поле стосувалось
            // лише ліків, а не довільних предметів, і не використовується в
            // жодному розрахунку (лише інформативний підпис). DROP COLUMN —
            // той самий безпечний try/catch патерн, що й у v41 вище.
            try {
              await customStatement(
                  'ALTER TABLE medications DROP COLUMN food_relation');
            } catch (_) {}
          }
          if (from < 43) {
            // Драг-н-дроп для "Ваші розділи" — усі наявні рядки отримують
            // 0 за замовчуванням, що безпечно: сортування в watchByMember
            // йде [sortOrder, createdAt], тож поки sortOrder однаковий,
            // порядок лишається тим самим, що й був (за датою створення) —
            // жодного видимого стрибка для наявних користувачів.
            try {
              await m.addColumn(medcardSections, medcardSections.sortOrder);
            } catch (_) {}
          }
          if (from < 44) {
            // Крок 4.1 плану: права видимості по розділах (Розклад/Медкартка)
            // окремо для кожного члена сім'ї. Нові стовпчики зі значенням
            // false за замовчуванням — до першого grants_summary від піра
            // після оновлення це безпечно "нічого не видно по розділах",
            // старі view/editGranted (загальний доступ) продовжують діяти
            // як і раніше, не чіпаються.
            try {
              await m.addColumn(familyPeers, familyPeers.viewScheduleGranted);
            } catch (_) {}
            try {
              await m.addColumn(familyPeers, familyPeers.editScheduleGranted);
            } catch (_) {}
            try {
              await m.addColumn(familyPeers, familyPeers.viewMedcardGranted);
            } catch (_) {}
            try {
              await m.addColumn(familyPeers, familyPeers.editMedcardGranted);
            } catch (_) {}
          }
          if (from < 45) {
            // Крок 5-6 плану: RemindersSlots (час(и) нагадувань кілька разів
            // на день) раніше взагалі не мали технічної підготовки для
            // синхронізації — ні syncUuid, ні updatedAt.
            try {
              await m.addColumn(reminderSlots, reminderSlots.updatedAt);
            } catch (_) {}
            try {
              await m.addColumn(reminderSlots, reminderSlots.syncUuid);
            } catch (_) {}
          }
          if (from < 46) {
            // Крок 4.3.4 плану: Полички як окремий розділ прав видимості,
            // той самий принцип, що й у Кроку 4.1 для Розкладу/Медкартки.
            try {
              await m.addColumn(familyPeers, familyPeers.viewShelvesGranted);
            } catch (_) {}
            try {
              await m.addColumn(familyPeers, familyPeers.editShelvesGranted);
            } catch (_) {}
          }
          if (from < 47) {
            // Крок 7.1 плану: "тіньовий" dependent-рядок, що представляє
            // автономного члена сім'ї в пулі ротації рутинної справи.
            try {
              await m.addColumn(members, members.linkedPeerPersonUuid);
            } catch (_) {}
          }
          if (from < 48) {
            // Реальний краш у продакшені (04.08): нагадування зі старими
            // ReminderSlots-рядками (з часів ДО версії 45, коли ця таблиця
            // ще не мала updatedAt) лишились із NULL у цій колонці —
            // припущення "DEFAULT currentDateAndTime сам заповнить старі
            // рядки" (коментар при version 5 вище) на практиці не
            // спрацювало для кожного пристрою. RemindersRepository читає
            // ReminderSlots не через nullable-safe шлях, тож NULL валив
            // Drift-мапер винятком — і через відсутній per-item захист у
            // watchActiveOnDate (тепер додано окремо) це гасило ВЕСЬ список
            // нагадувань на Сьогодні для профілю, а не лише зламаний запис.
            // Явний backfill тут — не покладаємось більше на DEFAULT для
            // datetime-колонок, доданих через addColumn заднім числом.
            // Заразом перевіряємо решту колонок, доданих тим самим шляхом
            // (version 5) — той самий ризик, навіть якщо конкретно ці поки
            // не спричинили видимого краху.
            for (final stmt in [
              'UPDATE reminder_slots SET updated_at = CURRENT_TIMESTAMP WHERE updated_at IS NULL',
              'UPDATE members SET updated_at = CURRENT_TIMESTAMP WHERE updated_at IS NULL',
              'UPDATE medications SET updated_at = CURRENT_TIMESTAMP WHERE updated_at IS NULL',
              'UPDATE schedules SET updated_at = CURRENT_TIMESTAMP WHERE updated_at IS NULL',
              'UPDATE intakes SET updated_at = CURRENT_TIMESTAMP WHERE updated_at IS NULL',
              'UPDATE symptoms SET updated_at = CURRENT_TIMESTAMP WHERE updated_at IS NULL',
              'UPDATE wellbeing_logs SET updated_at = CURRENT_TIMESTAMP WHERE updated_at IS NULL',
              'UPDATE wellbeing_schedules SET updated_at = CURRENT_TIMESTAMP WHERE updated_at IS NULL',
              'UPDATE activities SET updated_at = CURRENT_TIMESTAMP WHERE updated_at IS NULL',
              'UPDATE activity_slots SET updated_at = CURRENT_TIMESTAMP WHERE updated_at IS NULL',
              'UPDATE activity_logs SET updated_at = CURRENT_TIMESTAMP WHERE updated_at IS NULL',
              'UPDATE doctor_appointments SET updated_at = CURRENT_TIMESTAMP WHERE updated_at IS NULL',
            ]) {
              try {
                await customStatement(stmt);
              } catch (_) {}
            }
          }
          if (from < 49) {
            // Драг-н-дроп порядку відображення в перемикачах "хто зараз
            // активний" (Сьогодні/MemberSwitcherPill) — керується на екрані
            // Сім'я. members.sortOrder і familyPeers.sortOrder — окремі
            // простори значень (піри завжди рендеряться власним блоком
            // ПІСЛЯ локальних членів), тож звичайний addColumn з DEFAULT 0
            // тут безпечний.
            try {
              await m.addColumn(members, members.sortOrder);
            } catch (_) {}
            try {
              await m.addColumn(familyPeers, familyPeers.sortOrder);
            } catch (_) {}
          }
          if (from < 50) {
            // Виправлення попереднього backfill'у (v48) — той писав
            // updated_at через сирий CURRENT_TIMESTAMP (текстовий формат
            // SQLite), а ця база зберігає DateTime як unix-час у СЕКУНДАХ
            // (ціле число) — [AppDatabase] не передає storeDateTimeAsText,
            // тож діє дефолт drift (false = int, не text). currentDateAndTime
            // з Дart-коду (m.addColumn нижче й раніше) сам підбирає
            // правильний формат під це налаштування — а от сирий SQL-рядок
            // v48 такого не робив, тож замість NULL колонка отримала
            // текстовий рядок, який Drift-мапер так само не міг прочитати
            // як DateTime (падав так само, лише мовчки — цього разу вже
            // спіймано новим try/catch у watchActiveOnDate, але дані
            // лишались зіпсованими). typeof(...) != 'integer' ловить і
            // старий NULL, і зіпсований текст від v48 одним запитом;
            // unixepoch() — те саме SQLite-вираження, яким drift компілює
            // currentDateAndTime у режимі зберігання як ціле число.
            for (final table in _kUpdatedAtRepairTables) {
              try {
                await customStatement(
                    "UPDATE $table SET updated_at = unixepoch() WHERE typeof(updated_at) != 'integer'");
              } catch (_) {}
            }
          }
          if (from < 51) {
            // Крок 3.3 (справжня причина): FamilyPeers.introductionSent —
            // див. коментар при колонці. DEFAULT false (не true!) —
            // навмисно, щоб і вже наявні "мене хтось запросив" рядки теж
            // отримали одну повторну спробу надіслати картку після цього
            // фіксу, а не лишились "начебто вже відправленими" назавжди.
            try {
              await m.addColumn(familyPeers, familyPeers.introductionSent);
            } catch (_) {}
          }
        },
        beforeOpen: (details) async {
          // Безумовний самоцілющий прохід — див. коментар при
          // _kUpdatedAtRepairTables вище. На відміну від onUpgrade,
          // виконується щоразу при відкритті з'єднання (свіжий пристрій,
          // оновлення "на місці", відновлення з бекапу — байдуже), тож не
          // залежить від того, яким шляхом і з яким user_version файл
          // фізично потрапив на цей пристрій.
          //
          // Спершу захисний ALTER TABLE ... ADD COLUMN — реальний випадок з
          // логів build 67: на пристрої користувача updated_at був не
          // "зіпсований", а фізично ВІДСУТНІЙ як колонка (m.addColumn у
          // блоці if (from < 45) сам колись мовчки впав — ADD COLUMN з
          // виразом-DEFAULT (currentDateAndTime) підтримується не скрізь),
          // тож будь-який UPDATE на цю колонку одразу падав з
          // "no such column". Тут — проста форма без виразу-DEFAULT
          // (сумісніша), і лише якщо колонка вже є — "duplicate column"
          // ловиться тим самим catch (це штатний випадок для здорових
          // пристроїв, де колонка вже існує).
          for (final table in _kUpdatedAtRepairTables) {
            try {
              await customStatement('ALTER TABLE $table ADD COLUMN updated_at INTEGER');
            } catch (_) {}
          }
          // Той самий захист для family_peers.introduction_sent — non-
          // nullable boolean-колонка читається через такий самий '!' у
          // згенерованому мапері, тож якщо m.addColumn у if (from < 51)
          // колись мовчки впаде так само, як для updated_at — це зламає
          // ВЕСЬ екран Сім'я (кожен рядок FamilyPeers), не лише повторну
          // відправку картки. DEFAULT 0 ("false") — той самий дефолт, що й
          // Constant(false) у Dart-класі (див. коментар при колонці —
          // навмисно false, не true, щоб вже наявні рядки теж отримали
          // повторну спробу).
          try {
            await customStatement(
                'ALTER TABLE family_peers ADD COLUMN introduction_sent INTEGER DEFAULT 0');
          } catch (_) {}
          // Реальний краш у продакшені (06.08, з логів build 80): та сама
          // причина, що й для updated_at вище, але інший механізм —
          // reminderSlots.syncUuid оголошений як `.unique()()` у Dart-класі,
          // а SQLite В ПРИНЦИПІ забороняє додавати UNIQUE-колонку через
          // ALTER TABLE ADD COLUMN (лише через CREATE TABLE) — тож
          // `m.addColumn(reminderSlots, reminderSlots.syncUuid)` у
          // `if (from < 45)` вище падав на КОЖНОМУ пристрої, який пройшов
          // цей крок оновлення "на місці" (не лише на "деяких платформах",
          // як для updated_at), а не лише мовчки ковтався. Без цієї колонки
          // FamilyPeerSyncService._assignMissingUuids кидав виняток при
          // спробі призначити syncUuid новим рядкам — і через відсутній
          // try/catch навколо ЦІЄЇ конкретної підфункції (на відміну від
          // самого _push) валив УВЕСЬ раунд синку з пірами на кожному
          // тригері, назавжди. Без UNIQUE тут (ALTER TABLE фізично не може
          // її додати) — прийнятний компроміс, значення й так генеруються
          // клієнтом як UUID v4, практично гарантовано унікальні.
          try {
            await customStatement('ALTER TABLE reminder_slots ADD COLUMN sync_uuid TEXT');
          } catch (_) {}
          // Той самий клас багу (07.08): 6 boolean-колонок дозволів по
          // розділах (view/editScheduleGranted, view/editMedcardGranted з
          // if (from < 44), view/editShelvesGranted з if (from < 46)) теж
          // додавались через m.addColumn у мовчазному try/catch вище.
          // FamilyPeersRepository.updateGrantedToMe записує всі 10
          // прапорців ОДНИМ UPDATE — якщо бодай однієї з цих 6 колонок
          // фізично нема, весь запит падає з "no such column", і жоден
          // грант від піра більше ніколи не застосовується на цьому
          // пристрої, скільки б piр не пересилав коректний grants_summary.
          for (final col in [
            'view_schedule_granted',
            'edit_schedule_granted',
            'view_medcard_granted',
            'edit_medcard_granted',
            'view_shelves_granted',
            'edit_shelves_granted',
          ]) {
            try {
              await customStatement('ALTER TABLE family_peers ADD COLUMN $col INTEGER DEFAULT 0');
            } catch (_) {}
          }
          // Сам UPDATE — помилки тут НЕ ковтаються мовчки (на відміну від
          // onUpgrade-кроків і ALTER вище) — якщо після захисного ALTER
          // колонка досі чомусь недоступна, маємо про це дізнатись, а не
          // просто мовчки лишити дані зіпсованими.
          for (final table in _kUpdatedAtRepairTables) {
            try {
              await customStatement(
                  "UPDATE $table SET updated_at = unixepoch() WHERE typeof(updated_at) != 'integer'");
            } catch (e, st) {
              AppLogger.logError('AppDatabase.beforeOpen repair ($table)', e, st);
            }
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file = await DbEncryptionService.databaseFile();
    final key = await DbEncryptionService.ensureEncryptedDatabase(file);
    // ТИМЧАСОВЕ діагностичне логування (розслідування SqliteException(26) —
    // байтовий аналіз завантаженого medkit.db показав ЖОДНИХ ознак
    // пошкодження/обрізання файлу, тож підозра повертається до самого
    // значення ключа/його застосування). Логуємо лише ВІДБИТОК (не сам
    // ключ — секрет) того значення, яке за мить піде у PRAGMA key
    // реального з'єднання (виконується тут, на головному ізоляті, ДО
    // передачі в замикання setup нижче — сам setup-колбек виконується у
    // фоновому ізоляті createInBackground, де AppLogger писати ненадійно,
    // бо platform channels там окремі). Прибрати після завершення
    // розслідування.
    AppLogger.log(
      'AppDatabase: opening real connection, key fingerprint='
      '${DbEncryptionService.keyFingerprint(key)}',
    );
    return NativeDatabase.createInBackground(
      file,
      // createInBackground виконується у власному ізоляті — override
      // потрібен там окремо, той що в main() стосується лише головного.
      isolateSetup: () async {
        if (Platform.isAndroid) {
          sqlite3_open.open.overrideFor(
              sqlite3_open.OperatingSystem.android, openCipherOnAndroid);
        }
      },
      // key вже прийде у форматі SQLCipher raw-key: x'64-hex-символи',
      // тому саме значення оточуємо подвійними лапками, а не одинарними.
      setup: (db) {
        db.execute('PRAGMA key = "$key";');
        // SQLite не застосовує ON DELETE CASCADE (всюди прописаний у
        // таблицях) без цього — без нього видалення профілю лишало б
        // "осиротілі" ліки/розклади/прийоми в базі.
        db.execute('PRAGMA foreign_keys = ON;');
      },
    );
  });
}
