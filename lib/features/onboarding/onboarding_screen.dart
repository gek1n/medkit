import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/db/app_database.dart';
import '../../core/services/notification_service.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../../data/repositories/wellbeing_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/section_label.dart';
import '../medications/add_medication_screen.dart';
import '../today/providers/today_providers.dart';
import 'join_family_screen.dart';
import 'privacy_gate_screen.dart';
import 'restore_account_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  static const _totalSteps = 6;

  // Step 2: ім'я + аватар власного профілю
  final _nameController = TextEditingController();
  int _avatarIndex = 0;

  // Step 3: ліки — стандартна карточка додавання (форма + скан фото),
  // memberId ще не існує на цьому кроці, тож MedicationsCompanion
  // повертається як чернетка (фіктивний memberId) і записується в БД лише
  // в _finish(), коли власний профіль вже створено.
  final List<MedicationsCompanion> _medicationDrafts = [];

  // Step 5: activity/wellbeing toggles
  bool _walkEnabled = true;
  bool _wellbeingEnabled = true;

  bool _isSaving = false;

  Future<void> _openAddMedication() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicationScreen(
          onDraftCreated: (draft) => setState(() => _medicationDrafts.add(draft)),
        ),
      ),
    );
    if (saved == true) _next();
  }

  void _removeMedicationDraft(int index) {
    setState(() => _medicationDrafts.removeAt(index));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  void _next() {
    if (_step == 2 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.enterYourNameError)));
      return;
    }
    // Крок 1 → крок 2: перший природний момент попросити дозвіл на
    // сповіщення (не одразу на холодному старті, до першого екрана).
    if (_step == 0) {
      unawaited(NotificationService.requestPermissions());
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
    final l10n = context.l10n;
    try {
      final repo = container.read(membersRepositoryProvider);
      final name = _nameController.text.trim().isEmpty
          ? l10n.meCapsLabel
          : _nameController.text.trim();

      final ownerId = await repo.insert(
        MembersCompanion.insert(
          name: name,
          avatarIndex: Value(_avatarIndex),
          role: const Value('owner'),
        ),
      );

      if (_medicationDrafts.isNotEmpty) {
        final medRepo = container.read(medicationsRepositoryProvider);
        for (final draft in _medicationDrafts) {
          await medRepo.insert(draft.copyWith(memberId: Value(ownerId)));
        }
        container.invalidate(generateTodayIntakesProvider);
        container.invalidate(tomorrowIntakesProvider);
      }

      if (_walkEnabled) {
        final activitiesRepo = container.read(activitiesRepositoryProvider);
        final activityId = await activitiesRepo.insertActivity(
          ActivitiesCompanion.insert(
            memberId: ownerId,
            name: l10n.walkActivityName,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.onboardingFinishError(e.toString()))));
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
            _ProgressBar(
              step: _step,
              total: _totalSteps,
              onBack: _step > 0 ? _back : null,
            ),
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
      0 => _StepWelcome(key: const ValueKey(0), onNext: _next),
      1 => _StepAccountChoice(
        key: const ValueKey(1),
        onCreateAccount: _next,
        onJoinFamily: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const JoinFamilyScreen())),
        onRestoreAccount: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const RestoreAccountScreen())),
      ),
      2 => _StepName(
        key: const ValueKey(2),
        nameController: _nameController,
        avatarIndex: _avatarIndex,
        onAvatarChange: (i) => setState(() => _avatarIndex = i),
        onNext: _next,
      ),
      3 => _StepMedications(
        key: const ValueKey(3),
        drafts: _medicationDrafts,
        onSkip: _skip,
        onNext: _next,
        onAddMedication: _openAddMedication,
        onRemoveDraft: _removeMedicationDraft,
      ),
      4 => _StepActivities(
        key: const ValueKey(4),
        walkEnabled: _walkEnabled,
        wellbeingEnabled: _wellbeingEnabled,
        onWalkToggle: (v) => setState(() => _walkEnabled = v),
        onWellbeingToggle: (v) => setState(() => _wellbeingEnabled = v),
        onNext: _next,
      ),
      _ => PrivacyGateStep(
        key: const ValueKey(5),
        isBusy: _isSaving,
        hasMedications: _medicationDrafts.isNotEmpty,
        onConfirm: _finish,
      ),
    };
  }
}

// ─── Step 0: Привітання ──────────────────────────────────────────────────────

class _StepWelcome extends StatelessWidget {
  final VoidCallback onNext;
  const _StepWelcome({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/illustrations/welcome-hero.png',
                    height: 264,
                  ),
                  const SizedBox(height: 24),
                  Text(context.l10n.welcomeGreeting, style: AppTextStyles.h1),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.welcomeDescription,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _NextButton(label: context.l10n.startAction, onTap: onNext),
        ],
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              total,
              (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i <= step ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (onBack != null) MkBackButton(onTap: onBack),
              const Spacer(),
              Text(
                context.l10n.onboardingStepLabel(step + 1, total),
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Step 1: Як почнемо ──────────────────────────────────────────────────────

class _StepAccountChoice extends StatelessWidget {
  final VoidCallback onCreateAccount;
  final VoidCallback onJoinFamily;
  final VoidCallback onRestoreAccount;

  const _StepAccountChoice({
    super.key,
    required this.onCreateAccount,
    required this.onJoinFamily,
    required this.onRestoreAccount,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              'assets/illustrations/account-choice-hero.png',
              height: 200,
            ),
          ),
          const SizedBox(height: 20),
          Text(context.l10n.accountChoiceTitle, style: AppTextStyles.h2),
          const SizedBox(height: 6),
          Text(
            context.l10n.accountChoiceSubtitle,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 24),
          _AccountChoiceCard(
            icon: Icons.person_add_rounded,
            title: context.l10n.createAccountTitle,
            sub: context.l10n.createAccountSubtitle,
            onTap: onCreateAccount,
          ),
          const SizedBox(height: 10),
          _AccountChoiceCard(
            icon: Icons.family_restroom_rounded,
            title: context.l10n.joinFamilyChoiceTitle,
            sub: context.l10n.joinFamilyChoiceSubtitle,
            onTap: onJoinFamily,
          ),
          const SizedBox(height: 10),
          _AccountChoiceCard(
            icon: Icons.restore_rounded,
            title: context.l10n.restoreAccountTitle,
            sub: context.l10n.restoreAccountChoiceSubtitle,
            onTap: onRestoreAccount,
          ),
        ],
      ),
    );
  }
}

class _AccountChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  const _AccountChoiceCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 16,
                offset: Offset(0, 6)),
          ],
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
                  Text(
                    sub,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2: Ім'я + аватар власного профілю ──────────────────────────────────
// Раніше тут ще можна було одразу додати "чернетки" членів сім'ї — прибрано:
// профілі інших людей тепер створюються явно, після власної реєстрації,
// через "Сім'я" (локальний dependent) або запрошення до сімейної групи
// (FamilyGroupInviteScreen) — ніколи мовчки під час онбордингу.

class _StepName extends StatelessWidget {
  final TextEditingController nameController;
  final int avatarIndex;
  final void Function(int) onAvatarChange;
  final VoidCallback onNext;

  const _StepName({
    super.key,
    required this.nameController,
    required this.avatarIndex,
    required this.onAvatarChange,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.tellAboutYourselfTitle, style: AppTextStyles.h2),
              const SizedBox(height: 6),
              Text(
                context.l10n.tellAboutYourselfSubtitle,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
              ),
              const SizedBox(height: 24),

              // Owner: photo preview
              Center(child: AvatarImage(index: avatarIndex, size: 96)),
              const SizedBox(height: 20),

              // Owner: name input
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: context.l10n.yourNameHint,
                    hintStyle: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                  ),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Owner: avatar picker (only this list scrolls)
                _AvatarGrid(
                  start: 0,
                  end: avatarCount,
                  selectedIndex: avatarIndex,
                  onChanged: onAvatarChange,
                ),
                const SizedBox(height: AppDimensions.lg),
                _SectionDivider(label: context.l10n.petAvatarsSectionLabel),
                const SizedBox(height: AppDimensions.md),
                _AvatarGrid(
                  start: avatarCount,
                  end: totalAvatarCount,
                  selectedIndex: avatarIndex,
                  onChanged: onAvatarChange,
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: _NextButton(label: context.l10n.nextToMedsAction, onTap: onNext),
        ),
      ],
    );
  }
}

// Розділ пікера аватарів на діапазон [start, end) — той самий вигляд плиток,
// що й раніше, лише параметризований, щоб малювати і людські аватари, і
// секцію "Домашні улюбленці" одним і тим самим кодом.
class _AvatarGrid extends StatelessWidget {
  final int start;
  final int end;
  final int selectedIndex;
  final void Function(int) onChanged;
  const _AvatarGrid({
    required this.start,
    required this.end,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: end - start,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) {
        final index = start + i;
        return GestureDetector(
          onTap: () => onChanged(index),
          child: Container(
            decoration: BoxDecoration(
              color: index == selectedIndex
                  ? AppColors.primaryLight
                  : AppColors.bgPage,
              shape: BoxShape.circle,
              border: Border.all(
                color: index == selectedIndex
                    ? AppColors.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: AvatarImage(index: index, size: 52),
            ),
          ),
        );
      },
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

// ─── Step 3: Ліки ────────────────────────────────────────────────────────────

class _StepMedications extends StatelessWidget {
  final List<MedicationsCompanion> drafts;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onAddMedication;
  final void Function(int index) onRemoveDraft;

  const _StepMedications({
    super.key,
    required this.drafts,
    required this.onSkip,
    required this.onNext,
    required this.onAddMedication,
    required this.onRemoveDraft,
  });

  @override
  Widget build(BuildContext context) {
    final hasDrafts = drafts.isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.medsTitle, style: AppTextStyles.h2),
          const SizedBox(height: 6),
          Text(
            context.l10n.scanOrEnterManuallyHint,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 24),

          // Вже додані на цьому кроці — інакше повернення назад виглядає
          // так, ніби нічого не збереглося, хоча чернетки нікуди не ділись.
          if (hasDrafts) ...[
            ...drafts.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DraftMedRow(
                      name: e.value.name.value,
                      onRemove: () => onRemoveDraft(e.key),
                    ),
                  ),
                ),
            const SizedBox(height: 12),
          ],

          // Add medication button
          GestureDetector(
            onTap: onAddMedication,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.medication_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasDrafts ? context.l10n.addMoreMedsAction : context.l10n.addMedsShortAction,
                          style: AppTextStyles.labelLg.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.addMedsHint,
                          style: AppTextStyles.bodySm.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
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
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Color(0xFF78350F),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.addMedsLaterInfo,
                    style: AppTextStyles.bodySm.copyWith(
                      color: const Color(0xFF78350F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (hasDrafts)
            _NextButton(label: context.l10n.nextAction, onTap: onNext)
          else
            _SkipLink(label: context.l10n.skipAddLaterAction, onTap: onSkip),
        ],
      ),
    );
  }
}

class _DraftMedRow extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;
  const _DraftMedRow({required this.name, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: AppTextStyles.bodyMd)),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Step 4: Активність та самопочуття ───────────────────────────────────────

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
          Text(context.l10n.activityWellbeingTitle, style: AppTextStyles.h2),
          const SizedBox(height: 6),
          Text(
            context.l10n.activityWellbeingSubtitle,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 24),

          SectionLabel(context.l10n.activitySectionLabel),
          const SizedBox(height: 10),

          _ToggleRow(
            icon: Icons.directions_walk_rounded,
            title: context.l10n.walkActivityName,
            sub: context.l10n.walkActivitySub,
            value: walkEnabled,
            onChanged: onWalkToggle,
          ),
          const SizedBox(height: 8),

          SectionLabel(context.l10n.wellbeingDiaryLabel),
          const SizedBox(height: 6),
          Text(
            context.l10n.wellbeingDiaryDescription,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 10),

          _ToggleRow(
            icon: Icons.favorite_rounded,
            title: context.l10n.wellbeingSlotsTitle,
            sub: context.l10n.wellbeingSlotsSub,
            value: wellbeingEnabled,
            onChanged: onWellbeingToggle,
            activeColor: const Color(0xFF3F8F5F),
          ),

          const SizedBox(height: 32),
          _NextButton(label: context.l10n.almostDoneAction, onTap: onNext),
        ],
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
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
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
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelMd),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
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
        child: Text(
          label,
          style: AppTextStyles.labelLg.copyWith(color: Colors.white),
        ),
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
