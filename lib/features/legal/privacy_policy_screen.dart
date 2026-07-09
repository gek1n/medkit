import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/mk_screen_header.dart';

/// Повний текст Політики конфіденційності — те саме, що й
/// `docs/MedKit_Privacy_Policy_UK.html`, перенесене в нативний вигляд, щоб не
/// тягнути webview-залежність заради одного статичного документа.
/// ⚠️ Тримати синхронізованим з HTML-версією вручну при правках документа.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const MkScreenHeader(title: 'Політика конфіденційності'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_rounded, color: AppColors.primary),
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
                  ..._sections.map((s) => _SectionWidget(section: s)),
                  const SizedBox(height: 8),
                  Text(
                    'MedKit © 2026. Ця Політика застосовується разом з Умовами використання.',
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

class _Section {
  final IconData icon;
  final String title;
  final List<Widget> body;
  const _Section(this.icon, this.title, this.body);
}

class _SectionWidget extends StatelessWidget {
  final _Section section;
  const _SectionWidget({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(section.icon, size: 17, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(section.title, style: AppTextStyles.h3)),
            ],
          ),
          const SizedBox(height: 10),
          ...section.body,
        ],
      ),
    );
  }
}

Widget _p(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub)),
    );

Widget _bullets(List<String> items) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub)),
                      Expanded(
                          child: Text(t,
                              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub))),
                    ],
                  ),
                ))
            .toList(),
      ),
    );

Widget _callout(String text, {required Color bg, required Color border, required Color fg}) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: border),
      ),
      child: Text(text, style: AppTextStyles.bodyMd.copyWith(color: fg)),
    );

final _sections = <_Section>[
  _Section(Icons.description_rounded, '1. Вступ', [
    _p(
      'Ця Політика конфіденційності пояснює, які дані обробляє застосунок '
      'MedKit («ми», «застосунок») і як саме. MedKit створений навколо одного '
      "принципу: ваші дані про здоров'я належать лише вам. Застосунок не "
      'вимагає реєстрації, не має акаунтів, і сервер MedKit спроєктований так, '
      'щоб бачити якомога менше — в ідеалі взагалі нічого, що можна прочитати.',
    ),
    _callout(
      'Це не медична консультація. MedKit — інструмент для нагадувань і '
      'організації прийому ліків, а не медичний пристрій і не заміна лікаря, '
      'фармацевта чи екстреної допомоги.',
      bg: AppColors.warningLight,
      border: AppColors.warning,
      fg: AppColors.textMain,
    ),
  ]),
  _Section(Icons.visibility_off_rounded, '2. Головний принцип: сервер «сліпий»', [
    _callout(
      "Немає акаунтів — немає що зливати. У MedKit немає реєстрації, "
      'email/пароля, входу через соцмережі. Немає центральної бази '
      "користувачів. Це свідоме архітектурне рішення: якщо немає акаунтів, "
      'немає й ризику витоку бази акаунтів.',
      bg: AppColors.primaryLight,
      border: AppColors.primary,
      fg: AppColors.primaryDark,
    ),
    _p('Там, де застосунку все ж потрібен сервер (передача даних між вашими '
        'власними пристроями, голосові команди), сервер бачить лише:'),
    _bullets([
      'Зашифровані блоки даних, ключ до яких є лише на ваших пристроях;',
      'Випадкові технічні ідентифікатори (наприклад, код пейрингу чи '
          'ідентифікатор каналу), які самі по собі нічого не означають;',
      'Push-токен пристрою — потрібен лише щоб надіслати сповіщення через '
          'Firebase Cloud Messaging.',
    ]),
    _p("Сервер ніколи не бачить: ваше ім'я, назви ліків, дозування, розклад "
        'прийому, фото, стан здоров\'я, симптоми чи будь-який інший вміст у '
        'розшифрованому вигляді.'),
  ]),
  _Section(Icons.phone_android_rounded, '3. Дані, що зберігаються лише на пристрої', [
    _p('Все, що ви вносите в MedKit — ліки, розклад прийому, члени сім\'ї, '
        'показники самопочуття, записи до лікаря, фото упаковок — зберігається '
        'тільки локально, у зашифрованій базі даних на вашому пристрої '
        '(SQLCipher, AES-256). Фото додатково шифруються окремим ключем '
        '(AES-256-GCM).'),
    _p('Ключі шифрування зберігаються в захищеному сховищі операційної '
        'системи (Keychain на iOS, Keystore на Android) і ніколи не покидають '
        'пристрій у відкритому вигляді.'),
    _p('Доступ до застосунку може бути захищений біометрією (Face ID / '
        'відбиток пальця) або кодом пристрою.'),
    _callout(
      'Наслідок: якщо ви видалите застосунок без попереднього створення '
      'резервної копії — дані буде втрачено безповоротно. У нас немає копії '
      'на сервері, яку можна відновити за вас.',
      bg: AppColors.successLight,
      border: AppColors.success,
      fg: AppColors.textMain,
    ),
  ]),
  _Section(Icons.dns_rounded, '4. Дані, що проходять через сервер', [
    _p('Пейринг пристроїв: сервер бачить хеш коду доступу (sha256) і '
        'зашифрований блок даних, видаляється за 30 хв або після першого '
        'завантаження.'),
    _p('Синхронізація оновлень (relay): push-токен і зашифрований payload, '
        'який лише пересилається — нічого не зберігається.'),
    _p('Голосові команди: текст розпізнаного мовлення — обробляється і '
        'одразу забувається, не зберігається.'),
    _p('У всіх випадках сервер не веде журналів вмісту цих запитів і не '
        'пов\'язує їх з жодною особою — прив\'язки "хто ви" в системі просто '
        'не існує.'),
  ]),
  _Section(Icons.smart_toy_rounded, '5. AI-функції та сторонні провайдери', [
    Text('Голосові команди — Anthropic (Claude)', style: AppTextStyles.labelMd),
    const SizedBox(height: 4),
    _p('Якщо ви користуєтесь голосовим введенням, текст вашої команди '
        '(наприклад, «прийняв парацетамол») надсилається на наш сервер, який '
        'пересилає його моделі Claude від Anthropic для розпізнавання дії. '
        'Перед першим використанням застосунок явно запитує вашу згоду і '
        'називає Anthropic як провайдера. Вільний текстовий опис самопочуття '
        'чи симптомів ніколи не надсилається в хмару.'),
    Text('Сканування рецептів і упаковок — Anthropic (Claude)',
        style: AppTextStyles.labelMd),
    const SizedBox(height: 4),
    _p('Фото рецепта чи упаковки ліків надсилається на наш сервер, який '
        'пересилає його моделі Claude від Anthropic для розпізнавання назв, '
        'дозування й короткої довідкової інформації. Перед першим '
        'використанням застосунок явно запитує окрему згоду. Фото '
        'використовується лише для розпізнавання й ніде не зберігається '
        'після відповіді. Довідкова інформація про їжу й побічні ефекти — '
        'орієнтовна, звірте з інструкцією до препарату.'),
  ]),
  _Section(Icons.cloud_outlined, '6. Резервні копії (Google Drive / iCloud)', [
    _p('За бажанням ви можете створити резервну копію у власному Google '
        'Drive (Android) або iCloud (iOS) — у приховану службову область, яку '
        'бачить лише застосунок.'),
    _p('Дані в копії вже зашифровані так само, як і на пристрої. Ключі '
        'шифрування додатково загортаються паролем, який ви самі '
        'придумуєте. Ні MedKit, ні Google, ні Apple не можуть прочитати '
        'вміст копії без цього пароля — і ми його ніде не зберігаємо. Якщо '
        'ви його забудете, відновити копію буде неможливо.'),
  ]),
  _Section(Icons.link_rounded, '7. Спільний доступ між пристроями (пейринг)', [
    _p('Щоб поділитися розкладом з іншим пристроєм, пристрої обмінюються '
        'одноразовим кодом. Дані шифруються ключем, похідним від цього коду, '
        'і розшифровуються лише на другому пристрої після введення того '
        'самого коду. Сервер лише зберігає зашифрований блок протягом '
        'короткого часу — прочитати його без коду неможливо.'),
  ]),
  _Section(Icons.family_restroom_rounded, '8. Залежні профілі та діти', [
    _p('MedKit дозволяє додавати профілі членів сім\'ї (наприклад, дітей чи '
        'батьків похилого віку), якими керує власник пристрою. Це не окремі '
        'акаунти — залежні профілі не мають власного входу чи прямого '
        'доступу до застосунку, якщо власник профілю сам їх не налаштує.'),
    _p('Відповідальність за точність і доречність даних, внесених у профіль '
        'дитини чи іншого залежного члена сім\'ї, несе дорослий, який керує '
        'застосунком.'),
  ]),
  _Section(Icons.balance_rounded, '9. Ваші права', [
    _p('Оскільки основний масив ваших даних живе лише на вашому пристрої, '
        'більшість прав (доступ, виправлення, видалення) реалізуються '
        'безпосередньо в застосунку — ви редагуєте чи видаляєте записи '
        'напряму, без запиту до нас.'),
    _bullets([
      'Видалення всіх даних: видалення застосунку з пристрою (і, за '
          'наявності, резервної копії з Drive/iCloud вручну) видаляє всі '
          'ваші дані повністю.',
      'Дані на сервері: тимчасові технічні дані (пейринг-блоки, '
          'push-токени) можна видалити за запитом на нашу пошту — хоча '
          'більшість з них і так автоматично зникають протягом хвилин чи '
          'годин.',
      'Копія власних даних у читабельному форматі — розділ "Експорт '
          'даних" у профілі.',
    ]),
  ]),
  _Section(Icons.shield_rounded, '10. Безпека', [
    _bullets([
      'Локальна база даних зашифрована (SQLCipher, AES-256)',
      'Фото зашифровані окремим ключем (AES-256-GCM, унікальний nonce на '
          'кожен файл)',
      'Опційний біометричний захист входу в застосунок',
      'Увесь обмін даними з сервером — лише через HTTPS/TLS',
      'Rate-limiting на сервері проти зловживань і перебору кодів',
    ]),
  ]),
  _Section(Icons.edit_note_rounded, '11. Зміни до цієї Політики', [
    _p('Ми можемо оновлювати цю Політику з часом — наприклад, при додаванні '
        'нових функцій. Про суттєві зміни ми повідомимо в застосунку. Дата '
        'останнього оновлення завжди вказана на початку документа.'),
  ]),
  _Section(Icons.mail_outline_rounded, '12. Контакти', [
    _p('Питання щодо цієї Політики — на privacy@elly-medkit.com.'),
  ]),
];
