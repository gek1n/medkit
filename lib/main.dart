import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/l10n_ext.dart';
import 'features/add/add_type_sheet.dart';
import 'features/family/family_screen.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/today/today_screen.dart';
import 'features/today/providers/today_providers.dart';
import 'features/profile/profile_screen.dart';
import 'shared/widgets/app_bottom_nav.dart';

void main() {
  runZonedGuarded(
    () => runApp(const ProviderScope(child: MedKitApp())),
    (error, stack) => debugPrint('🔴 MEDKIT CRASH: $error\n$stack'),
  );
}

class MedKitApp extends StatelessWidget {
  const MedKitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedKit',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('uk'), Locale('en')],
      locale: const Locale('uk'),
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends ConsumerWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentMemberProvider);

    return memberAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const OnboardingScreen(),
      data: (member) =>
          member == null ? const OnboardingScreen() : const _Shell(),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 2;

  static const _screens = [
    SizedBox.shrink(), // 0 = Додати — handled by bottom nav
    ScheduleScreen(),  // 1 = Розклад
    TodayScreen(),     // 2 = Сьогодні (center)
    FamilyScreen(),    // 3 = Сім'я
    ProfileScreen(),   // 4 = Профіль
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) {
          if (i == 0) {
            showAddTypeSheet(context);
          } else {
            setState(() => _index = i);
          }
        },
      ),
    );
  }
}
