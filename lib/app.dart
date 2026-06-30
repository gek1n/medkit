import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_dimensions.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/l10n_ext.dart';
import 'features/family/family_screen.dart';
import 'features/meds/meds_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/today/today_screen.dart';

class MedKitApp extends StatefulWidget {
  const MedKitApp({super.key});

  @override
  State<MedKitApp> createState() => _MedKitAppState();
}

class _MedKitAppState extends State<MedKitApp> {
  Locale _locale = const Locale('uk');

  void _changeLocale(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedKit',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MainShell(
        locale: _locale,
        onLocaleChanged: _changeLocale,
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  const MainShell({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _handleFab() {
    // FAB открывает AddMedSheet напрямую с любой вкладки
    setState(() => _currentIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const TodayScreen(),
      const MedsScreen(),
      // index 2 — FAB (не экран)
      const FamilyScreen(),
      ProfileScreen(
        currentLocale: widget.locale,
        onLocaleChanged: widget.onLocaleChanged,
      ),
    ];

    // Маппинг вкладок навигации → индекс в screens[]
    // nav: 0→today, 1→meds, 2→fab, 3→family, 4→profile
    final screenIndex = switch (_currentIndex) {
      0 => 0,
      1 => 1,
      3 => 2,
      4 => 3,
      _ => 0,
    };

    return Scaffold(
      body: IndexedStack(
        index: screenIndex,
        children: screens,
      ),
      floatingActionButton: _CenterFab(onTap: _handleFab),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 2) {
            _handleFab();
          } else {
            setState(() => _currentIndex = i);
          }
        },
      ),
    );
  }
}

class _CenterFab extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppDimensions.fabSize,
        height: AppDimensions.fabSize,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9B6DE8), AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomBar(
      {required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: AppDimensions.navHeight,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.today_outlined,
                activeIcon: Icons.today,
                label: context.l10n.navToday,
                index: 0,
                current: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.medication_outlined,
                activeIcon: Icons.medication,
                label: context.l10n.navMeds,
                index: 1,
                current: currentIndex,
                onTap: onTap,
              ),
              // FAB gap
              const Expanded(child: SizedBox()),
              _NavItem(
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: context.l10n.navFamily,
                index: 3,
                current: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: context.l10n.navProfile,
                index: 4,
                current: currentIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
