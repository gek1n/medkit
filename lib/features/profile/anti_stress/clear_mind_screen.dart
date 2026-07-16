import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/widgets/mk_back_button.dart';
import '../../../shared/widgets/mk_button.dart';

class ClearMindScreen extends StatefulWidget {
  const ClearMindScreen({super.key});

  @override
  State<ClearMindScreen> createState() => _ClearMindScreenState();
}

class _FogHole {
  final Offset pos;
  final int bornAtMs;
  const _FogHole(this.pos, this.bornAtMs);
}

class _ClearMindScreenState extends State<ClearMindScreen>
    with SingleTickerProviderStateMixin {
  static const _holdMs = 1100;
  static const _regrowMs = 3200;
  static const _holeRadius = 46.0;
  static const _minPointDist = 16.0;
  static const _minHapticGapMs = 90;

  late final Ticker _ticker;
  final _audioPlayer = AudioPlayer();
  int _nowMs = 0;
  final List<_FogHole> _holes = [];
  Offset? _lastAdded;
  int _lastHapticMs = -1000;
  bool _touched = false;
  bool _soundOn = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _nowMs = elapsed.inMilliseconds;
      _holes.removeWhere(
          (h) => _nowMs - h.bornAtMs > _holdMs + _regrowMs);
      setState(() {});
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _audioPlayer.dispose();
    super.dispose();
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

  void _addPoint(Offset p) {
    if (_lastAdded != null && (p - _lastAdded!).distance < _minPointDist) {
      return;
    }
    _lastAdded = p;
    _holes.add(_FogHole(p, _nowMs));
    if (_nowMs - _lastHapticMs >= _minHapticGapMs) {
      _lastHapticMs = _nowMs;
      HapticFeedback.selectionClick();
    }
    if (!_touched) setState(() => _touched = true);
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
                        context.l10n.clearMindTitle,
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
              const SizedBox(height: AppDimensions.md),
              Text(context.l10n.clearMindHeading, style: AppTextStyles.h2),
              const SizedBox(height: 6),
              Text(
                context.l10n.clearMindInstructions,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.screenPadding),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/illustrations/elly-leaf.png',
                          fit: BoxFit.cover,
                        ),
                        GestureDetector(
                          onPanStart: (d) => _addPoint(d.localPosition),
                          onPanUpdate: (d) => _addPoint(d.localPosition),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _FogPainter(holes: _holes, nowMs: _nowMs),
                          ),
                        ),
                        if (!_touched)
                          IgnorePointer(
                            child: Center(
                              child: Text(
                                context.l10n.clearMindTouchHint,
                                style: AppTextStyles.bodyMd.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPadding,
                  0,
                  AppDimensions.screenPadding,
                  AppDimensions.md,
                ),
                child: Container(
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

class _FogPainter extends CustomPainter {
  final List<_FogHole> holes;
  final int nowMs;
  const _FogPainter({required this.holes, required this.nowMs});

  static double _clearStrength(_FogHole h, int nowMs) {
    final age = nowMs - h.bornAtMs;
    if (age <= _ClearMindScreenState._holdMs) return 1.0;
    final t = ((age - _ClearMindScreenState._holdMs) /
            _ClearMindScreenState._regrowMs)
        .clamp(0.0, 1.0);
    return 1.0 - Curves.easeInOut.transform(t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(
      rect,
      Paint()..color = const Color(0xFFEFEAE0).withValues(alpha: 0.94),
    );
    for (final h in holes) {
      final strength = _clearStrength(h, nowMs);
      if (strength <= 0) continue;
      canvas.drawCircle(
        h.pos,
        _ClearMindScreenState._holeRadius,
        Paint()
          ..color = Colors.black.withValues(alpha: strength)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22)
          ..blendMode = BlendMode.dstOut,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FogPainter oldDelegate) => true;
}
