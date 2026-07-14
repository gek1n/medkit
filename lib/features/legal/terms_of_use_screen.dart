import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/mk_screen_header.dart';
import 'legal_content_widgets.dart';

/// Повний текст Умов використання — те саме, що й
/// `docs/MedKit_Terms_UK.html`, перенесене в нативний вигляд (той самий
/// підхід, що й PrivacyPolicyScreen — щоб не тягнути webview заради одного
/// статичного документа).
/// ⚠️ Тримати синхронізованим з HTML-версією вручну при правках документа.
/// Тарифи в розділі 4 навмисно відрізняються від застарілої версії в HTML
/// (там ще старі назви "Турбота"/"Сім'я" й ліміти) — тут актуальні
/// Elly/Plus/Family з plans_screen.dart.
class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const MkScreenHeader(title: 'Умови використання'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Набирає чинності: липень 2026 · Версія 1.0',
                            style: AppTextStyles.labelMd.copyWith(color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._sections.map((s) => LegalSectionWidget(section: s)),
                  const SizedBox(height: 8),
                  Text(
                    'Elly © 2026. Ці Умови застосовуються разом з Політикою конфіденційності.',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _sections = <LegalSection>[
  LegalSection(Icons.check_circle_outline_rounded, '1. Прийняття умов', [
    legalP(
      'Використовуючи застосунок Elly, ви погоджуєтесь з цими Умовами '
      'використання та з Політикою конфіденційності. Якщо ви не погоджуєтесь '
      'з будь-яким пунктом — будь ласка, не використовуйте застосунок.',
    ),
    legalP(
      'Якщо ви керуєте профілями інших членів родини (дітей, батьків '
      'похилого віку), ви підтверджуєте, що маєте на це право та несете '
      'відповідальність за дії, здійснені через ці профілі.',
    ),
  ]),
  LegalSection(Icons.medical_services_outlined, '2. Медичне застереження', [
    legalCallout(
      'Elly не є медичним пристроєм, не надає медичних консультацій і не '
      'замінює лікаря чи фармацевта. Застосунок допомагає організовувати й '
      'нагадувати про прийом ліків на основі даних, які ви самі вносите. '
      'Точність нагадувань залежить від точності введених вами даних.',
      bg: AppColors.dangerLight,
      border: AppColors.danger,
      fg: AppColors.textMain,
    ),
    legalCallout(
      'У разі невідкладного стану телефонуйте до служби екстреної медичної '
      'допомоги. Не покладайтесь на застосунок у критичних чи невідкладних '
      'ситуаціях: сповіщення можуть затримуватись або не спрацювати через '
      'налаштування пристрою, відсутність інтернету, розряджений акумулятор '
      'тощо.',
      bg: AppColors.warningLight,
      border: AppColors.warning,
      fg: AppColors.textMain,
    ),
    legalP(
      'Остаточні рішення щодо дозування, схеми лікування чи заміни '
      'препаратів приймає виключно лікар або фармацевт, а не застосунок.',
    ),
  ]),
  LegalSection(Icons.build_outlined, '3. Опис сервісу', [
    legalP(
      'Elly — мобільний застосунок для планування прийому ліків, '
      "відстеження самопочуття, ведення записів до лікаря та (опційно) "
      "синхронізації розкладу між пристроями користувача чи членів сім'ї. "
      'Реєстрація не потрібна; дані зберігаються локально на пристрої, як '
      'описано в Політиці конфіденційності.',
    ),
  ]),
  LegalSection(Icons.credit_card_rounded, '4. Тарифні плани та оплата', [
    Text('Elly (безкоштовний)', style: AppTextStyles.labelMd),
    const SizedBox(height: 4),
    legalBullets([
      'Всі розділи без обмежень, необмежено ліків і медкарток;',
      '3 сканування фото рецепта, 5 голосових команд;',
      'Локально на пристрої + опційна копія в Google Drive/iCloud.',
    ]),
    const SizedBox(height: 8),
    Text('Elly Plus', style: AppTextStyles.labelMd),
    const SizedBox(height: 4),
    legalBullets([
      'Все з безкоштовного;',
      'Необмежені сканування фото й голосові команди;',
      'Синхронізація з сервером (зашифровано);',
      'Необмежена кількість локальних профілів.',
    ]),
    const SizedBox(height: 8),
    Text('Elly Family', style: AppTextStyles.labelMd),
    const SizedBox(height: 4),
    legalBullets([
      'Все з Elly Plus;',
      "Автономні профілі — до 8 осіб;",
      'Кожен учасник керує своїм профілем сам.',
    ]),
    const SizedBox(height: 8),
    legalP(
      'Платні плани оформлюються та оплачуються через App Store (Apple) або '
      'Google Play — Elly не обробляє й не зберігає дані вашої платіжної '
      'картки самостійно.',
    ),
    legalCallout(
      'Автоматичне продовження. Підписка Elly Plus/Family автоматично '
      'продовжується на новий період за тією самою ціною, якщо ви не '
      'скасуєте її щонайменше за 24 години до завершення поточного періоду. '
      'Оплата списується з вашого облікового запису App Store/Google Play '
      'при підтвердженні покупки та повторно — при кожному продовженні. '
      'Керувати підпискою чи скасувати автопродовження можна в налаштуваннях '
      'вашого облікового запису App Store/Google Play — самому застосунку '
      'Elly ця можливість недоступна.',
      bg: AppColors.primaryLight,
      border: AppColors.primary,
      fg: AppColors.primaryDark,
    ),
  ]),
  LegalSection(Icons.person_outline_rounded, '5. Ваші обов\'язки', [
    legalBullets([
      "Вносити дані про ліки та розклад точно й вчасно оновлювати їх при змінах;",
      "Не використовувати застосунок для зберігання неправдивої чи оманливої "
          "медичної інформації, що стосується інших людей без їхньої згоди;",
      "Забезпечити безпеку доступу до свого пристрою (код блокування, "
          "біометрія) — Elly не може захистити дані, якщо доступ до "
          "розблокованого пристрою отримає третя особа;",
      "Не намагатись обійти технічні обмеження застосунку чи втручатись у "
          "роботу сервера.",
    ]),
  ]),
  LegalSection(Icons.copyright_rounded, '6. Інтелектуальна власність', [
    legalP(
      'Застосунок Elly, його дизайн, логотип і код належать розробнику '
      'застосунку. Дані, які ви вносите (ліки, розклад, фото тощо), '
      'належать виключно вам.',
    ),
  ]),
  LegalSection(Icons.block_rounded, '7. Обмеження відповідальності', [
    legalP('Застосунок надається «як є», без будь-яких гарантій. Розробник не несе відповідальності за:'),
    legalBullets([
      'Пропущені чи затримані сповіщення через обставини поза контролем '
          'застосунку (налаштування ОС, відсутність інтернету, розряджений '
          'пристрій тощо);',
      'Наслідки рішень, прийнятих на основі даних, внесених користувачем '
          'самостійно;',
      'Втрату даних через видалення застосунку без попереднього створення '
          'резервної копії.',
    ]),
  ]),
  LegalSection(Icons.logout_rounded, '8. Припинення дії', [
    legalP(
      'Ви можете припинити користування застосунком у будь-який час, '
      'видаливши його з пристрою. Оскільки акаунтів немає, "блокування" чи '
      '"видалення акаунта" з нашого боку не застосовується — весь контроль '
      'над даними завжди залишається у вас.',
    ),
  ]),
  LegalSection(Icons.edit_note_rounded, '9. Зміни до цих Умов', [
    legalP(
      'Ми можемо оновлювати ці Умови з часом. Про суттєві зміни ми '
      'повідомимо в застосунку. Продовження використання застосунку після '
      'змін означає згоду з оновленими Умовами.',
    ),
  ]),
  LegalSection(Icons.gavel_rounded, '10. Застосовне право', [
    legalP(
      'Ці Умови регулюються законодавством України, якщо інше не '
      'вимагається обов\'язковими нормами права країни вашого проживання.',
    ),
  ]),
  LegalSection(Icons.mail_outline_rounded, '11. Контакти', [
    legalP('Питання щодо цих Умов — на support@elly-medkit.com.'),
  ]),
];
