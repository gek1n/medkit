import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart' as sqlite3_open;
import 'core/providers/app_language_provider.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/font_scale_provider.dart';
import 'core/providers/plan_provider.dart';
import 'core/providers/real_plan_provider.dart';
import 'core/services/account_service.dart';
import 'core/services/affiliate_config_service.dart';
import 'core/services/app_lock_service.dart';
import 'core/services/app_logger.dart';
import 'core/services/backup_reminder_service.dart';
import 'core/services/backup_service.dart';
import 'core/services/backup_settings_service.dart';
import 'core/services/db_encryption_service.dart';
import 'core/services/billing_lifecycle_service.dart';
import 'core/services/family_group_service.dart';
import 'core/services/family_peer_sync_service.dart';
import 'core/services/family_sync_service.dart';
import 'core/services/marketing_topics_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/review_prompt_service.dart';
import 'core/services/subscription_service.dart';
import 'core/services/sync_service.dart';
import 'data/repositories/family_peers_repository.dart';
import 'data/repositories/members_repository.dart';
import 'features/plans/billing_lifecycle_dialogs.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/l10n_ext.dart';
import 'features/family/family_screen.dart';
import 'features/lock/app_lock_screen.dart';
import 'features/medcard/med_card_screen.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/today/today_screen.dart';
import 'features/today/providers/today_providers.dart';
import 'features/profile/profile_screen.dart';
import 'shared/widgets/app_bottom_nav.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      AppLogger.log('app_start');
      // FlutterError.onError ловить помилки під час build/layout/paint
      // (напр. кинуте виключення всередині widget.build) — вони НЕ
      // проходять через runZonedGuarded, бо Flutter обробляє їх сам.
      FlutterError.onError = (details) {
        AppLogger.logError('FlutterError', details.exception, details.stack);
        FlutterError.presentError(details);
      };
      // sqlite3 за замовчуванням шукає звичайний libsqlite3.so на Android —
      // це вказує йому натомість вантажити SQLCipher-збірку з
      // sqlcipher_flutter_libs. Без цього PRAGMA key ніхто не побачить.
      if (Platform.isAndroid) {
        sqlite3_open.open.overrideFor(
            sqlite3_open.OperatingSystem.android, openCipherOnAndroid);
      }
      try {
        // Потрібен лише для FCM push-пробудження (relay-канал сам по собі —
        // звичайний HTTP до власного бекенду, від Firebase не залежить).
        // Поки google-services.json/GoogleService-Info.plist не додані в
        // нативні проєкти, це кине виняток, який тут навмисно не фатальний.
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint('🔶 Firebase не налаштований: $e');
      }
      await NotificationService.init();
      // Fire-and-forget: не блокує запуск, а кнопка "Купити" сама
      // з'явиться (AffiliateConfigService.revision) щойно конфіг підвантажиться.
      unawaited(AffiliateConfigService.warmUp());
      runApp(const ProviderScope(child: MedKitApp()));
    },
    (error, stack) => AppLogger.logError('Zone', error, stack),
  );
}

class MedKitApp extends ConsumerWidget {
  const MedKitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbFontSize = ref.watch(effectiveFontSizeProvider); // 1..4, default 2=normal
    final scale = fontScaleValues[
        (dbFontSize - 1).clamp(0, fontScaleValues.length - 1)];
    final languageId = ref.watch(appLanguageProvider);
    final languageCode = languageId.split('_').first;
    // 'ru' ще не має власного ARB-файлу (лише uk/en перекладено) — доки
    // перекладів більше немає, показуємо українську як безпечний фолбек.
    final appLocale = const ['uk', 'en'].contains(languageCode)
        ? Locale(languageCode)
        : const Locale('uk');

    return MaterialApp(
      title: 'Elly',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('uk'), Locale('en')],
      locale: appLocale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const _AppLockGate(),
    );
  }
}

class _AppLockGate extends StatefulWidget {
  const _AppLockGate();

  @override
  State<_AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<_AppLockGate> {
  bool? _unlocked; // null = ще триває перша перевірка при старті

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  Future<void> _checkLock() async {
    final enabled = await AppLockService.isEnabled();
    if (!enabled) {
      if (mounted) setState(() => _unlocked = true);
      return;
    }
    // authenticate() сама повертає true, якщо на пристрої взагалі не
    // налаштовано жодного способу автентифікації — див. AppLockService.
    final ok = await AppLockService.authenticate();
    if (!mounted) return;
    setState(() => _unlocked = ok);
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked == null) {
      return const _LoadingScreen();
    }
    if (_unlocked == false) {
      return AppLockScreen(onUnlocked: () => setState(() => _unlocked = true));
    }
    return const _RootRouter();
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            Text(context.l10n.loadingEllipsisLabel, style: AppTextStyles.labelLg),
          ],
        ),
      ),
    );
  }
}

class _RootRouter extends ConsumerWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Гейтимо на самовідновлення ролі owner ДО першого читання
    // currentMemberProvider — інакше на пошкоджених даних (жоден профіль не
    // позначений owner) встигає промайнути кадр зі старим/неправильним
    // станом. Сама перевірка — один SELECT, у нормальному випадку instant.
    final repairAsync = ref.watch(ensureOwnerRoleProvider);
    if (repairAsync.isLoading) return const _LoadingScreen();

    final memberAsync = ref.watch(currentMemberProvider);

    return memberAsync.when(
      loading: () => const _LoadingScreen(),
      // НІКОЛИ не показувати онбординг при помилці читання БД — дані
      // фізично на диску, просто зараз не читаються (напр. розсинхрон
      // ключа шифрування). Раніше тут стояло `=> const OnboardingScreen()`,
      // що ховало будь-яку помилку і виглядало як "акаунт зник" — юзер
      // проходив онбординг заново, хоча дані нікуди не ділись.
      error: (e, st) {
        // Раніше ця помилка була взагалі не видна нікому (мовчки йшли на
        // онбординг) — тепер пишемо в AppLogger (файл на диску, доступний
        // через "Журнал подій" у профілі) замість лише debugPrint.
        AppLogger.logError('currentMemberProvider', e, st);
        return _DatabaseErrorScreen(error: e, stackTrace: st);
      },
      data: (member) =>
          member == null ? const OnboardingScreen() : const _Shell(),
    );
  }
}

class _DatabaseErrorScreen extends ConsumerStatefulWidget {
  final Object error;
  final StackTrace? stackTrace;
  const _DatabaseErrorScreen({required this.error, this.stackTrace});

  @override
  ConsumerState<_DatabaseErrorScreen> createState() =>
      _DatabaseErrorScreenState();
}

class _DatabaseErrorScreenState extends ConsumerState<_DatabaseErrorScreen>
    with WidgetsBindingObserver {
  bool _showDetails = false;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // iOS: Keychain стає знову доступним одразу після розблокування —
  // на відміну від _isKeyMismatch (де retry принципово безглуздий), тут
  // повторна спроба після кожного resume майже напевно спрацює сама, без
  // натискання кнопки користувачем.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isDeviceLocked) {
      ref.invalidate(databaseProvider);
      ref.invalidate(currentMemberProvider);
    }
  }
  // Кількість разів, коли ця помилка повторилась ПІСЛЯ явного "Спробувати
  // ще раз" — 0 при першій появі екрана. Деструктивний "Скинути" не можна
  // пропонувати одразу: помилка може бути транзитною (напр. тимчасовий
  // лок файлу після відновлення бекапу, повільний диск), і без цього
  // порогу користувач міг би втратити всі дані через звичайний глюк
  // з'єднання замість того, щоб просто спробувати ще раз.
  //
  // Поріг навмисно піднято з 1 до 3: реальні звіти користувачів (і логи)
  // показують, що цей конкретний код 26 після оновлення/сну пристрою
  // майже завжди минає сам — але НЕ від "Спробувати ще раз" у тому ж
  // процесі (ретрай лише перечитує той самий застиглий Keychain-стан), а
  // ЛИШЕ від повного закриття й повторного відкриття застосунку. Занизький
  // поріг тут уже призводив би до пропозиції видалити реальні дані там, де
  // проблема через кілька секунд минула б сама після релончу.
  int _retryCount = 0;

  @override
  void didUpdateWidget(_DatabaseErrorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _retryCount++;
  }

  String get _detailsText =>
      '${widget.error}\n\n${widget.stackTrace ?? ''}';

  // SQLITE_NOTADB (code 26): PRAGMA key встановлено, але перший реальний
  // read падає — означає, що ключ у Keychain не той, яким зашифровано файл
  // на диску (типово після Delete App + перевстановлення). "Спробувати ще
  // раз" тут ніколи не допоможе: без правильного ключа розшифрувати дані
  // криптографічно неможливо, тож для цього конкретного випадку показуємо
  // окрему, явно деструктивну дію.
  //
  // NativeDatabase.createInBackground працює через ізолят — Drift
  // серіалізує помилку в рядок ще на боці фонового ізоляту (bool `_serialize`
  // у DriftCommunication), тож на момент, коли вона долітає сюди, це вже НЕ
  // `SqliteException`, а обгортка `DriftRemoteException` над самим лише
  // текстом. Перевіряти доводиться за текстом, `is SqliteException` тут
  // завжди буде false.
  bool get _isKeyMismatch =>
      widget.error.toString().contains('(code 26)') ||
      widget.error.toString().contains('file is not a database');

  // iOS: пристрій не розблоковували з моменту перезавантаження, тому
  // Keychain-ключ фізично на місці, але зараз недосяжний
  // (DbTemporarilyLockedException, db_encryption_service.dart) — на
  // відміну від _isKeyMismatch, деструктивний скид тут НЕ пропонується
  // ніколи, лише прохання розблокувати пристрій. Кидається до перетину
  // ізолятної межі (див. коментар вище про DriftRemoteException), тож тип
  // тут завжди справжній, без string-matching.
  bool get _isDeviceLocked => widget.error is DbTemporarilyLockedException;

  Future<void> _resetLocalDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.resetLocalDbConfirmTitle),
        content: Text(ctx.l10n.resetLocalDbConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(ctx.l10n.resetAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _resetting = true);
    AppLogger.log('db_reset_after_key_mismatch');
    final file = await DbEncryptionService.databaseFile();
    await DbEncryptionService.resetCorruptedDatabase(file);
    if (!mounted) return;
    ref.invalidate(databaseProvider);
    ref.invalidate(currentMemberProvider);
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeviceLocked) return _buildLockedScreen(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(context.l10n.dbLoadErrorTitle, style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(
                context.l10n.dbLoadErrorBody,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
              ),
              // Для code-26 випадку кнопка "Спробувати ще раз" нижче лише
              // перечитує той самий застиглий стан у ТОМУ Ж процесі — за
              // спостереженнями (логи користувачів) вона тут майже ніколи
              // не допомагає. Реально вирішує лише повне закриття
              // застосунку (не згортання) і повторний запуск — новий
              // процес отримує свіже, коректне значення з Keychain. Тому
              // ця інструкція — головна порада, а не кнопка retry.
              if (_isKeyMismatch) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.dbErrorTryThisFirstLabel,
                              style: AppTextStyles.labelMd
                                  .copyWith(color: AppColors.primaryDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.dbErrorCloseReopenHint,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(databaseProvider);
                  ref.invalidate(currentMemberProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(context.l10n.tryAgainButtonAction),
              ),
              if (_isKeyMismatch && _retryCount < 3) ...[
                const SizedBox(height: 8),
                Text(
                  context.l10n.dbErrorMoreActionHint,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                ),
              ],
              if (_isKeyMismatch && _retryCount >= 3) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _resetting ? null : _resetLocalDatabase,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _resetting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.resetLocalDbAction),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _showDetails = !_showDetails),
                child: Text(_showDetails
                    ? context.l10n.hideDetailsAction
                    : context.l10n.showErrorDetailsAction),
              ),
              if (_showDetails) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _detailsText,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSub,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _detailsText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.copiedToClipboardSnackbar)),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(context.l10n.copyErrorTextAction),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Окремий, свідомо не тривожний екран — на відміну від загального
  // _DatabaseErrorScreen.build() вище тут НІКОЛИ немає деструктивної дії
  // (нема чого "скидати" — ключ шифрування цілий, просто зараз недосяжний),
  // і didChangeAppLifecycleState вище сам перезапустить читання БД щойно
  // застосунок повернеться на передній план — кнопка нижче лише про всяк
  // випадок, якщо автоматичне оновлення чомусь не спрацювало.
  Widget _buildLockedScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    size: 34, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(context.l10n.unlockPhoneTitle, style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(
                context.l10n.unlockPhoneBody,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LockedStep(
                      number: '1',
                      text: context.l10n.unlockStep1,
                    ),
                    const SizedBox(height: 10),
                    _LockedStep(
                      number: '2',
                      text: context.l10n.unlockStep2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  ref.invalidate(databaseProvider);
                  ref.invalidate(currentMemberProvider);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(context.l10n.checkAgainAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedStep extends StatelessWidget {
  final String number;
  final String text;
  const _LockedStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: AppTextStyles.labelSm.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: AppTextStyles.bodySm.copyWith(color: AppColors.textMain)),
        ),
      ],
    );
  }
}

class _Shell extends ConsumerStatefulWidget {
  const _Shell();

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> with WidgetsBindingObserver {
  int _index = 0;
  late final PageController _pageController;
  bool _syncing = false;
  bool _familySyncing = false;
  bool _billingSyncing = false;
  bool _backingUp = false;
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  static const _screens = [
    TodayScreen(),     // 0 = Сьогодні
    ScheduleScreen(),  // 1 = Розклад
    MedCardScreen(),   // 2 = Медкартка
    FamilyScreen(),    // 3 = Сім'я
    ProfileScreen(),   // 4 = Профіль
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
    WidgetsBinding.instance.addObserver(this);
    // Похідний кеш "чужих" даних, поділених пірами (SharedSubjects/
    // SharedEntities) — чистимо ПЕРЕД першим синком на холодному старті,
    // щоб застаріла версія (напр. з відновленого бекапу) не пережила
    // відновлення; наступний вдалий syncAllPeers() наповнить його заново
    // вже актуальними даними.
    unawaited(FamilyPeersRepository(ref.read(databaseProvider)).clearSharedCache());
    _syncIfEnabled();
    _familySyncIfNeeded();
    _billingSyncIfNeeded();
    _backupIfDue();
    unawaited(MarketingTopicsService.syncCoreTopics(ref.read(databaseProvider)));
    unawaited(ReviewPromptService.recordInstallIfNeeded());
    unawaited(ReviewPromptService.maybeShow());
    unawaited(BackupReminderService.recordInstallIfNeeded());
    unawaited(BackupReminderService.maybeRemind());
    unawaited(NotificationService.logDiagnostics());
    // "Розбуди" push від family_sync (relay/send) приходить як data-message —
    // поки застосунок відкритий, його треба явно підхопити тут; коли
    // застосунок згорнутий/закритий, той самий ефект дає resume-хук нижче.
    try {
      _fcmSubscription = FirebaseMessaging.onMessage.listen((_) => _familySyncIfNeeded());
    } catch (_) {
      // Firebase не налаштований на цьому білді — не критично.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fcmSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncIfEnabled();
      _familySyncIfNeeded();
      _billingSyncIfNeeded();
      _backupIfDue();
      unawaited(MarketingTopicsService.syncCoreTopics(ref.read(databaseProvider)));
      unawaited(ReviewPromptService.maybeShow());
      unawaited(BackupReminderService.maybeRemind());
      unawaited(NotificationService.logDiagnostics());
    }
  }

  /// Тихо синхронізує в фоні, якщо режим не "тільки локально". Помилки
  /// (немає інтернету, сервер недоступний тощо) навмисно проковтуються —
  /// локальні дані завжди лишаються джерелом правди, невдала синхронізація
  /// просто спробує ще раз наступного разу.
  Future<void> _syncIfEnabled() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final mode = await AccountService().currentMode();
      if (mode != SyncMode.local) {
        await SyncService(ref.read(databaseProvider)).pushChanges();
        await SyncService(ref.read(databaseProvider)).pullChanges();
      }
    } catch (_) {
      // Тиха невдача — див. коментар вище.
    } finally {
      _syncing = false;
    }
  }

  /// family_sync — незалежно від режиму account-sync вище: працює для будь-
  /// якого профілю, привʼязаного до каналу пейрингу (SharedChannels), навіть
  /// якщо облікова синхронізація взагалі вимкнена.
  Future<void> _familySyncIfNeeded() async {
    if (_familySyncing) return;
    _familySyncing = true;
    try {
      final db = ref.read(databaseProvider);
      await FamilySyncService(db).syncAll();
      // Легкий обмін візитівками сімейної групи — той самий тригер, що й
      // family_sync вище, але не залежить від нього (працює навіть якщо
      // жодного каналу-дзеркала профілю ще немає).
      await FamilyGroupService(db).refreshPeers();
      // Реальні дані (ліки, медкартка) до/від пірів, відфільтровані через
      // FamilyVisibilityService — Фаза 4.
      await FamilyPeerSyncService(db).syncAllPeers();
    } catch (_) {
      // Тиха невдача — див. коментар до _syncIfEnabled.
    } finally {
      _familySyncing = false;
    }
  }

  /// Той самий resume/cold-start тригер, що й family-синк вище — оновлює
  /// кеш статусу підписки (SubscriptionService), перераховує realPlanProvider
  /// (той пише в planProvider через ref.listen у build(), див. нижче), і
  /// перевіряє грейс-період/розпад ВЛАСНОЇ сім'ї (BillingLifecycleService).
  /// No-op, якщо синк вимкнено — SubscriptionService.refreshFromServer сам
  /// про це подбає.
  Future<void> _billingSyncIfNeeded() async {
    if (_billingSyncing) return;
    _billingSyncing = true;
    try {
      await SubscriptionService.refreshFromServer();
      ref.invalidate(realPlanProvider);

      final result = await BillingLifecycleService.checkGraceAndMaybeDisband(ref.read(databaseProvider));
      if (!mounted) return;
      switch (result) {
        case GraceCheckResult.graceStarted:
        case GraceCheckResult.graceOngoing:
          final timeLeft = await BillingLifecycleService.timeLeftInGrace();
          if (mounted) {
            unawaited(showGracePeriodPopup(context, timeLeft: timeLeft));
          }
        case GraceCheckResult.disbanded:
          if (mounted) {
            unawaited(showAccessChangedModal(
              context,
              reason: context.l10n.familyDisbandedReason,
            ));
          }
        case GraceCheckResult.none:
          break;
      }
    } catch (_) {
      // Тиха невдача — див. коментар до _syncIfEnabled.
    } finally {
      _billingSyncing = false;
    }
  }

  /// Автоматичний бекап за розкладом (розділ "Резервна копія" в Профілі) —
  /// той самий resume/cold-start тригер, що й усе вище. Flutter не має
  /// надійного background scheduler без нативних плагінів (WorkManager/
  /// BGTaskScheduler), тож замість цього перевіряємо на кожному відкритті
  /// застосунку: чи минуло достатньо часу з останнього бекапу за обраною
  /// частотою — і якщо так, тихо робимо новий, паролем, збереженим на цьому
  /// пристрої при першому вмиканні хмарного режиму. No-op у режимі "тільки
  /// на пристрої" чи якщо пароль ще не було задано.
  Future<void> _backupIfDue() async {
    if (_backingUp) return;
    _backingUp = true;
    try {
      if (!await BackupSettingsService.isDue()) return;
      final passphrase = await BackupSettingsService.savedPassphrase();
      if (passphrase == null) return;

      final mode = await BackupSettingsService.currentMode();
      final target = switch (mode) {
        BackupMode.googleDrive => BackupTarget.googleDrive,
        BackupMode.iCloud => BackupTarget.iCloud,
        BackupMode.local => null,
      };
      if (target == null) return;

      await BackupService().createBackup(target: target, passphrase: passphrase);
      await BackupSettingsService.markBackedUpNow();
    } catch (_) {
      // Тиха невдача — див. коментар до _syncIfEnabled. Спробуємо знову на
      // наступному resume.
    } finally {
      _backingUp = false;
    }
  }

  void _goToTab(int i) {
    setState(() => _index = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(requestedTabIndexProvider, (previous, next) {
      if (next != null) {
        _goToTab(next);
        Future.microtask(
            () => ref.read(requestedTabIndexProvider.notifier).state = null);
      }
    });
    // Міст: planProvider лишається тим самим bare StateProvider, яким
    // користується весь інший код застосунку, — але тепер його значення
    // веде реальний (сервер+сім'я-обізнаний) realPlanProvider, а не лише
    // ручні тапи в PlansScreen. docs/multifamily_billing_plan.md, "Тестовий
    // режим біллінгу".
    ref.listen<AsyncValue<AppPlan>>(realPlanProvider, (previous, next) {
      final plan = next.valueOrNull;
      if (plan != null) {
        ref.read(planProvider.notifier).state = plan;
      }
    });
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _index = i),
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: _goToTab,
      ),
    );
  }
}
