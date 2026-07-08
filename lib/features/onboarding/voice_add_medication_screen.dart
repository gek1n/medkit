import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/services/ai_consent_service.dart';
import '../../core/services/nlu_service.dart';
import '../../core/services/prescription_scan_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/mk_back_button.dart';

enum _VoiceStage { checkingConsent, needsConsent, idle, listening, analyzing, error }

const _consentKind = 'voice';

/// [advance] розрізняє "Готово" (продовжити онбординг далі) від виходу
/// назад на попередній крок — і те, і те повертає вже надиктовані чернетки,
/// але лише перше має рухати кроки онбордингу вперед.
class VoiceMedicationResult {
  final List<ScannedMedication> drafts;
  final bool advance;
  const VoiceMedicationResult(this.drafts, {required this.advance});
}

/// Онбординг-варіант голосового додавання ліків — замінює сканування
/// рецепта (дорожче: фото йде на vision-аналіз) на голосову команду
/// (дешевше: лише короткий текст іде в NLU-проксі). Кожна успішно
/// розпізнана фраза одразу лягає у список чернеток [ScannedMedication],
/// той самий формат, що й після сканування — решта онбордингу (крок
/// розкладу, `_finish()`) працює з ним без змін.
class VoiceAddMedicationScreen extends StatefulWidget {
  const VoiceAddMedicationScreen({super.key});

  @override
  State<VoiceAddMedicationScreen> createState() => _VoiceAddMedicationScreenState();
}

class _VoiceAddMedicationScreenState extends State<VoiceAddMedicationScreen> {
  final _speech = SpeechToText();
  final List<ScannedMedication> _drafts = [];

  _VoiceStage _stage = _VoiceStage.checkingConsent;
  bool _sttAvailable = false;
  String _transcript = '';
  String _errorMsg = '';

  static const _examples = [
    '"Еналаприл одна таблетка двічі на день після їжі"',
    '"Парацетамол дві таблетки вранці та ввечері"',
    '"Вітамін D одна крапля щоранку"',
  ];

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _checkConsent() async {
    final given = await AiConsentService.hasConsent(_consentKind);
    if (!mounted) return;
    if (given) {
      setState(() => _stage = _VoiceStage.idle);
      _initSpeech();
    } else {
      setState(() => _stage = _VoiceStage.needsConsent);
    }
  }

  Future<void> _onConsentGiven() async {
    await AiConsentService.recordConsent(_consentKind);
    if (!mounted) return;
    setState(() => _stage = _VoiceStage.idle);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize(
      onError: (e) => _setError('Помилка розпізнавання: ${e.errorMsg}'),
    );
    if (mounted) setState(() => _sttAvailable = ok);
  }

  Future<void> _startListening() async {
    if (!_sttAvailable) {
      _setError('Розпізнавання мови недоступне на цьому пристрої');
      return;
    }
    setState(() {
      _stage = _VoiceStage.listening;
      _transcript = '';
    });
    await _speech.listen(
      onResult: (r) {
        if (mounted) setState(() => _transcript = r.recognizedWords);
        if (r.finalResult) _onSpeechDone();
      },
      listenOptions: SpeechListenOptions(
        localeId: 'uk_UA',
        listenFor: const Duration(seconds: 20),
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

  /// Назад під час запису/аналізу — не завершує розпізнавання, а просто
  /// повертає на екран інструкцій (скасовує поточну спробу).
  Future<void> _cancelListening() async {
    await _speech.stop();
    if (!mounted) return;
    setState(() {
      _stage = _VoiceStage.idle;
      _transcript = '';
    });
  }

  Future<void> _onSpeechDone() async {
    if (_stage != _VoiceStage.listening) return;
    final text = _transcript.trim();
    if (text.isEmpty) {
      _setError('Нічого не почуто. Спробуйте ще раз.');
      return;
    }
    setState(() => _stage = _VoiceStage.analyzing);
    try {
      final result = await NluService().parse(text);
      if (result.drugName == null) {
        _setError('Не вдалося розпізнати назву ліків. Спробуйте ще раз.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _drafts.add(ScannedMedication(
          name: result.drugName!,
          doseAmount: result.doseAmount,
          doseUnit: result.doseUnit,
          scheduleTimes: result.scheduleTimes,
          foodRelation: result.foodRelation,
        ));
        _stage = _VoiceStage.idle;
      });
    } catch (e) {
      _setError('Помилка аналізу: $e');
    }
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _errorMsg = msg;
      _stage = _VoiceStage.error;
    });
  }

  void _retry() => setState(() {
        _stage = _VoiceStage.idle;
        _transcript = '';
        _errorMsg = '';
      });

  void _done() =>
      Navigator.of(context).pop(VoiceMedicationResult(_drafts, advance: true));

  void _backToOnboarding() =>
      Navigator.of(context).pop(VoiceMedicationResult(_drafts, advance: false));

  @override
  Widget build(BuildContext context) {
    final onBack = switch (_stage) {
      _VoiceStage.listening || _VoiceStage.analyzing => _cancelListening,
      _ => _backToOnboarding,
    };
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: onBack),
            Expanded(
              child: switch (_stage) {
                _VoiceStage.checkingConsent => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                _VoiceStage.needsConsent => _ConsentBody(onAgree: _onConsentGiven),
                _VoiceStage.idle => _IdleBody(
                    sttAvailable: _sttAvailable,
                    examples: _examples,
                    drafts: _drafts,
                    onStart: _startListening,
                    onDone: _drafts.isNotEmpty ? _done : null,
                  ),
                _VoiceStage.listening => _ListeningBody(
                    transcript: _transcript,
                    onStop: _stopListening,
                  ),
                _VoiceStage.analyzing => const _AnalyzingBody(),
                _VoiceStage.error => _ErrorBody(message: _errorMsg, onRetry: _retry),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          MkBackButton(onTap: onBack),
          const SizedBox(width: 12),
          Text('Додати голосом', style: AppTextStyles.h3),
        ],
      ),
    );
  }
}

class _ConsentBody extends StatefulWidget {
  final VoidCallback onAgree;
  const _ConsentBody({required this.onAgree});

  @override
  State<_ConsentBody> createState() => _ConsentBodyState();
}

class _ConsentBodyState extends State<_ConsentBody> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      children: [
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLighter, width: 2.5),
            ),
            child: const Center(child: Icon(Icons.mic_rounded, size: 44, color: AppColors.primary)),
          ),
        ),
        const SizedBox(height: 20),
        Text('Перш ніж почати',
            textAlign: TextAlign.center, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.primaryLighter),
          ),
          child: Text(
            'Розпізнавання голосу відбувається на пристрої. Але щоб зрозуміти назву '
            'ліків, дозу та розклад, короткий текст фрази надсилається сервісу '
            'Anthropic (Claude) — без збереження після відповіді.',
            style: AppTextStyles.bodyMd,
          ),
        ),
        const SizedBox(height: AppDimensions.lg),
        GestureDetector(
          onTap: () => setState(() => _checked = !_checked),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _checked ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _checked ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: _checked
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Я погоджуюсь на обробку тексту моєї фрази для розпізнавання команди',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMain),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.xl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _checked ? widget.onAgree : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.border,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
            ),
            child: Text('Зрозуміло, погоджуюсь',
                style: AppTextStyles.bodyMd
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

class _IdleBody extends StatelessWidget {
  final bool sttAvailable;
  final List<String> examples;
  final List<ScannedMedication> drafts;
  final VoidCallback onStart;
  final VoidCallback? onDone;

  const _IdleBody({
    required this.sttAvailable,
    required this.examples,
    required this.drafts,
    required this.onStart,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppDimensions.screenPadding, AppDimensions.lg, AppDimensions.screenPadding, AppDimensions.xl),
      children: [
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLighter, width: 2.5),
            ),
            child: const Center(child: Icon(Icons.mic_rounded, size: 52, color: AppColors.primary)),
          ),
        ),
        const SizedBox(height: 20),
        Text('Скажіть, які ліки приймаєте',
            textAlign: TextAlign.center, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Назва, доза і коли приймати — одним реченням',
            textAlign: TextAlign.center, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub)),
        const SizedBox(height: AppDimensions.xl),
        Text('НАПРИКЛАД', style: AppTextStyles.labelSm),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: examples.asMap().entries.map((e) {
              final isLast = e.key == examples.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.md, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.format_quote_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(e.value,
                              style: AppTextStyles.bodyMd.copyWith(fontStyle: FontStyle.italic)),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, color: AppColors.borderLight),
                ],
              );
            }).toList(),
          ),
        ),
        if (drafts.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.xl),
          Text('ДОДАНО (${drafts.length})', style: AppTextStyles.labelSm),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: drafts.asMap().entries.map((e) {
                final isLast = e.key == drafts.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.md, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(e.value.name,
                                style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                          ),
                          if (e.value.doseAmount != null)
                            Text(
                              '${e.value.doseAmount!.toStringAsFixed(e.value.doseAmount! % 1 == 0 ? 0 : 1)} ${e.value.doseUnit ?? ''}',
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                            ),
                        ],
                      ),
                    ),
                    if (!isLast) const Divider(height: 1, color: AppColors.borderLight),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: AppDimensions.xl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: sttAvailable ? onStart : null,
            icon: const Icon(Icons.mic_rounded, size: 20),
            label: Text(
              sttAvailable
                  ? (drafts.isEmpty ? 'Диктувати' : 'Диктувати ще')
                  : 'Мікрофон недоступний',
              style: AppTextStyles.bodyMd
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.border,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
            ),
          ),
        ),
        if (onDone != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onDone,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
              ),
              child: Text('Готово',
                  style: AppTextStyles.bodyMd
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ],
    );
  }
}

class _ListeningBody extends StatelessWidget {
  final String transcript;
  final VoidCallback onStop;

  const _ListeningBody({required this.transcript, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onStop,
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Center(child: Icon(Icons.stop_rounded, size: 40, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 28),
          Text('Слухаю...', style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text('Натисни на мікрофон щоб зупинити',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub)),
          if (transcript.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              child: Text('"$transcript"',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(fontStyle: FontStyle.italic)),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnalyzingBody extends StatelessWidget {
  const _AnalyzingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Аналізую...'),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sentiment_dissatisfied_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Щось пішло не так', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
            ),
            child: const Text('Спробувати ще раз'),
          ),
        ],
      ),
    );
  }
}
