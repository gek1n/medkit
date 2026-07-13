import 'dart:convert';
import 'dart:math' as math;
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/services/symptom_library_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/wellbeing_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/section_label.dart';
import 'symptom_picker_sheet.dart';
import 'wellbeing_history_screen.dart';

class WellbeingCheckScreen extends ConsumerStatefulWidget {
  final int memberId;
  const WellbeingCheckScreen({super.key, required this.memberId});

  @override
  ConsumerState<WellbeingCheckScreen> createState() =>
      _WellbeingCheckScreenState();
}

class _WellbeingCheckScreenState extends ConsumerState<WellbeingCheckScreen> {
  int? _mood; // 1-5
  final Set<String> _symptoms = {};
  final _commentController = TextEditingController();
  bool _isSaving = false;
  bool _isListening = false;

  static const _moods = [
    (1, '😣', 'Погано', Color(0xFFFEE2E2)),
    (2, '😕', 'Так собі', Color(0xFFFEF3C7)),
    (3, '😐', 'Норм', Color(0xFFE9F4EC)),
    (4, '🙂', 'Добре', Color(0xFFDCFCE7)),
    (5, '😄', 'Відмінно', Color(0xFFDCFCE7)),
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_mood == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Оберіть самопочуття')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref
          .read(wellbeingRepositoryProvider)
          .insertLog(
            WellbeingLogsCompanion.insert(
              memberId: widget.memberId,
              mood: _mood!,
              symptomsJson: Value(jsonEncode(_symptoms.toList())),
              comment: Value(
                _commentController.text.trim().isEmpty
                    ? null
                    : _commentController.text.trim(),
              ),
            ),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Помилка: $e')));
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    MkBackButton(onTap: () => Navigator.pop(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Самопочуття', style: AppTextStyles.h2),
                          Text(
                            '${_formatDate(now)} · $timeLabel',
                            style: AppTextStyles.bodySm,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              WellbeingHistoryScreen(memberId: widget.memberId),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'Історія',
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.textSub,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 28),

                  // ── Step 1: Mood ──
                  SectionLabel('Як ви себе почуваєте?'),
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
                                          color: AppColors.primary.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 0,
                                          spreadRadius: 3,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  m.$2,
                                  style: const TextStyle(fontSize: 30),
                                ),
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
                  SectionLabel('Є симптоми?'),
                  const SizedBox(height: 4),
                  Text(
                    'Оберіть зі списку поширених або додайте своє',
                    style: AppTextStyles.bodySm,
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _openSymptomPicker,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.medical_information_outlined,
                              size: 18,
                              color: _symptoms.isEmpty
                                  ? AppColors.textMuted
                                  : AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _symptoms.isEmpty
                                  ? 'Симптоми не обрано'
                                  : _symptoms.map(SymptomLibraryService.labelFor).join(', '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: _symptoms.isEmpty
                                    ? AppColors.textMuted
                                    : AppColors.textMain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: AppColors.border),
                  ),

                  // ── Step 3: Comment ──
                  Row(
                    children: [
                      Text(
                        'Коментар',
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· необов\'язково',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _VoiceCommentField(
                    controller: _commentController,
                    onListeningChanged: (v) =>
                        setState(() => _isListening = v),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isSaving || _isListening) ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isSaving ? 'Зберігаємо...' : 'Зберегти зріз',
                        style: AppTextStyles.labelLg.copyWith(
                          color: Colors.white,
                        ),
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

  Future<void> _openSymptomPicker() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      ),
      builder: (_) => SymptomPickerSheet(initialSelected: _symptoms),
    );
    if (result != null) {
      setState(() {
        _symptoms
          ..clear()
          ..addAll(result);
      });
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      '',
      'січня',
      'лютого',
      'березня',
      'квітня',
      'травня',
      'червня',
      'липня',
      'серпня',
      'вересня',
      'жовтня',
      'листопада',
      'грудня',
    ];
    return '${d.day} ${months[d.month]}';
  }
}

// ─── Voice comment field ──────────────────────────────────────────────────────

enum _CommentMode { idle, recording, transcribed }

class _VoiceCommentField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<bool>? onListeningChanged;
  const _VoiceCommentField({required this.controller, this.onListeningChanged});

  @override
  State<_VoiceCommentField> createState() => _VoiceCommentFieldState();
}

class _VoiceCommentFieldState extends State<_VoiceCommentField>
    with SingleTickerProviderStateMixin {
  final _speech = SpeechToText();
  bool _sttReady = false;
  // STT-рушій стартує не миттєво — якщо почати говорити одразу по тапу,
  // перше слово губиться. Показуємо "Говоріть" лише коли рушій підтвердив
  // через onStatus, що дійсно вже захоплює звук.
  bool _micReady = false;
  _CommentMode _mode = _CommentMode.idle;
  String _transcript = '';
  int _seconds = 0;

  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _speech
        .initialize(
          onStatus: (status) {
            if (!mounted) return;
            if (status == 'listening') {
              setState(() => _micReady = true);
            } else if (_micReady) {
              setState(() => _micReady = false);
            }
          },
        )
        .then((ok) {
      if (mounted) setState(() => _sttReady = ok);
    });
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_sttReady) return;
    setState(() {
      _mode = _CommentMode.recording;
      _transcript = '';
      _seconds = 0;
      _micReady = false;
    });
    widget.onListeningChanged?.call(true);
    // tick timer
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _mode != _CommentMode.recording) return false;
      setState(() => _seconds++);
      return true;
    });

    await _speech.listen(
      onResult: (r) {
        if (mounted) setState(() => _transcript = r.recognizedWords);
        if (r.finalResult) _stopRecording();
      },
      listenOptions: SpeechListenOptions(
        localeId: 'uk_UA',
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> _stopRecording() async {
    await _speech.stop();
    widget.onListeningChanged?.call(false);
    if (!mounted) return;
    if (_transcript.trim().isNotEmpty) {
      widget.controller.text = _transcript.trim();
      setState(() => _mode = _CommentMode.transcribed);
    } else {
      // Нічого нового не наговорили — лишаємо попередній текст (якщо він
      // був) видимим у полі нижче, просто повертаємось у стан очікування.
      setState(() => _mode = _CommentMode.idle);
    }
  }

  String get _timerLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_mode == _CommentMode.recording)
          _RecordingBlock(
            waveCtrl: _waveCtrl,
            timerLabel: _timerLabel,
            micReady: _micReady,
            onStop: _stopRecording,
          )
        else if (_mode == _CommentMode.transcribed)
          _TranscribedBlock(text: _transcript, onReRecord: _startRecording)
        else
          _MicIdleButton(available: _sttReady, onTap: _startRecording),

        if (_mode != _CommentMode.recording) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'або введіть текстом',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: TextField(
              controller: widget.controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Опишіть як себе почуваєте…',
                hintStyle: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
              style: AppTextStyles.bodyMd,
            ),
          ),
        ],
      ],
    );
  }
}

class _MicIdleButton extends StatelessWidget {
  final bool available;
  final VoidCallback onTap;
  const _MicIdleButton({required this.available, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: available ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF3FAF5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCBE6D3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: available ? const Color(0xFF3F8F5F) : AppColors.border,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.mic_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    available ? 'Надиктуйте коментар' : 'Мікрофон недоступний',
                    style: AppTextStyles.labelMd.copyWith(
                      color: available
                          ? const Color(0xFF2F5F41)
                          : AppColors.textMuted,
                    ),
                  ),
                  if (available)
                    Text(
                      'Натисніть і говоріть',
                      style: AppTextStyles.bodySm.copyWith(
                        color: const Color(0xFF3F8F5F),
                      ),
                    ),
                ],
              ),
            ),
            if (available)
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF3F8F5F),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _RecordingBlock extends StatelessWidget {
  final AnimationController waveCtrl;
  final String timerLabel;
  final bool micReady;
  final VoidCallback onStop;

  static const _barHeights = [
    12.0,
    28.0,
    20.0,
    34.0,
    16.0,
    24.0,
    10.0,
    30.0,
    18.0,
    26.0,
    14.0,
    32.0,
  ];
  static const _barPhases = [
    0.0,
    0.3,
    0.6,
    0.1,
    0.8,
    0.4,
    0.7,
    0.2,
    0.9,
    0.5,
    0.15,
    0.65,
  ];

  const _RecordingBlock({
    required this.waveCtrl,
    required this.timerLabel,
    required this.micReady,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStop,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3FAF5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCBE6D3), width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F8F5F),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3F8F5F).withValues(alpha: 0.25),
                        blurRadius: 0,
                        spreadRadius: 6,
                      ),
                      BoxShadow(
                        color: const Color(0xFF3F8F5F).withValues(alpha: 0.12),
                        blurRadius: 0,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedBuilder(
                    animation: waveCtrl,
                    builder: (_, _) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(_barHeights.length, (i) {
                        final phase = _barPhases[i];
                        final t = (waveCtrl.value + phase) % 1.0;
                        final scale = 0.35 + 0.65 * math.sin(t * math.pi);
                        final h = _barHeights[i] * scale;
                        return Container(
                          width: 3,
                          height: h.clamp(4.0, 36.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3F8F5F),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  timerLabel,
                  style: AppTextStyles.labelMd.copyWith(
                    color: const Color(0xFF3F8F5F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              micReady
                  ? 'Говоріть… натисніть щоб зупинити'
                  : 'Готуємось… зачекайте секунду',
              style: AppTextStyles.bodySm.copyWith(
                color: const Color(0xFF3F8F5F),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TranscribedBlock extends StatelessWidget {
  final String text;
  final VoidCallback onReRecord;

  const _TranscribedBlock({required this.text, required this.onReRecord});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F1E7),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.mic_rounded,
                    color: Color(0xFF3F8F5F),
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Розшифровка голосу',
                style: AppTextStyles.labelMd.copyWith(
                  color: const Color(0xFF2F5F41),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(text, style: AppTextStyles.bodyMd.copyWith(height: 1.6)),
          const SizedBox(height: 4),
          Text(
            'Текст можна редагувати нижче в полі',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onReRecord,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.mic_rounded,
                    size: 15,
                    color: AppColors.textSub,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Записати знову',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
            SectionLabel('Сьогодні'),
            const SizedBox(height: 12),
            ...logs.map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LogCard(log: log),
              ),
            ),
          ],
        );
      },
    );
  }
}

final _todayLogsProvider = StreamProvider.family<List<WellbeingLog>, int>((
  ref,
  memberId,
) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));
  return ref
      .watch(wellbeingRepositoryProvider)
      .watchByMember(memberId)
      .map(
        (logs) => logs
            .where((l) => l.loggedAt.isAfter(start) && l.loggedAt.isBefore(end))
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
    final timeIcon = h < 12
        ? Icons.wb_sunny_rounded
        : h < 17
        ? Icons.schedule_rounded
        : Icons.dark_mode_rounded;
    final hh = h.toString().padLeft(2, '0');
    final mm = log.loggedAt.minute.toString().padLeft(2, '0');

    final symptoms = (jsonDecode(log.symptomsJson) as List).cast<String>();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _moodEmoji[log.mood.clamp(1, 5)],
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(timeIcon, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(
                      '$hh:$mm',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (symptoms.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: symptoms
                        .map(
                          (s) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              SymptomLibraryService.labelFor(s),
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF991B1B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (log.comment != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '«${log.comment}»',
                    style: AppTextStyles.bodySm.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
