import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/providers/app_language_provider.dart';
import '../../core/providers/plan_provider.dart';
import '../../core/services/ai_consent_service.dart';
import '../../core/services/ai_usage_service.dart';
import '../../core/services/marketing_topics_service.dart';
import '../../core/services/nlu_service.dart';
import '../../core/services/prescription_scan_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/mk_button.dart';
import '../add/add_activity_screen.dart';
import '../appointments/add_appointment_screen.dart';
import '../medications/add_medication_screen.dart';
import '../plans/plans_screen.dart';
import '../today/providers/today_providers.dart';

// ────────────────────────────── state ──────────────────────────────

enum _VoiceState { checkingConsent, needsConsent, idle, listening, analyzing, result, error }

const _consentKind = 'voice';

// ────────────────────────────── screen ──────────────────────────────

class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen>
    with SingleTickerProviderStateMixin {
  final _speech = SpeechToText();

  _VoiceState _state = _VoiceState.checkingConsent;
  bool _sttAvailable = false;
  // STT-рушій стартує не миттєво по натисканню — якщо почати говорити
  // одразу, як побачив "Слухаю", перше слово (найчастіше назва ліків)
  // губиться. Показуємо "Слухаю" лише коли рушій підтвердив через
  // onStatus, що дійсно вже захоплює звук.
  bool _micReady = false;
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
    _checkConsent();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _checkConsent() async {
    final given = await AiConsentService.hasConsent(_consentKind);
    if (!mounted) return;
    if (given) {
      setState(() => _state = _VoiceState.idle);
      _initSpeech();
    } else {
      setState(() => _state = _VoiceState.needsConsent);
    }
  }

  Future<void> _onConsentGiven() async {
    await AiConsentService.recordConsent(_consentKind);
    if (!mounted) return;
    setState(() => _state = _VoiceState.idle);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize(
      onError: (e) => _setError(context.l10n.sttErrorLabel(e.errorMsg)),
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'listening') {
          setState(() => _micReady = true);
        } else if (_micReady) {
          setState(() => _micReady = false);
        }
      },
    );
    if (mounted) setState(() => _sttAvailable = ok);
  }

  Future<void> _startListening() async {
    if (!_sttAvailable) {
      _setError(context.l10n.speechNotAvailableError);
      return;
    }
    final plan = ref.read(planProvider);
    if (!plan.isPaid && !await ref.read(aiUsageServiceProvider).canUseVoiceCommand()) {
      unawaited(MarketingTopicsService.markHitVoiceLimit());
      if (!mounted) return;
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const PlansScreen()));
      return;
    }
    setState(() {
      _state = _VoiceState.listening;
      _transcript = '';
      _micReady = false;
    });
    await _speech.listen(
      onResult: (r) {
        if (mounted) setState(() => _transcript = r.recognizedWords);
        if (r.finalResult) _onSpeechDone();
      },
      listenOptions: SpeechListenOptions(
        localeId: ref.read(appLanguageProvider),
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
      _setError(context.l10n.nothingHeardError);
      return;
    }
    setState(() => _state = _VoiceState.analyzing);
    await _runNlu(text);
  }

  Future<void> _runNlu(String text) async {
    try {
      final result = await NluService().parse(text);
      if (!ref.read(planProvider).isPaid) {
        await ref.read(aiUsageServiceProvider).recordVoiceCommand();
      }
      if (mounted) {
        final fr = result.foodRelation;
        setState(() {
          _result = result;
          _foodRelation = fr == 'before' ? 0 : fr == 'after' ? 1 : 2;
          _state = _VoiceState.result;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _setError(context.l10n.analysisErrorWithMessage(e.toString()));
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
                _VoiceState.checkingConsent => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  ),
                _VoiceState.needsConsent => _ConsentBody(
                    onAgree: _onConsentGiven,
                  ),
                _VoiceState.idle => _IdleBody(
                    sttAvailable: _sttAvailable,
                    onStart: _startListening,
                    languageLabel: appLanguageLabel(ref.watch(appLanguageProvider)),
                  ),
                _VoiceState.listening => _ListeningBody(
                    anim: _pulseAnim,
                    transcript: _transcript,
                    micReady: _micReady,
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
        _openAddMed(r);
      case 'add_activity':
        _openAddActivity(r);
      case 'add_appointment':
        _openAddAppointment(r);
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.l10n.commandNotRecognizedError)),
        );
    }
  }

  void _openAddMed(NluResult r) {
    final memberId = ref.read(currentMemberProvider).valueOrNull?.id;
    if (memberId == null) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicationScreen(
          memberId: memberId,
          voicePrefill: r.drugName == null
              ? null
              : ScannedMedication(
                  name: r.drugName!,
                  doseAmount: r.doseAmount,
                  doseUnit: r.doseUnit,
                  scheduleTimes: r.scheduleTimes,
                  foodRelation: r.foodRelation,
                ),
        ),
      ),
    );
  }

  void _openAddActivity(NluResult r) {
    final memberId = ref.read(currentMemberProvider).valueOrNull?.id;
    if (memberId == null) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddActivityScreen(
          memberId: memberId,
          voicePrefillName: r.activityName,
          voicePrefillTimes: r.scheduleTimes,
        ),
      ),
    );
  }

  void _openAddAppointment(NluResult r) {
    final memberId = ref.read(currentMemberProvider).valueOrNull?.id;
    if (memberId == null) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAppointmentScreen(
          memberId: memberId,
          voicePrefillDoctorType: r.appointmentType,
        ),
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
          MkBackButton(onTap: onBack),
          const SizedBox(width: 12),
          Text(context.l10n.voiceControlTitle,
              style: AppTextStyles.h3),
        ],
      ),
    );
  }
}

// ────────────────────────────── consent body ──────────────────────────────

class _ConsentBody extends StatelessWidget {
  final VoidCallback onAgree;
  const _ConsentBody({required this.onAgree});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppDimensions.screenPadding,
          AppDimensions.xl,
          AppDimensions.screenPadding,
          AppDimensions.xl),
      children: [
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primaryLighter, width: 2.5),
            ),
            child: const Center(
              child: Icon(Icons.mic_rounded, size: 44, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(context.l10n.beforeYouStartTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.primaryLighter),
          ),
          child: Text(
            context.l10n.voiceConsentDisclaimerBody,
            style: AppTextStyles.bodyMd,
          ),
        ),
        const SizedBox(height: AppDimensions.xl),
        MkButton(label: context.l10n.understoodAgreeAction, onTap: onAgree),
      ],
    );
  }
}

// ────────────────────────────── idle body ──────────────────────────────

class _IdleBody extends StatelessWidget {
  final bool sttAvailable;
  final VoidCallback onStart;
  final String languageLabel;
  const _IdleBody({
    required this.sttAvailable,
    required this.onStart,
    required this.languageLabel,
  });

  List<(IconData, Color, String, String)> _examples(BuildContext context) => [
        (Icons.medication_rounded, const Color(0xFFE9F4EC),
            context.l10n.voiceExampleMedQuote, context.l10n.voiceExampleMedDesc),
        (Icons.fitness_center_rounded, const Color(0xFFFFF1EB),
            context.l10n.voiceExampleActivityQuote, context.l10n.voiceExampleActivityDesc),
        (Icons.calendar_month_rounded, const Color(0xFFFFFBEB),
            context.l10n.voiceExampleApptQuote, context.l10n.voiceExampleApptDesc),
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
              child: Icon(Icons.mic_rounded,
                  size: 52, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(context.l10n.whatToDoTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.h3
                .copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(context.l10n.tapAndSayCommandHint,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.textSub)),
        const SizedBox(height: AppDimensions.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            context.l10n.dictateLanguageHint(languageLabel),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
          ),
        ),
        const SizedBox(height: AppDimensions.xl),
        Text(context.l10n.commandExamplesCapsLabel,
            style: AppTextStyles.labelSm),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 16,
                  offset: Offset(0, 6)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: _examples(context).asMap().entries.map((e) {
              final ex = e.value;
              final isLast = e.key == _examples(context).length - 1;
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
                              child: Icon(ex.$1,
                                  size: 18, color: AppColors.primary)),
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
        const SizedBox(height: AppDimensions.lg),
        Text(
          context.l10n.experimentalFeatureNotice,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppDimensions.md),
        MkButton(
          label: sttAvailable ? context.l10n.holdAndSpeakAction : context.l10n.micUnavailableLabel,
          icon: const Icon(Icons.mic_rounded, size: 20, color: Colors.white),
          onTap: sttAvailable ? onStart : null,
        ),
      ],
    );
  }
}

// ────────────────────────────── listening body ──────────────────────────────

class _ListeningBody extends StatelessWidget {
  final Animation<double> anim;
  final String transcript;
  final bool micReady;
  final VoidCallback onStop;

  const _ListeningBody({
    required this.anim,
    required this.transcript,
    required this.micReady,
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
                      child: Icon(Icons.stop_rounded,
                          size: 40, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(micReady ? context.l10n.listeningEllipsisLabel : context.l10n.preparingEllipsisLabel,
              style: AppTextStyles.h2
                  .copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(
              micReady
                  ? context.l10n.tapMicToStopHint
                  : context.l10n.waitBeforeSpeakingHint,
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
                context.l10n.quotedTextLabel(transcript),
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
              context.l10n.quotedTextLabel(transcript),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd
                  .copyWith(fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(
              color: AppColors.primary),
          const SizedBox(height: 16),
          Text(context.l10n.analyzingCommandLabel,
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
  final VoidCallback onRetry;

  const _ResultBody({
    required this.result,
    required this.foodRelation,
    required this.onFoodChanged,
    required this.onConfirm,
    required this.onRetry,
  });

  List<String> _foodOpts(BuildContext context) => [
        context.l10n.foodOptBefore,
        context.l10n.foodOptAfter,
        context.l10n.foodOptNotImportant,
      ];

  List<(String, String)> _parsedRows(BuildContext context) {
    final rows = <(String, String)>[];
    rows.add((context.l10n.actionCapsLabel, _actionLabel(context, result.action)));
    if (result.drugName != null) {
      rows.add((context.l10n.drugCapsLabel, result.drugName!));
    }
    if (result.activityName != null) {
      rows.add((context.l10n.activityCapsLabel, result.activityName!));
    }
    if (result.doseAmount != null) {
      final dose = result.doseAmount!
          .toStringAsFixed(result.doseAmount! % 1 == 0 ? 0 : 1);
      rows.add((context.l10n.doseCapsLabel, '$dose ${result.doseUnit ?? ''}'));
    }
    if (result.scheduleTimes != null &&
        result.scheduleTimes!.isNotEmpty) {
      rows.add((context.l10n.scheduleCapsLabel,
          result.scheduleTimes!.map((s) => _scheduleLabel(context, s)).join(' + ')));
    }
    if (result.appointmentType != null) {
      rows.add((context.l10n.doctorCapsLabel, result.appointmentType!));
    }
    return rows;
  }

  String _actionLabel(BuildContext context, String a) => switch (a) {
        'add_med' => context.l10n.addMedsShortAction,
        'add_activity' => context.l10n.addActivityActionLabel,
        'add_appointment' => context.l10n.newAppointmentTitle,
        _ => context.l10n.unknownCommandLabel,
      };

  String _scheduleLabel(BuildContext context, String s) => switch (s) {
        'morning' => context.l10n.scheduleTimeMorning,
        'evening' => context.l10n.scheduleTimeEvening,
        'afternoon' => context.l10n.scheduleTimeAfternoon,
        'night' => context.l10n.scheduleTimeNight,
        _ => s,
      };

  bool get _showFoodClarification =>
      result.action == 'add_med' && result.foodRelation == null;

  @override
  Widget build(BuildContext context) {
    final rows = _parsedRows(context);

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
              Text(context.l10n.youSaidCapsLabel,
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.primary)),
              const SizedBox(height: 6),
              Text(context.l10n.quotedTextLabel(result.transcript),
                  style: AppTextStyles.bodyMd
                      .copyWith(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.lg),
        Text(context.l10n.iUnderstoodLabel,
            style: AppTextStyles.bodyMd
                .copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 16,
                  offset: Offset(0, 6)),
            ],
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
                const Icon(Icons.bolt_rounded,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.clarifyOneMoreLabel,
                          style: AppTextStyles.labelMd
                              .copyWith(
                                  color: const Color(
                                      0xFF92400E))),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.foodRelationClarifyHint,
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
            children: List.generate(_foodOpts(context).length, (i) {
              final sel = foodRelation == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: i < _foodOpts(context).length - 1 ? 8 : 0),
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
                        _foodOpts(context)[i],
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
        MkButton(label: context.l10n.nextShortAction, onTap: onConfirm),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onRetry,
          child: Text(context.l10n.tryAgainAction,
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
          const Icon(Icons.sentiment_dissatisfied_rounded,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(context.l10n.somethingWentWrongTitle,
              style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 32),
          MkButton(label: context.l10n.tryAgainAction, isFullWidth: false, onTap: onRetry),
        ],
      ),
    );
  }
}
