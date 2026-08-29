import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A soft, cute gradient "blob" mascot with a simple two-eyed face.
///
/// Replaces the old dark/neon [GlowOrb] for the v3 light-pastel redesign.
/// No wave lines, no neon rings — just a breathing gradient sphere, a soft
/// blurred shadow beneath it, and a friendly blinking face.
class SoftOrb extends StatefulWidget {
  const SoftOrb({
    super.key,
    this.size = 180,
    this.animate = true,
    this.speaking = false,
    this.showFace = true,
  });

  /// Diameter of the orb (the widget itself is slightly taller to make room
  /// for the shadow beneath).
  final double size;

  /// Whether the breathing/float animation (and blinking) runs. When false
  /// the orb renders a static frame.
  final bool animate;

  /// Whether the AI is currently speaking — makes the eyes bounce gently.
  final bool speaking;

  /// Whether to draw the two-eyed face at all.
  final bool showFace;

  @override
  State<SoftOrb> createState() => _SoftOrbState();
}

class _SoftOrbState extends State<SoftOrb> with TickerProviderStateMixin {
  final math.Random _random = math.Random();

  late final AnimationController _bodyController;
  late final AnimationController _blinkController;
  late final AnimationController _bounceController;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _bodyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    if (widget.animate) {
      _bodyController.repeat();
      _scheduleBlink();
    }
    if (widget.animate && widget.speaking) {
      _bounceController.repeat(reverse: true);
    }
  }

  void _scheduleBlink() {
    _blinkTimer?.cancel();
    final delayMs = 4000 + _random.nextInt(1000); // 4-5s
    _blinkTimer = Timer(Duration(milliseconds: delayMs), _runBlink);
  }

  Future<void> _runBlink() async {
    if (!mounted || !widget.animate) return;
    try {
      await _blinkController.forward();
      if (!mounted) return;
      await _blinkController.reverse();
    } on TickerCanceled {
      return;
    }
    if (!mounted || !widget.animate) return;
    _scheduleBlink();
  }

  @override
  void didUpdateWidget(covariant SoftOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _bodyController.repeat();
        _scheduleBlink();
      } else {
        _bodyController.stop();
        _blinkTimer?.cancel();
        _blinkController.stop();
        _blinkController.value = 0;
      }
    }
    if (widget.speaking != oldWidget.speaking ||
        widget.animate != oldWidget.animate) {
      if (widget.animate && widget.speaking) {
        _bounceController.repeat(reverse: true);
      } else {
        _bounceController.stop();
        _bounceController.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _bodyController.dispose();
    _blinkController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extra = widget.size * 0.16;
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size + extra,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _bodyController,
            _blinkController,
            _bounceController,
          ]),
          builder: (context, _) {
            final t = _bodyController.value;
            final breathe = widget.animate
                ? 1.0 + 0.04 * (0.5 + 0.5 * math.sin(t * 2 * math.pi))
                : 1.0;
            final floatY = widget.animate
                ? widget.size * 0.02 * math.sin(t * 2 * math.pi)
                : 0.0;
            final orbSize = widget.size * breathe;

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: widget.size * 0.9 + floatY,
                  child: _buildShadow(),
                ),
                Positioned(
                  top: (widget.size - orbSize) / 2 + floatY,
                  child: _buildBody(orbSize),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildShadow() {
    final w = widget.size * 0.62;
    final h = widget.size * 0.16;
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 6),
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.all(Radius.elliptical(w / 2, h / 2)),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(double orbSize) {
    return Container(
      width: orbSize,
      height: orbSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.4, -0.5),
          radius: 0.95,
          colors: [
            Color(0xFFC4B5FD), // glow highlight, top-left
            Color(0xFF8B7CF6), // accent, core
            Color(0xFF6D5BD0), // deep violet, bottom
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: widget.showFace ? Center(child: _buildFace(orbSize)) : null,
    );
  }

  Widget _buildFace(double orbSize) {
    final gap = orbSize * 0.16;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildEye(orbSize, phaseOffset: 0),
        SizedBox(width: gap),
        _buildEye(orbSize, phaseOffset: math.pi / 4),
      ],
    );
  }

  Widget _buildEye(double orbSize, {required double phaseOffset}) {
    final blink = _blinkController.value;
    final heightScale = (1.0 - 0.85 * blink).clamp(0.15, 1.0);
    final eyeWidth = orbSize * 0.11;
    final eyeHeight = orbSize * 0.24;
    final bounce = widget.animate && widget.speaking
        ? -orbSize *
              0.05 *
              math.sin(_bounceController.value * math.pi + phaseOffset).abs()
        : 0.0;

    return Transform.translate(
      offset: Offset(0, bounce),
      child: Container(
        width: eyeWidth,
        height: eyeHeight * heightScale,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(eyeWidth / 2),
        ),
      ),
    );
  }
}
