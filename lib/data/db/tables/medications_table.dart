import 'package:drift/drift.dart';
import 'medcard_sections_table.dart';
import 'members_table.dart';

class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  IntColumn get sectionId => integer()
      .nullable()
      .references(MedcardSections, #id, onDelete: KeyAction.setNull)();
  // Необов'язковий Простір (розділ архіву) — той самий розділ, куди можна
  // класти й нотатки. Видалення розділу не видаляє самі ліки, лише
  // відв'язує їх (setNull), на відміну від MedcardEntries, які каскадно
  // видаляються разом із розділом.
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get form => text().withDefault(const Constant(''))();
  // вільний текст (напр. "Флакон", "Пачка") — до v41 був фіксованим
  // переліком tablet/capsule/syrup/... що керував іконкою й одиницею виміру;
  // тепер це окремо: iconKey (нижче) та stockUnit.
  RealColumn get doseAmount => real()();
  TextColumn get doseUnit => text().withDefault(const Constant('мг'))();
  TextColumn get foodRelation => text().withDefault(const Constant('any'))();
  // before/after/with/any
  TextColumn get repeatType => text().withDefault(const Constant('daily'))();
  // daily/alternate/weekdays/every_n/cycle
  TextColumn get repeatConfig =>
      text().withDefault(const Constant('{}'))();
  // json: {days:[1,3,5]} / {n:3} / {on:7,off:3}
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  // null = постійний
  IntColumn get totalCount => integer().withDefault(const Constant(0))();
  IntColumn get remainingCount => integer().withDefault(const Constant(0))();
  TextColumn get photoPaths =>
      text().withDefault(const Constant('[]'))();
  // json: ["path1","path2"]
  TextColumn get instructions => text().nullable()();
  TextColumn get phases => text().nullable()();
  // json: [{"times":["08:00"],"durationDays":7}, ...]
  BoolColumn get trackStock => boolean().withDefault(const Constant(false))();
  // до v41 відстеження залишку вмикалось лише неявно (stockPercent!=null) —
  // явний прапорець, той самий підхід, що й лишається робочим для
  // count-режиму незалежно від відсоткового (видаленого в v41).
  TextColumn get stockUnit => text().nullable()();
  // одиниця виміру залишку (г/кг/мл/л/шт/склянка/...) — обирається окремо
  // від form, використовується в розрахунку "потрібно докупити".
  TextColumn get iconKey => text().nullable()();
  // ключ повнокольорової іконки картки — той самий MedcardIcon/
  // medcardIconKeys реєстр, що й для розділів Полички/кольору рутин.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable().unique()();
  TextColumn get color => text().nullable()();
  // hex "#RRGGBB" — кастомний колір картки, null = дефолтний колір типу
  // глобально унікальний ідентифікатор для сімейної синхронізації (family_sync) —
  // призначається лише коли член сім'ї прив'язаний до каналу, на відміну від
  // локального autoincrement id, який не унікальний між пристроями
  TextColumn get sideEffects => text().nullable()();
  // json: ["назва побічного ефекту", ...] — довідково від ІІ під час
  // сканування рецепта/упаковки (PrescriptionScanService), null для ліків,
  // доданих вручну або без цієї інформації на фото.
}
