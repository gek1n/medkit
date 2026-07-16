import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/widgets/mk_back_button.dart';
import '../../../shared/widgets/mk_button.dart';

enum _Phase { inhale, exhale }

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  static const _totalCycles = 10;

  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  final _audioPlayer = AudioPlayer();
  _Phase _phase = _Phase.inhale;
  int _cyclesLeft = _totalCycles;
  bool _soundOn = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scale = Tween<double>(begin: 0.72, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.addStatusListener(_onStatus);
    _ctrl.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.completed) {
      setState(() => _phase = _Phase.exhale);
      _ctrl.reverse();
    } else if (status == AnimationStatus.dismissed) {
      final next = _cyclesLeft - 1;
      setState(() {
        _phase = _Phase.inhale;
        _cyclesLeft = next.clamp(0, _totalCycles);
      });
      if (next > 0) {
        _ctrl.forward();
      }
    }
  }

  void _restart() {
    setState(() {
      _cyclesLeft = _totalCycles;
      _phase = _Phase.inhale;
    });
    _ctrl.forward(from: 0);
  }

  Future<void> _toggleSound() async {
    final next = !_soundOn;
    setState(() => _soundOn = next);
    if (next) {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(0.3);
      await _audioPlayer.play(AssetSource('audio/pulsar-grey-room.mp3'));
    } else {
      await _audioPlayer.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _cyclesLeft <= 0;
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
                      context.l10n.breathingScreenHeaderLabel,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelLg
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleSound,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _soundOn
                            ? AppColors.primaryLight
                            : AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(
                            color: _soundOn
                                ? AppColors.primary
                                : AppColors.border),
                      ),
                      child: Center(
                        child: Icon(
                          _soundOn
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          size: 18,
                          color: _soundOn
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding),
                child: Column(
                  children: [
                    const SizedBox(height: AppDimensions.lg),
                    Text(context.l10n.breathingExerciseTitle,
                        style: AppTextStyles.h2),
                    const SizedBox(height: 6),
                    Text(
                      done
                          ? context.l10n.breathingDoneBody
                          : context.l10n
                              .breathingCyclesLeftBody(_cyclesLeft),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.textSub),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.12),
                            ),
                          ),
                          GestureDetector(
                            onTap: done ? _restart : null,
                            child: AnimatedBuilder(
                              animation: _scale,
                              builder: (context, child) => Transform.scale(
                                scale: done ? 0.85 : _scale.value,
                                child: child,
                              ),
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryDark,
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    done
                                        ? context.l10n.restartAction
                                        : (_phase == _Phase.inhale
                                            ? context.l10n.inhaleLabel
                                            : context.l10n.exhaleLabel),
                                    style: AppTextStyles.h3
                                        .copyWith(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusLg),
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
                                Text(context.l10n.safeYouTitle,
                                    style: AppTextStyles.h3),
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
                    const SizedBox(height: AppDimensions.xl),
                  ],
                ),
              ),
            ),
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
