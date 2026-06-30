# MedKit — Claude Code Context

## Проект
Flutter-додаток для управління ліками сім'ї. Фіолетова палітра (#7048C4). Підтримка декількох мов (uk, en — і більше в майбутньому).

## Заборони (КРИТИЧНО)
- НІКОЛИ не згадувати російські сайти/сервіси/рублі
- Аптеки тільки українські: Liki24.com, Tabletki.ua, Doc.ua, Helsi.me
- Ціни тільки в $ або грн

## Структура
```
lib/
  core/theme/       # AppColors, AppTextStyles, AppDimensions, AppTheme
  core/utils/       # date_utils.dart, l10n_ext.dart
  data/models/      # Medication, MedIntake, FamilyMember
  features/today/   # TodayScreen + widgets
  features/...      # інші екрани (meds, family, profile)
  shared/widgets/   # MkCard, MkButton, SectionLabel, AppBottomNav
  l10n/             # app_uk.arb, app_en.arb (шаблон — uk)
  main.dart         # MedKitApp + _Shell (5 вкладок)
docs/               # MedKit_Brief.html, MedKit_Screens.html
```

## Кольори (AppColors)
- primary: #7048C4 — основний фіолетовий
- accent: #F4855A — теплий акцент
- bg: #FAF8FF, surface: #FFFFFF
- success/warning/danger зі світлими варіантами

## i18n
- Всі рядки UI — тільки через `context.l10n.ключ`
- Нові ключі додавати в обидва ARB файли одночасно
- `flutter gen-l10n` запускається автоматично при `flutter run`

## Команди
```bash
flutter pub get          # після зміни pubspec.yaml
flutter run              # запуск (iOS: потрібен Mac з Xcode)
flutter analyze          # перевірка помилок
flutter test             # тести
```

## Важливо
- `withOpacity()` — ЗАСТАРІЛИЙ, використовувати `.withValues(alpha: x)`
- Розробка на Mac (Xcode + iPhone)
- Backend: PHP 8.2 + MySQL (окремий проект, ще не розпочато)
- API ключі (GPT-4o, Claude) — ТІЛЬКИ на сервері, ніколи в app
