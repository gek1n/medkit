import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/mk_back_button.dart';
import '../../../shared/widgets/mk_button.dart';

class _GroundStep {
  final int count;
  final String title;
  final IconData icon;
  final String hint;
  const _GroundStep(this.count, this.title, this.icon, this.hint);
}

const _steps = [
  _GroundStep(5, '5 речей, які ти бачиш', Icons.visibility_rounded,
      'Одна річ, напр. вікно'),
  _GroundStep(4, '4 речі, які можеш відчути на дотик', Icons.touch_app_rounded,
      'Одна річ, напр. тканина светра'),
  _GroundStep(3, '3 звуки, які ти чуєш', Icons.hearing_rounded,
      'Один звук, напр. гудіння холодильника'),
  _GroundStep(2, '2 запахи, які відчуваєш', Icons.local_florist_rounded,
      'Один запах, напр. кава'),
  _GroundStep(1, '1 смак, які відчуваєш', Icons.emoji_food_beverage_rounded,
      "Один смак, напр. м'ята"),
];

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

  int _stepIndex = 0;
  List<String> _items = [];
  bool _completed = false;

  @override
  void initState() {
    super.initState();
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

  _GroundStep get _step => _steps[_stepIndex];

  void _addItem(String raw) {
    final text = raw.trim();
    if (text.isEmpty || _items.length >= _step.count) return;
    setState(() => _items = [..._items, text]);
    _textCtrl.clear();
    if (_items.length >= _step.count) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _advance();
      });
    }
  }

  void _submitTyped() => _addItem(_textCtrl.text);

  void _advance() {
    if (_stepIndex + 1 < _steps.length) {
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
        localeId: 'uk_UA',
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
                        '5-4-3-2-1',
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
                      _steps.length,
                      (i) => Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(
                              right: i < _steps.length - 1 ? 4 : 0),
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
                            step: _step,
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
                          label: 'Інша вправа',
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: MkButton(
                          label: 'Мені краще',
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
          'Назви ${step.title}',
          textAlign: TextAlign.center,
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: 6),
        Text(
          '${items.length} / ${step.count} названо',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
        ),
        const SizedBox(height: 28),
        if (listening)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              liveText.isEmpty ? 'Слухаю…' : liveText,
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
            'Пропустити цей крок',
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
                    Text('Ти в безпеці', style: AppTextStyles.h3),
                    const SizedBox(height: 3),
                    Text(
                      'Тривога мине. Еллі поруч, поки тобі потрібно.',
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
          'Ти повернувся(-лась) у тут-і-зараз',
          textAlign: TextAlign.center,
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: 8),
        Text(
          'Чудова робота. Повертайся до цієї вправи, коли знадобиться.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
        ),
        const SizedBox(height: AppDimensions.xl),
        MkButton(label: 'Готово', onTap: () => Navigator.pop(context)),
      ],
    );
  }
}
