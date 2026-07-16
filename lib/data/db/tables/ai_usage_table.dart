import 'package:drift/drift.dart';

/// Лічильники безкоштовних AI-викликів (скан рецепта за фото, голосові
/// команди) — один рядок (id завжди 0), навмисно в самій БД, а не в
/// SharedPreferences: SharedPreferences НЕ потрапляє в резервну копію
/// (`BackupService`/`BackupCryptoService` пакують лише medkit.db і
/// med_photos/), а ці лічильники мають "виживати" відновлення бекапу так
/// само, як і решта даних — інакше видалення застосунку й відновлення
/// бекапу мовчки обнуляло б витрачені безкоштовні спроби.
class AiUsage extends Table {
  IntColumn get id => integer()();
  IntColumn get photoScansUsed => integer().withDefault(const Constant(0))();
  IntColumn get voiceCommandsUsed => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
