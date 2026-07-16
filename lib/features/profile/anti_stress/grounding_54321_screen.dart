import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/providers/app_language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/widgets/mk_back_button.dart';
import '../../../shared/widgets/mk_button.dart';

class _GroundStep {
  final int count;
  final String title;
  final IconData icon;
  final String hint;
  const _GroundStep(this.count, this.title, this.icon, this.hint);
}

const _stepCounts = [5, 4, 3, 2, 1];
const _stepIcons = [
  Icons.visibility_rounded,
  Icons.touch_app_rounded,
  Icons.hearing_rounded,
  Icons.local_florist_rounded,
  Icons.emoji_food_beverage_rounded,
];

List<_GroundStep> _groundStepsFor(BuildContext context) {
  final l10n = context.l10n;
  final titles = [
    l10n.groundStep5Title,
    l10n.groundStep4Title,
    l10n.groundStep3Title,
    l10n.groundStep2Title,
    l10n.groundStep1Title,
  ];
  final hints = [
    l10n.groundStep5Hint,
    l10n.groundStep4Hint,
    l10n.groundStep3Hint,
    l10n.groundStep2Hint,
    l10n.groundStep1Hint,
  ];
  return [
    for (var i = 0; i < _stepCounts.length; i++)
      _GroundStep(_stepCounts[i], titles[i], _stepIcons[i], hints[i]),
  ];
}

class Grounding54321Screen extends StatefulWidget {
  const Grounding54321Screen({super.key});

  @override
  State<Grounding54321Screen> createState() => _Grounding54321ScreenState();
}

class _Grounding54321ScreenState extends State<Grounding54321Screen> {
  final _speech = SpeechToText();
  final _textCtrl = TextEditingController();
  bool _sttReady = false;
  bool _listening = false;
  String _liveText = '';
  String _languageId = 'uk_UA';

  int _stepIndex = 0;
  List<String> _items = [];
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    AppLanguageNotifier.loadLanguageId().then((id) {
      if (mounted) _languageId = id;
    });
    _speech.initialize().then((ok) {
      if (mounted) setState(() => _sttReady = ok);
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  int get _stepCount => _stepCounts[_stepIndex];

  void _addItem(String raw) {
    final text = raw.trim();
    if (text.isEmpty || _items.length >= _stepCount) return;
    setState(() => _items = [..._items, text]);
    _textCtrl.clear();
    if (_items.length >= _stepCount) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _advance();
      });
    }
  }

  void _submitTyped() => _addItem(_textCtrl.text);

  void _advance() {
    if (_stepIndex + 1 < _stepCounts.length) {
      setState(() {
        _stepIndex++;
        _items = [];
      });
    } else {
      setState(() => _completed = true);
    }
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    if (!_sttReady) return;
    setState(() {
      _listening = true;
      _liveText = '';
    });
    await _speech.listen(
      onResult: (r) {
        if (!mounted) return;
        setState(() => _liveText = r.recognizedWords);
        if (r.finalResult) {
          final text = _liveText;
          setState(() => _listening = false);
          _addItem(text);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: _languageId,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDCEEE2), AppColors.bg],
            stops: [0, 0.55],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPadding,
                  AppDimensions.md,
                  AppDimensions.screenPadding,
                  0,
                ),
                child: Row(
                  children: [
                    MkBackButton(onTap: () => Navigator.pop(context)),
                    Expanded(
                      child: Text(
                        context.l10n.grounding54321Title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelLg
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
              if (!_completed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.screenPadding,
                    AppDimensions.lg,
                    AppDimensions.screenPadding,
                    0,
                  ),
                  child: Row(
                    children: List.generate(
                      _stepCounts.length,
                      (i) => Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(
                              right: i < _stepCounts.length - 1 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: i < _stepIndex
                                ? AppColors.primary
                                : i == _stepIndex
                                    ? AppColors.primary.withValues(alpha: 0.4)
                                    : AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.screenPadding,
                      vertical: AppDimensions.lg),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                                begin: const Offset(0, 0.04),
                                end: Offset.zero)
                            .animate(anim),
                        child: child,
                      ),
                    ),
                    child: _completed
                        ? const _CompletionCard(key: ValueKey('done'))
                        : _StepBody(
                            key: ValueKey(_stepIndex),
                            step: _groundStepsFor(context)[_stepIndex],
                            items: _items,
                            textCtrl: _textCtrl,
                            listening: _listening,
                            liveText: _liveText,
                            onSubmitTyped: _submitTyped,
                            onMicTap: _toggleListening,
                            onSkip: _advance,
                          ),
                  ),
                ),
              ),
              if (!_completed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.screenPadding,
                    0,
                    AppDimensions.screenPadding,
                    AppDimensions.lg,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: MkButton.secondary(
                          label: context.l10n.differentExerciseAction,
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: MkButton(
                          label: context.l10n.feelBetterAction,
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  final _GroundStep step;
  final List<String> items;
  final TextEditingController textCtrl;
  final bool listening;
  final String liveText;
  final VoidCallback onSubmitTyped;
  final VoidCallback onMicTap;
  final VoidCallback onSkip;

  const _StepBody({
    super.key,
    required this.step,
    required this.items,
    required this.textCtrl,
    required this.listening,
    required this.liveText,
    required this.onSubmitTyped,
    required this.onMicTap,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset('assets/illustrations/elly-leaf.png', height: 150),
        const SizedBox(height: AppDimensions.md),
        Text(
          context.l10n.groundingNameStepLabel(step.title),
          textAlign: TextAlign.center,
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.groundingProgressCounter(items.length, step.count),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
        ),
        const SizedBox(height: 28),
        if (listening)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              liveText.isEmpty ? context.l10n.groundingListeningLabel : liveText,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: textCtrl,
                  onSubmitted: (_) => onSubmitTyped(),
                  decoration: InputDecoration(
                    hintText: step.hint,
                    hintStyle: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                  ),
                  style:
                      AppTextStyles.bodyMd.copyWith(color: AppColors.textMain),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: textCtrl,
              builder: (context, value, _) {
                final enabled = value.text.trim().isNotEmpty;
                return GestureDetector(
                  onTap: enabled ? onSubmitTyped : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: enabled ? AppColors.primary : AppColors.border,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 22),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onMicTap,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: listening ? AppColors.danger : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  listening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.lg),
        if (items.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items) _ItemChip(item),
            ],
          ),
        if (items.isNotEmpty) const SizedBox(height: AppDimensions.lg),
        GestureDetector(
          onTap: onSkip,
          child: Text(
            context.l10n.groundingSkipStepAction,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: AppDimensions.xl),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 16,
                  offset: Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/illustrations/elly-care.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.safeYouTitle, style: AppTextStyles.h3),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.safeYouSubtitle,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.textSub),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemChip extends StatelessWidget {
  final String text;
  const _ItemChip(this.text);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child:
            Transform.translate(offset: Offset(0, (1 - t) * 8), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_rounded, size: 14, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(text,
                style: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.primaryDark)),
          ],
        ),
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppDimensions.lg),
        Image.asset('assets/illustrations/elly-care.png', height: 160),
        const SizedBox(height: AppDimensions.lg),
        Text(
          context.l10n.groundingCompletedTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.groundingCompletedSubtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
        ),
        const SizedBox(height: AppDimensions.xl),
        MkButton(label: context.l10n.doneTitle, onTap: () => Navigator.pop(context)),
      ],
    );
  }
}
