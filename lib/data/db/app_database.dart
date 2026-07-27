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
  DoctorAppointments,
  Reminders,
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
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 32;

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
            try {
              await m.addColumn(medications, medications.stockPercent);
            } catch (_) {}
            try {
              await m.addColumn(medications, medications.openedAt);
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
