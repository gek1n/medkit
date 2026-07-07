import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../data/db/app_database.dart';
import '../../core/services/prescription_scan_service.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../../data/repositories/wellbeing_repository.dart';
import '../scan/prescription_scan_screen.dart';
import '../today/providers/today_providers.dart';

TimeOfDay _onboardingDefaultTime(String s) => switch (s) {
      'morning' => const TimeOfDay(hour: 8, minute: 0),
      'afternoon' => const TimeOfDay(hour: 13, minute: 0),
      'evening' => const TimeOfDay(hour: 19, minute: 0),
      'night' => const TimeOfDay(hour: 22, minute: 0),
      _ => const TimeOfDay(hour: 8, minute: 0),
    };

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  static const _totalSteps = 6;

  // Step 1: кого настраиваем
  final Set<String> _selectedRoles = {'self'};

  // Step 2: имя + аватар + члены семьи
  final _nameController = TextEditingController();
  int _avatarIndex = 0;
  final List<_FamilyMemberDraft> _familyDrafts = [];

  // Step 3: ліки (скан)
  final List<ScannedMedication> _scannedMedDrafts = [];

  // Step 5: activity/wellbeing toggles
  bool _walkEnabled = true;
  bool _wellbeingEnabled = true;

  bool _isSaving = false;

  Future<void> _openScanFromOnboarding() async {
    final results = await Navigator.push<List<ScannedMedication>>(
      context,
      MaterialPageRoute(builder: (_) => const PrescriptionScanScreen()),
    );
    if (results != null && results.isNotEmpty && mounted) {
      setState(() => _scannedMedDrafts.addAll(results));
    }
    _next();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final d in _familyDrafts) {
      d.controller.dispose();
    }
    super.dispose();
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  void _next() {
    if (_step == 1 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введіть своє ім\'я')),
      );
      return;
    }
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _skip() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    // Captured before any await: as soon as the owner member is inserted below,
    // currentMemberProvider flips non-null and _RootRouter swaps this screen out,
    // disposing this State. A ProviderContainer outlives that disposal, unlike `ref`.
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final repo = container.read(membersRepositoryProvider);
      final name = _nameController.text.trim().isEmpty
          ? 'Я'
          : _nameController.text.trim();

      final ownerId = await repo.insert(MembersCompanion.insert(
        name: name,
        avatarIndex: Value(_avatarIndex),
        role: const Value('owner'),
      ));

      for (final draft in _familyDrafts) {
        final draftName = draft.controller.text.trim();
        if (draftName.isNotEmpty) {
          await repo.insert(MembersCompanion.insert(
            name: draftName,
            avatarIndex: Value(draft.avatarIndex),
            role: const Value('member'),
          ));
        }
      }

      if (_scannedMedDrafts.isNotEmpty) {
        final medRepo = container.read(medicationsRepositoryProvider);
        final medsNow = DateTime.now();
        for (final m in _scannedMedDrafts) {
          final times = (m.scheduleTimes ?? const ['morning'])
              .map((s) =>
                  '${_onboardingDefaultTime(s).hour.toString().padLeft(2, '0')}:${_onboardingDefaultTime(s).minute.toString().padLeft(2, '0')}')
              .toList();
          final phasesJson = jsonEncode([
            {'times': times, 'durationDays': 7, 'doseAmount': m.doseAmount ?? 1.0},
          ]);
          await medRepo.insert(MedicationsCompanion.insert(
            memberId: ownerId,
            name: m.name,
            form: const Value('tablet'),
            doseAmount: m.doseAmount ?? 1.0,
            doseUnit: Value(m.doseUnit ?? 'табл.'),
            foodRelation: Value(m.foodRelation ?? 'after'),
            repeatType: const Value('daily'),
            repeatConfig: const Value('{}'),
            startDate: medsNow,
            endDate: Value(DateTime(medsNow.year, medsNow.month, medsNow.day).add(const Duration(days: 7))),
            phases: Value(phasesJson),
          ));
        }
        container.invalidate(generateTodayIntakesProvider);
        container.invalidate(tomorrowIntakesProvider);
      }

      if (_walkEnabled) {
        final activitiesRepo = container.read(activitiesRepositoryProvider);
        final activityId = await activitiesRepo.insertActivity(
          ActivitiesCompanion.insert(
            memberId: ownerId,
            name: 'Прогулянка',
            type: const Value('walk'),
            durationMin: const Value(30),
            repeatDays: Value(jsonEncode(const [1, 2, 3, 4, 5, 6, 7])),
          ),
        );
        await activitiesRepo.insertSlots([
          ActivitySlotsCompanion.insert(
            activityId: activityId,
            timeOfDay: '08:30',
            durationMin: const Value(30),
            sortOrder: const Value(0),
          ),
        ]);
        container.invalidate(generateTodayActivityLogsProvider);
        container.invalidate(tomorrowActivityLogsProvider);
      }

      if (_wellbeingEnabled) {
        final wellbeingRepo = container.read(wellbeingRepositoryProvider);
        await wellbeingRepo.upsertSchedule(
          WellbeingSchedulesCompanion.insert(
            memberId: ownerId,
            timesPerDay: const Value(3),
            times: Value(jsonEncode(const ['08:00', '14:00', '20:00'])),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('🔴 Onboarding _finish() error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка при завершенні: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(step: _step, total: _totalSteps, onBack: _step > 0 ? _back : null),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildStep(_step),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int step) {
    return switch (step) {
      0 => _StepWho(
          key: const ValueKey(0),
          selectedRoles: _selectedRoles,
          onToggle: (role) => setState(() {
            if (role == 'self') return;
            if (_selectedRoles.contains(role)) {
              _selectedRoles.remove(role);
            } else {
              _selectedRoles.add(role);
            }
          }),
          onNext: _next,
          onSkip: _skip,
        ),
      1 => _StepName(
          key: const ValueKey(1),
          nameController: _nameController,
          avatarIndex: _avatarIndex,
          familyDrafts: _familyDrafts,
          selectedRoles: _selectedRoles,
          onAvatarChange: (i) => setState(() => _avatarIndex = i),
          onFamilyAdd: () => setState(() => _familyDrafts.add(_FamilyMemberDraft())),
          onFamilyAvatarChange: (idx, av) => setState(() => _familyDrafts[idx].avatarIndex = av),
          onFamilyRemove: (idx) => setState(() {
            _familyDrafts[idx].controller.dispose();
            _familyDrafts.removeAt(idx);
          }),
          onNext: _next,
        ),
      2 => _StepMedications(
          key: const ValueKey(2),
          onNext: _next,
          onSkip: _skip,
          onScan: _openScanFromOnboarding,
        ),
      3 => _StepSchedule(
          key: const ValueKey(3),
          onNext: _next,
        ),
      4 => _StepActivities(
          key: const ValueKey(4),
          walkEnabled: _walkEnabled,
          wellbeingEnabled: _wellbeingEnabled,
          onWalkToggle: (v) => setState(() => _walkEnabled = v),
          onWellbeingToggle: (v) => setState(() => _wellbeingEnabled = v),
          onNext: _next,
        ),
      _ => _StepDone(
          key: const ValueKey(5),
          isSaving: _isSaving,
          onFinish: _finish,
        ),
    };
  }
}

// ─── Progress bar ────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int step;
  final int total;
  final VoidCallback? onBack;
  const _ProgressBar({required this.step, required this.total, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              if (onBack != null) ...[
                GestureDetector(
                  onTap: onBack,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textMuted),
                  ),
                ),
              ] else
                const SizedBox(width: 28),
              ...List.generate(total, (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i <= step ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Крок ${step + 1} з $total',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1: Кого настраиваем ────────────────────────────────────────────────

class _StepWho extends StatelessWidget {
  final Set<String> selectedRoles;
  final void Function(String) onToggle;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _StepWho({
    super.key,
    required this.selectedRoles,
    required this.onToggle,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
              ),
              child: const Center(child: Icon(Icons.groups_rounded, size: 44, color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Швидке налаштування',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Кого налаштовуємо?', style: AppTextStyles.h2),
          const SizedBox(height: 6),
          Text(
            'Виберіть всіх одразу — налаштуємо за один раз',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 24),
          _Option(
            icon: Icons.person_rounded,
            title: 'Себе',
            sub: 'Мої ліки та розклад',
            selected: true,
            locked: true,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _Option(
            icon: Icons.elderly_rounded,
            title: 'Маму / Тата',
            sub: 'Стежитиму, вони отримають нагадування',
            selected: selectedRoles.contains('parent'),
            onTap: () => onToggle('parent'),
          ),
          const SizedBox(height: 10),
          _Option(
            icon: Icons.child_care_rounded,
            title: 'Дитину',
            sub: 'Дитячі ліки та активність',
            selected: selectedRoles.contains('child'),
            onTap: () => onToggle('child'),
          ),
          const SizedBox(height: 10),
          _Option(
            icon: Icons.favorite_rounded,
            title: 'Партнера',
            sub: 'Бачимо статуси один одного',
            selected: selectedRoles.contains('partner'),
            onTap: () => onToggle('partner'),
          ),
          const SizedBox(height: 32),
          _NextButton(label: 'Далі →', onTap: onNext),
          const SizedBox(height: 12),
          _SkipLink(label: 'Пропустити — налаштую пізніше', onTap: onSkip),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.title,
    required this.sub,
    required this.selected,
    this.locked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLg),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textSub)),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2: Ім'я + аватар + родственники ───────────────────────────────────

class _FamilyMemberDraft {
  final TextEditingController controller = TextEditingController();
  int avatarIndex = 1;
}

class _StepName extends StatelessWidget {
  final TextEditingController nameController;
  final int avatarIndex;
  final List<_FamilyMemberDraft> familyDrafts;
  final Set<String> selectedRoles;
  final void Function(int) onAvatarChange;
  final VoidCallback onFamilyAdd;
  final void Function(int, int) onFamilyAvatarChange;
  final void Function(int) onFamilyRemove;
  final VoidCallback onNext;

  const _StepName({
    super.key,
    required this.nameController,
    required this.avatarIndex,
    required this.familyDrafts,
    required this.selectedRoles,
    required this.onAvatarChange,
    required this.onFamilyAdd,
    required this.onFamilyAvatarChange,
    required this.onFamilyRemove,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Додайте учасників', style: AppTextStyles.h2),
          const SizedBox(height: 6),
          Text(
            'Вкажіть ім\'я та оберіть аватар',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 24),

          // Owner card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showAvatarPicker(context, avatarIndex, onAvatarChange),
                      child: AvatarImage(index: avatarIndex, size: 52),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Я (власник)',
                              style: AppTextStyles.labelMd
                                  .copyWith(color: AppColors.primary)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: 'Ваше ім\'я',
                              hintStyle: AppTextStyles.bodyMd
                                  .copyWith(color: AppColors.textMuted),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: AppTextStyles.bodyMd
                                .copyWith(color: AppColors.textMain),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Family drafts
          for (int i = 0; i < familyDrafts.length; i++) ...[
            _FamilyMemberCard(
              draft: familyDrafts[i],
              onAvatarTap: () => _showAvatarPicker(
                  context, familyDrafts[i].avatarIndex,
                  (av) => onFamilyAvatarChange(i, av)),
              onRemove: () => onFamilyRemove(i),
            ),
            const SizedBox(height: 10),
          ],

          // Add more
          if (selectedRoles.length > 1 || familyDrafts.isNotEmpty)
            GestureDetector(
              onTap: onFamilyAdd,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.border, width: 2,
                      style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('＋', style: TextStyle(fontSize: 18, color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Text('Додати учасника',
                        style: AppTextStyles.bodyMd
                            .copyWith(color: AppColors.textMuted,
                                fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 32),
          _NextButton(label: 'Далі — ліки →', onTap: onNext),
        ],
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, int current, void Function(int) onSelect) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Оберіть аватар', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(avatarCount, (i) => GestureDetector(
                    onTap: () {
                      onSelect(i);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: i == current
                            ? AppColors.primaryLight
                            : AppColors.bgPage,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: i == current
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: AvatarImage(index: i, size: 52),
                      ),
                    ),
                  )),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FamilyMemberCard extends StatelessWidget {
  final _FamilyMemberDraft draft;
  final VoidCallback onAvatarTap;
  final VoidCallback onRemove;

  const _FamilyMemberCard({
    required this.draft,
    required this.onAvatarTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: AvatarImage(index: draft.avatarIndex, size: 48),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: draft.controller,
              decoration: InputDecoration(
                hintText: 'Ім\'я учасника',
                hintStyle:
                    AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMain),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 3: Ліки ────────────────────────────────────────────────────────────

class _StepMedications extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onScan;

  const _StepMedications({super.key, required this.onNext, required this.onSkip, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ліки', style: AppTextStyles.h2),
          const SizedBox(height: 6),
          Text(
            'Додайте для кожного — сканування рецепта або вручну',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 24),

          // Scan button
          GestureDetector(
            onTap: onScan,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt_outlined,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Сканувати рецепт',
                            style: AppTextStyles.labelLg
                                .copyWith(color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('AI заповнить все за вас',
                            style: AppTextStyles.bodySm
                                .copyWith(
                                    color: Colors.white.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded,
                      color: Colors.white.withValues(alpha: 0.7)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info text
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF78350F)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ліки можна додати пізніше через розділ «Ліки» в головному меню',
                    style: AppTextStyles.bodySm
                        .copyWith(color: const Color(0xFF78350F)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _NextButton(label: 'Пропустити — додам пізніше →', onTap: onSkip),
          const SizedBox(height: 12),
          _SkipLink(label: 'Додати вручну', onTap: onSkip),
        ],
      ),
    );
  }
}

// ─── Step 4: Розклад ─────────────────────────────────────────────────────────

class _StepSchedule extends StatelessWidget {
  final VoidCallback onNext;
  const _StepSchedule({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Розклад', style: AppTextStyles.h2),
          const SizedBox(height: 6),
          Text(
            'Після додавання ліків AI автоматично складе розклад прийомів',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 48, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  'Розклад з\'явиться після додавання ліків',
                  style: AppTextStyles.labelLg.copyWith(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'AI враховує інструкції: після їжі, інтервал між дозами, сумісність препаратів',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _NextButton(label: 'Розклад підходить →', onTap: onNext),
        ],
      ),
    );
  }
}

// ─── Step 5: Активність та самопочуття ───────────────────────────────────────

class _StepActivities extends StatelessWidget {
  final bool walkEnabled;
  final bool wellbeingEnabled;
  final void Function(bool) onWalkToggle;
  final void Function(bool) onWellbeingToggle;
  final VoidCallback onNext;

  const _StepActivities({
    super.key,
    required this.walkEnabled,
    required this.wellbeingEnabled,
    required this.onWalkToggle,
    required this.onWellbeingToggle,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Активність та самопочуття', style: AppTextStyles.h2),
          const SizedBox(height: 6),
          Text(
            'Увімкніть одним перемикачем — налаштування можна змінити пізніше',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 24),

          _SectionLabel('Активність'),
          const SizedBox(height: 10),

          _ToggleRow(
            icon: Icons.directions_walk_rounded,
            title: 'Прогулянка',
            sub: '30 хв · щодня · 08:30',
            value: walkEnabled,
            onChanged: onWalkToggle,
          ),
          const SizedBox(height: 8),

          _SectionLabel('Щоденник самопочуття'),
          const SizedBox(height: 10),

          _ToggleRow(
            icon: Icons.favorite_rounded,
            title: 'Зрізи самопочуття',
            sub: '2–3 рази на день · 08:00, 14:00, 20:00',
            value: wellbeingEnabled,
            onChanged: onWellbeingToggle,
            activeColor: const Color(0xFF3F8F5F),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF78350F)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Додаток фіксуватиме зв\'язок між пропусками таблеток та симптомами. Не є медичною порадою.',
                    style: AppTextStyles.bodySm
                        .copyWith(color: const Color(0xFF78350F)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          _NextButton(label: 'Майже готово →', onTap: onNext),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.bodySm.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final bool value;
  final void Function(bool) onChanged;
  final Color activeColor;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.value,
    required this.onChanged,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgPage,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Icon(icon, size: 18, color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelMd),
                const SizedBox(height: 2),
                Text(sub,
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: activeColor,
            activeTrackColor: activeColor.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

// ─── Step 6: Done ─────────────────────────────────────────────────────────────

class _StepDone extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onFinish;

  const _StepDone({super.key, required this.isSaving, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.celebration_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text('Готово!', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          Text(
            'Все налаштовано. Відкрийте дашборд і почніть стежити за здоров\'ям.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.notifications_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Перше нагадування — сьогодні',
                        style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.primary),
                      ),
                      Text(
                        'Налаштуйте ліки щоб активувати нагадування',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.textSub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          _NextButton(
            label: isSaving ? 'Зберігаємо...' : 'Відкрити дашборд →',
            onTap: isSaving ? () {} : onFinish,
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          elevation: 0,
        ),
        child: Text(label, style: AppTextStyles.labelLg.copyWith(color: Colors.white)),
      ),
    );
  }
}

class _SkipLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SkipLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
