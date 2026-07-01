import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/wellbeing_repository.dart';

class WellbeingCheckScreen extends ConsumerStatefulWidget {
  final int memberId;
  const WellbeingCheckScreen({super.key, required this.memberId});

  @override
  ConsumerState<WellbeingCheckScreen> createState() =>
      _WellbeingCheckScreenState();
}

class _WellbeingCheckScreenState
    extends ConsumerState<WellbeingCheckScreen> {
  int? _mood; // 1-5
  final Set<String> _symptoms = {};
  final _commentController = TextEditingController();
  bool _isSaving = false;

  static const _moods = [
    (1, '😣', 'Погано', Color(0xFFFEE2E2)),
    (2, '😕', 'Так собі', Color(0xFFFEF3C7)),
    (3, '😐', 'Норм', Color(0xFFF2EEFF)),
    (4, '🙂', 'Добре', Color(0xFFDCFCE7)),
    (5, '😄', 'Відмінно', Color(0xFFDCFCE7)),
  ];

  // Common symptoms (keys for i18n, displayed as labels)
  static const _commonSymptoms = [
    ('headache', 'головний біль'),
    ('nausea', 'нудота'),
    ('dizziness', 'запаморочення'),
    ('weakness', 'слабість'),
    ('shortness_of_breath', 'задишка'),
    ('rash', 'висип'),
    ('pain', 'біль'),
    ('fever', 'температура'),
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_mood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Оберіть самопочуття')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(wellbeingRepositoryProvider).insertLog(
            WellbeingLogsCompanion.insert(
              memberId: widget.memberId,
              mood: _mood!,
              symptomsJson:
                  Value(jsonEncode(_symptoms.toList())),
              comment: Value(_commentController.text.trim().isEmpty
                  ? null
                  : _commentController.text.trim()),
            ),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Помилка: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeLabel = now.hour < 12
        ? 'ранковий зріз'
        : now.hour < 17
            ? 'денний зріз'
            : 'вечірній зріз';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Самопочуття', style: AppTextStyles.h2),
                        Text(
                          '${_formatDate(now)} · $timeLabel',
                          style: AppTextStyles.bodySm,
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text('Закрити',
                            style: AppTextStyles.labelMd
                                .copyWith(color: AppColors.primary)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 28),

                  // ── Step 1: Mood ──
                  Text('Як ви себе почуваєте?',
                      style: AppTextStyles.labelLg),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _moods.map((m) {
                      final sel = _mood == m.$1;
                      return GestureDetector(
                        onTap: () => setState(() => _mood = m.$1),
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: m.$4,
                                shape: BoxShape.circle,
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.4),
                                          blurRadius: 0,
                                          spreadRadius: 3,
                                        )
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(m.$2,
                                    style: const TextStyle(fontSize: 30)),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              m.$3,
                              style: AppTextStyles.caption.copyWith(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: AppColors.border),
                  ),

                  // ── Step 2: Symptoms ──
                  Text('Є симптоми?', style: AppTextStyles.labelLg),
                  const SizedBox(height: 4),
                  Text(
                    'З побічок ваших ліків + часто зустрічаються у вас',
                    style: AppTextStyles.bodySm,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._commonSymptoms.map((s) {
                        final sel = _symptoms.contains(s.$1);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (sel) {
                              _symptoms.remove(s.$1);
                            } else {
                              _symptoms.add(s.$1);
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFFFEE2E2)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel
                                    ? const Color(0xFFFECACA)
                                    : AppColors.border,
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              s.$2,
                              style: AppTextStyles.labelMd.copyWith(
                                color: sel
                                    ? const Color(0xFF991B1B)
                                    : AppColors.textSub,
                              ),
                            ),
                          ),
                        );
                      }),
                      GestureDetector(
                        onTap: () => _addCustomSymptom(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                style: BorderStyle.solid),
                          ),
                          child: Text(
                            '＋ своє',
                            style: AppTextStyles.labelMd
                                .copyWith(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: AppColors.border),
                  ),

                  // ── Step 3: Comment ──
                  Row(
                    children: [
                      Text('Коментар', style: AppTextStyles.labelLg),
                      const SizedBox(width: 6),
                      Text('· необов\'язково',
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Опишіть як себе почуваєте…',
                        hintStyle: AppTextStyles.bodyMd
                            .copyWith(color: AppColors.textMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      style: AppTextStyles.bodyMd,
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        _isSaving ? 'Зберігаємо...' : 'Зберегти зріз',
                        style: AppTextStyles.labelLg
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),

                  // ── Today's logs ──
                  const SizedBox(height: 32),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),
                  _TodayLogsSection(memberId: widget.memberId),
                  const SizedBox(height: 60),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCustomSymptom(BuildContext context) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Додати симптом', style: AppTextStyles.h3),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Назва симптому'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Скасувати')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Додати')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _symptoms.add('custom_$result'));
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'січня', 'лютого', 'березня', 'квітня', 'травня', 'червня',
      'липня', 'серпня', 'вересня', 'жовтня', 'листопада', 'грудня',
    ];
    return '${d.day} ${months[d.month]}';
  }
}

// ─── Today's logs ─────────────────────────────────────────────────────────────

class _TodayLogsSection extends ConsumerWidget {
  final int memberId;
  const _TodayLogsSection({required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(_todayLogsProvider(memberId));

    return logsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (logs) {
        if (logs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Сьогодні', style: AppTextStyles.labelLg),
            const SizedBox(height: 12),
            ...logs.map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LogCard(log: log),
                )),
          ],
        );
      },
    );
  }
}

final _todayLogsProvider =
    StreamProvider.family<List<WellbeingLog>, int>((ref, memberId) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));
  return ref.watch(wellbeingRepositoryProvider).watchByMember(memberId).map(
        (logs) => logs
            .where((l) =>
                l.loggedAt.isAfter(start) && l.loggedAt.isBefore(end))
            .toList(),
      );
});

class _LogCard extends StatelessWidget {
  final WellbeingLog log;
  const _LogCard({required this.log});

  static const _moodEmoji = ['', '😣', '😕', '😐', '🙂', '😄'];

  @override
  Widget build(BuildContext context) {
    final h = log.loggedAt.hour;
    final timeIcon = h < 12 ? '☀️' : h < 17 ? '🕑' : '🌙';
    final hh = h.toString().padLeft(2, '0');
    final mm = log.loggedAt.minute.toString().padLeft(2, '0');

    final symptoms = (jsonDecode(log.symptomsJson) as List).cast<String>();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_moodEmoji[log.mood.clamp(1, 5)],
              style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$timeIcon $hh:$mm',
                    style: AppTextStyles.caption
                        .copyWith(fontWeight: FontWeight.w700)),
                if (symptoms.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: symptoms
                        .map((s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                s.startsWith('custom_')
                                    ? s.substring(7)
                                    : s,
                                style: AppTextStyles.caption.copyWith(
                                    color: const Color(0xFF991B1B),
                                    fontWeight: FontWeight.w600),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                if (log.comment != null) ...[
                  const SizedBox(height: 4),
                  Text('«${log.comment}»',
                      style: AppTextStyles.bodySm
                          .copyWith(fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
