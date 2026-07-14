import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/mk_screen_header.dart';

class _Faq {
  final String q;
  final String a;
  const _Faq(this.q, this.a);
}

class _FaqGroup {
  final String title;
  final IconData icon;
  final List<_Faq> items;
  const _FaqGroup(this.title, this.icon, this.items);
}

const _groups = <_FaqGroup>[
  _FaqGroup('Приватність і дані', Icons.lock_outline_rounded, [
    _Faq(
      'Хто бачить мої дані?',
      'Ніхто, крім вас. Усе зберігається зашифрованим на вашому пристрої '
          '(SQLCipher, AES-256). Сервер Elly навмисно "сліпий": реєстрації '
          'через email чи пароль немає, а те, що все ж проходить через '
          'сервер (запрошення до сім\'ї, синхронізація, підтвердження '
          'підписки), бачить лише зашифровані блоки й технічні '
          'ідентифікатори — без ключа розшифрувати їх неможливо.',
    ),
    _Faq(
      'У чому різниця між Резервною копією і Запрошенням до сім\'ї?',
      'Резервна копія — знімок ваших власних даних у вашому Google Drive/'
          'iCloud на випадок втрати телефону чи перевстановлення '
          'застосунку. Запрошення до сім\'ї — живий обмін розкладом між '
          'РІЗНИМИ людьми (наприклад, дитина бачить розклад мами) через '
          'QR-код чи код запрошення. Це два різні механізми: перший — про '
          'вас самих, другий — про спільний доступ між кількома людьми.',
    ),
    _Faq(
      'Що буде, якщо я видалю застосунок без бекапу?',
      'Дані буде втрачено безповоротно — копії на сервері не існує. '
          'Обов\'язково зробіть резервну копію заздалегідь (Профіль → '
          'Резервна копія).',
    ),
    _Faq(
      'Як видалити свої дані повністю?',
      'Видаліть застосунок з пристрою (і резервну копію з Drive/iCloud '
          'вручну, якщо створювали). Профіль також можна видалити окремо — '
          'Профіль → Конфіденційність → Небезпечна зона.',
    ),
  ]),
  _FaqGroup('Сім\'я', Icons.family_restroom_rounded, [
    _Faq(
      'Як додати члена сім\'ї чи залежний профіль?',
      'На вкладці "Сім\'я" — кнопка додавання профілю. Залежні профілі '
          '(діти, батьки похилого віку) не мають власного входу — ними '
          'керує власник пристрою.',
    ),
    _Faq(
      'Як передати керування профілем іншій людині (наприклад, дорослій дитині)?',
      'На картці локального профілю — кнопка "Запросити в застосунок": '
          'покажіть QR-код чи назвіть код запрошення людині, яка '
          'приєднується на своєму пристрої. Профіль перетвориться з '
          'локального на автономний — людина відтепер керуватиме ним сама, '
          'а вся історія даних збережеться. Дані шифруються ключем, '
          'похідним від коду запрошення, — сервер бачить лише зашифрований '
          'блок.',
    ),
    _Faq(
      'Хто що бачить про інших членів сім\'ї?',
      'Налаштовується в Профіль → Видимість для сім\'ї — окремо для '
          'кожного профілю.',
    ),
  ]),
  _FaqGroup('AI-функції', Icons.smart_toy_outlined, [
    _Faq(
      'Куди йдуть дані при голосовому вводі чи скані рецепта?',
      'Розпізнавання відбувається через модель Claude від Anthropic — це '
          'явно вказується в запиті згоди перед першим використанням '
          'кожної функції. Вільний текстовий опис самопочуття чи симптомів '
          'у хмару ніколи не надсилається.',
    ),
    _Faq(
      'Наскільки точна довідкова інформація про ліки від AI?',
      'Це орієнтовна інформація із загальних знань моделі, а не '
          'перевірений медичний каталог. Завжди звіряйте з інструкцією до '
          'препарату чи лікарем.',
    ),
  ]),
  _FaqGroup('Сповіщення', Icons.notifications_none_rounded, [
    _Faq(
      'Чому не приходять нагадування?',
      'Найчастіша причина — оптимізація батареї на Android обмежує '
          'фонову роботу застосунку. Додайте Elly у виключення в '
          'налаштуваннях енергозбереження пристрою. Також перевірте "Тихі '
          'години" в Профіль → Сповіщення.',
    ),
    _Faq(
      'Як налаштувати повторне нагадування, якщо не відмітив прийом?',
      'Профіль → Сповіщення → "Повторити якщо нема відповіді" — виберіть '
          'інтервал повзунком.',
    ),
  ]),
  _FaqGroup('Тарифи', Icons.workspace_premium_outlined, [
    _Faq(
      'Чим відрізняються тарифи?',
      'Elly (безкоштовний) — базові функції з обмеженнями. Elly Plus і '
          'Elly Family знімають ліміти й додають розширені можливості. '
          'Деталі — Профіль → Тарифи.',
    ),
  ]),
  _FaqGroup('Технічні проблеми', Icons.build_outlined, [
    _Faq(
      'Не працює біометрія / забув пароль від резервної копії',
      'Пароль резервної копії запам\'ятовується лише локально на цьому '
          'пристрої (щоб автоматичні копії за розкладом не питали його '
          'щоразу) — на наші сервери він ніколи не потрапляє. Якщо ви '
          'перевстановите застосунок чи зміните пристрій, доведеться '
          'ввести той самий пароль вручну; якщо забули його — відновити '
          'копію неможливо, доведеться створити нову. Біометрію можна '
          'переналаштувати в системних налаштуваннях пристрою.',
    ),
    _Faq(
      'Не вдається відновити дані з резервної копії',
      'Найчастіша причина — невірний пароль (той самий, який ви вказали '
          'при створенні копії) або відсутнє з\'єднання з інтернетом. '
          'Перевірте, що відновлюєте копію на відповідному типі пристрою '
          '(з iCloud — лише на iOS, з Google Drive — на Android чи iOS). '
          'Після успішного відновлення застосунок попросить перезапуститись.',
    ),
  ]),
];

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const MkScreenHeader(title: 'Допомога та FAQ'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  for (final g in _groups) ...[
                    _GroupHeader(icon: g.icon, title: g.title),
                    const SizedBox(height: AppDimensions.sm),
                    ...g.items.map((f) => _FaqTile(faq: f)),
                    const SizedBox(height: AppDimensions.lg),
                  ],
                  const _ContactsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _GroupHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title,
              style: AppTextStyles.bodyMd.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final _Faq faq;
  const _FaqTile({required this.faq});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(faq.q, style: AppTextStyles.labelLg),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: EdgeInsets.zero,
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textMuted,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(faq.a, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactsCard extends StatelessWidget {
  const _ContactsCard();

  Future<void> _openMail(String address) => launchUrl(Uri(scheme: 'mailto', path: address));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Не знайшли відповідь?', style: AppTextStyles.labelLg),
          const SizedBox(height: 4),
          Text(
            'Напишіть нам — відповімо особисто.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: AppDimensions.md),
          _ContactRow(
            icon: Icons.mail_outline_rounded,
            label: 'Підтримка',
            value: 'support@elly-medkit.com',
            onTap: () => _openMail('support@elly-medkit.com'),
          ),
          const SizedBox(height: AppDimensions.sm),
          _ContactRow(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Чат підтримки',
            value: 'Скоро',
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
                  Text(
                    value,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: onTap != null ? AppColors.primary : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
