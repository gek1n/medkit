import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/services/nlu_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../medications/add_medication_screen.dart';
import '../today/providers/today_providers.dart';

// ────────────────────────────── state ──────────────────────────────

enum _VoiceState { idle, listening, analyzing, result, error }

// ────────────────────────────── screen ──────────────────────────────

class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen>
    with SingleTickerProviderStateMixin {
  final _speech = SpeechToText();

  _VoiceState _state = _VoiceState.idle;
  bool _sttAvailable = false;
  String _transcript = '';
  NluResult? _result;
  String _errorMsg = '';
  int _foodRelation = 1; // 0=before 1=after 2=any

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _initSpeech();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize(
      onError: (e) => _setError('STT помилка: ${e.errorMsg}'),
    );
    if (mounted) setState(() => _sttAvailable = ok);
  }

  Future<void> _startListening() async {
    if (!_sttAvailable) {
      _setError('Розпізнавання мови недоступне на цьому пристрої');
      return;
    }
    setState(() {
      _state = _VoiceState.listening;
      _transcript = '';
    });
    await _speech.listen(
      onResult: (r) {
        if (mounted) setState(() => _transcript = r.recognizedWords);
        if (r.finalResult) _onSpeechDone();
      },
      listenOptions: SpeechListenOptions(
        localeId: 'uk_UA',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    _onSpeechDone();
  }

  Future<void> _onSpeechDone() async {
    if (_state != _VoiceState.listening) return;
    final text = _transcript.trim();
    if (text.isEmpty) {
      _setError('Нічого не почуто. Спробуй ще раз.');
      return;
    }
    setState(() => _state = _VoiceState.analyzing);
    await _runNlu(text);
  }

  Future<void> _runNlu(String text) async {
    try {
      final result = await NluService().parse(text);
      if (mounted) {
        final fr = result.foodRelation;
        setState(() {
          _result = result;
          _foodRelation = fr == 'before' ? 0 : fr == 'after' ? 1 : 2;
          _state = _VoiceState.result;
        });
      }
    } catch (e) {
      _setError('Помилка аналізу: $e');
    }
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _errorMsg = msg;
      _state = _VoiceState.error;
    });
  }

  void _reset() => setState(() {
        _state = _VoiceState.idle;
        _transcript = '';
        _result = null;
        _errorMsg = '';
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _BackHeader(onBack: () => Navigator.pop(context)),
            Expanded(
              child: switch (_state) {
                _VoiceState.idle => _IdleBody(
                    sttAvailable: _sttAvailable,
                    onStart: _startListening,
                  ),
                _VoiceState.listening => _ListeningBody(
                    anim: _pulseAnim,
                    transcript: _transcript,
                    onStop: _stopListening,
                  ),
                _VoiceState.analyzing => _AnalyzingBody(
                    transcript: _transcript,
                  ),
                _VoiceState.result => _ResultBody(
                    result: _result!,
                    foodRelation: _foodRelation,
                    onFoodChanged: (v) =>
                        setState(() => _foodRelation = v),
                    onConfirm: () =>
                        _handleConfirm(_result!),
                    onEditManually: () =>
                        _handleEditManually(_result!),
                    onRetry: _reset,
                  ),
                _VoiceState.error => _ErrorBody(
                    message: _errorMsg,
                    onRetry: _reset,
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleConfirm(NluResult r) {
    switch (r.action) {
      case 'add_med':
        _openAddMed();
      case 'mark_taken':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Найближчий прийом відмічено ✓')),
        );
        Navigator.pop(context);
      case 'add_wellbeing':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Зріз самопочуття збережено')),
        );
        Navigator.pop(context);
      case 'add_appointment':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Відкриваємо форму запису...')),
        );
        Navigator.pop(context);
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Не вдалося розпізнати команду')),
        );
    }
  }

  void _handleEditManually(NluResult r) {
    if (r.action == 'add_med') {
      _openAddMed();
    } else {
      Navigator.pop(context);
    }
  }

  void _openAddMed() {
    final memberId =
        ref.read(currentMemberProvider).valueOrNull?.id;
    if (memberId == null) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddMedicationScreen(memberId: memberId),
      ),
    );
  }
}

// ────────────────────────────── back header ──────────────────────────────

class _BackHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _BackHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: AppColors.textMain),
            ),
          ),
          const SizedBox(width: 12),
          Text('Голосове управління',
              style: AppTextStyles.h3),
        ],
      ),
    );
  }
}

// ────────────────────────────── idle body ──────────────────────────────

class _IdleBody extends StatelessWidget {
  final bool sttAvailable;
  final VoidCallback onStart;
  const _IdleBody(
      {required this.sttAvailable, required this.onStart});

  static const _examples = [
    ('💊', Color(0xFFF2EEFF), '"Прийняв таблетку"',
        'Відмітить найближчий прийом'),
    ('⏱', Color(0xFFFFF1EB),
        '"Додай Еналаприл 10 мг вранці та ввечері"',
        'Відкриє форму з заповненими полями'),
    ('💜', Color(0xFFF5F3FF),
        '"Самопочуття сьогодні — болить голова"',
        'Запис у щоденник самопочуття'),
    ('🗓', Color(0xFFFFFBEB),
        '"Запис до кардіолога у пʼятницю о 10"',
        'Додасть нагадування про прийом'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppDimensions.screenPadding,
          AppDimensions.lg,
          AppDimensions.screenPadding,
          AppDimensions.xl),
      children: [
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primaryLighter, width: 2.5),
            ),
            child: const Center(
              child: Icon(Icons.mic,
                  size: 52, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Що хочеш зробити?',
            textAlign: TextAlign.center,
            style: AppTextStyles.h3
                .copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Натисни і скажи команду\nабо почни говорити',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.textSub)),
        const SizedBox(height: AppDimensions.xl),
        Text('ПРИКЛАДИ КОМАНД',
            style: AppTextStyles.labelSm),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: _examples.asMap().entries.map((e) {
              final ex = e.value;
              final isLast = e.key == _examples.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.md,
                        vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: ex.$2,
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Center(
                              child: Text(ex.$1,
                                  style: const TextStyle(
                                      fontSize: 16))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(ex.$3,
                                  style: AppTextStyles.bodyMd
                                      .copyWith(
                                          fontWeight:
                                              FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(ex.$4,
                                  style: AppTextStyles.bodySm
                                      .copyWith(
                                          color:
                                              AppColors.textSub)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1,
                        color: AppColors.borderLight),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppDimensions.xl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: sttAvailable ? onStart : null,
            icon: const Icon(Icons.mic, size: 20),
            label: Text(
              sttAvailable
                  ? 'Утримуй і говори'
                  : 'Мікрофон недоступний',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.border,
              padding:
                  const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    AppDimensions.radiusLg),
              ),
              elevation: 4,
              shadowColor:
                  AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────── listening body ──────────────────────────────

class _ListeningBody extends StatelessWidget {
  final Animation<double> anim;
  final String transcript;
  final VoidCallback onStop;

  const _ListeningBody({
    required this.anim,
    required this.transcript,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onStop,
            child: AnimatedBuilder(
              animation: anim,
              builder: (_, child) =>
                  Transform.scale(scale: anim.value, child: child),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.stop,
                          size: 40, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Слухаю...',
              style: AppTextStyles.h2
                  .copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text('Натисни на мікрофон щоб зупинити',
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.textSub)),
          if (transcript.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusLg),
              ),
              child: Text(
                '"$transcript"',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────── analyzing body ──────────────────────────────

class _AnalyzingBody extends StatelessWidget {
  final String transcript;
  const _AnalyzingBody({required this.transcript});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.lg),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusLg),
            ),
            child: Text(
              '"$transcript"',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd
                  .copyWith(fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(
              color: AppColors.primary),
          const SizedBox(height: 16),
          Text('Аналізую команду...',
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.textSub)),
        ],
      ),
    );
  }
}

// ────────────────────────────── result body ──────────────────────────────

class _ResultBody extends StatelessWidget {
  final NluResult result;
  final int foodRelation;
  final ValueChanged<int> onFoodChanged;
  final VoidCallback onConfirm;
  final VoidCallback onEditManually;
  final VoidCallback onRetry;

  const _ResultBody({
    required this.result,
    required this.foodRelation,
    required this.onFoodChanged,
    required this.onConfirm,
    required this.onEditManually,
    required this.onRetry,
  });

  static const _foodOpts = ['До їжі', 'Після їжі', 'Не важливо'];

  List<(String, String)> get _parsedRows {
    final rows = <(String, String)>[];
    rows.add(('ДІЯ', _actionLabel(result.action)));
    if (result.drugName != null) {
      rows.add(('ПРЕПАРАТ', result.drugName!));
    }
    if (result.doseAmount != null) {
      final dose = result.doseAmount!
          .toStringAsFixed(result.doseAmount! % 1 == 0 ? 0 : 1);
      rows.add(('ДОЗА', '$dose ${result.doseUnit ?? ''}'));
    }
    if (result.scheduleTimes != null &&
        result.scheduleTimes!.isNotEmpty) {
      rows.add(('РОЗКЛАД',
          result.scheduleTimes!.map(_scheduleLabel).join(' + ')));
    }
    if (result.wellbeingMood != null) {
      rows.add(('НАСТРІЙ', _moodLabel(result.wellbeingMood!)));
    }
    if (result.appointmentType != null) {
      rows.add(('ЛІКАР', result.appointmentType!));
    }
    return rows;
  }

  String _actionLabel(String a) => switch (a) {
        'mark_taken' => 'Відмітити прийом',
        'add_med' => 'Додати ліки',
        'add_wellbeing' => 'Записати самопочуття',
        'add_appointment' => 'Запис до лікаря',
        _ => 'Невідома команда',
      };

  String _scheduleLabel(String s) => switch (s) {
        'morning' => 'Вранці',
        'evening' => 'Ввечері',
        'afternoon' => 'Вдень',
        'night' => 'Вночі',
        _ => s,
      };

  String _moodLabel(int m) => switch (m) {
        1 => '😣 Погано',
        2 => '😕 Так собі',
        3 => '😐 Норм',
        4 => '🙂 Добре',
        5 => '😄 Відмінно',
        _ => '$m',
      };

  bool get _showFoodClarification =>
      result.action == 'add_med' && result.foodRelation == null;

  @override
  Widget build(BuildContext context) {
    final rows = _parsedRows;

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      children: [
        // Transcript
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ТИ СКАЗАВ',
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.primary)),
              const SizedBox(height: 6),
              Text('"${result.transcript}"',
                  style: AppTextStyles.bodyMd
                      .copyWith(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.lg),
        Text('Я зрозумів так:',
            style: AppTextStyles.bodyMd
                .copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: rows.asMap().entries.map((e) {
              final isLast = e.key == rows.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.md,
                        vertical: 12),
                    child: Row(
                      children: [
                        Text(e.value.$1,
                            style: AppTextStyles.labelSm),
                        const Spacer(),
                        Text(e.value.$2,
                            style: AppTextStyles.bodyMd
                                .copyWith(
                                    fontWeight:
                                        FontWeight.w700)),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1,
                        color: AppColors.borderLight),
                ],
              );
            }).toList(),
          ),
        ),
        if (_showFoodClarification) ...[
          const SizedBox(height: AppDimensions.md),
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                  color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚡',
                    style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text('Уточни ще одне',
                          style: AppTextStyles.labelMd
                              .copyWith(
                                  color: const Color(
                                      0xFF92400E))),
                      const SizedBox(height: 2),
                      Text(
                        'Ти не сказав, до чи після їжі. Вибери нижче або пропусти',
                        style: AppTextStyles.bodySm
                            .copyWith(
                                color: const Color(
                                    0xFF92400E)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          Row(
            children: List.generate(_foodOpts.length, (i) {
              final sel = foodRelation == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: i < _foodOpts.length - 1 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => onFoodChanged(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primaryLight
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd),
                        border: sel
                            ? Border.all(
                                color: AppColors.primary,
                                width: 1.5)
                            : null,
                      ),
                      child: Text(
                        _foodOpts[i],
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelMd
                            .copyWith(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.textSub),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
        const SizedBox(height: AppDimensions.xl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    AppDimensions.radiusLg),
              ),
              elevation: 4,
              shadowColor:
                  AppColors.primary.withValues(alpha: 0.3),
            ),
            child: const Text('Підтвердити і додати',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onEditManually,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    AppDimensions.radiusLg),
              ),
            ),
            child: const Text('Редагувати вручну',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onRetry,
          child: Text('Спробувати ще раз',
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.textSub)),
        ),
        const SizedBox(height: AppDimensions.xl),
      ],
    );
  }
}

// ────────────────────────────── error body ──────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody(
      {required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Щось пішло не так',
              style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    AppDimensions.radiusLg),
              ),
            ),
            child: const Text('Спробувати ще раз'),
          ),
        ],
      ),
    );
  }
}
