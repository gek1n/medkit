import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart' as sqlite3_open;
import 'package:uuid/uuid.dart';

import '../../core/services/db_encryption_service.dart';
import 'tables/members_table.dart';
import 'tables/medications_table.dart';
import 'tables/schedules_table.dart';
import 'tables/intakes_table.dart';
import 'tables/symptoms_table.dart';
import 'tables/wellbeing_logs_table.dart';
import 'tables/wellbeing_schedules_table.dart';
import 'tables/activities_table.dart';
import 'tables/doctor_appointments_table.dart';
import 'tables/lab_results_table.dart';
import 'tables/allergies_table.dart';
import 'tables/chronic_conditions_table.dart';
import 'tables/vaccinations_table.dart';
import 'tables/surgeries_table.dart';
import 'tables/shared_channels_table.dart';
import 'tables/family_peers_table.dart';
import 'tables/family_grants_table.dart';

part 'app_database.g.dart';

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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 21;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
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
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file = await DbEncryptionService.databaseFile();
    final key = await DbEncryptionService.ensureEncryptedDatabase(file);
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
