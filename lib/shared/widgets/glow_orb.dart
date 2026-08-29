import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A glowing, breathing "AI voice" orb.
///
/// Draws several soft blurred glow layers plus a handful of animated sine
/// waves clipped inside a circle, giving an "energy wave" impression. Pure
/// [CustomPainter] + [AnimationController] — no external packages.
class GlowOrb extends StatefulWidget {
  const GlowOrb({
    super.key,
    this.size = 180,
    this.animate = true,
    this.intensity = 1.0,
    this.child,
  });

  /// Diameter of the orb.
  final double size;

  /// Whether the breathing / flowing-wave animation runs. When false the
  /// orb renders a static frame.
  final bool animate;

  /// Glow intensity multiplier, roughly 0.0 - 1.5. Multiplies glow radius
  /// and opacity (e.g. bump to ~1.2 while the AI is speaking).
  final double intensity;

  /// Optional widget layered centered on top of the orb.
  final Widget? child;

  @override
  State<GlowOrb> createState() => _GlowOrbState();
}

class _GlowOrbState extends State<GlowOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant GlowOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.square(widget.size),
                  painter: _GlowOrbPainter(
                    t: _controller.value,
                    intensity: widget.intensity.clamp(0.0, 1.5),
                    animate: widget.animate,
                  ),
                );
              },
            ),
            if (widget.child != null) Center(child: widget.child),
          ],
        ),
      ),
    );
  }
}

class _GlowOrbPainter extends CustomPainter {
  _GlowOrbPainter({
    required this.t,
    required this.intensity,
    required this.animate,
  });

  final double t;
  final double intensity;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    // Breathing scale: 1.0 - 1.05 over the animation cycle.
    final breathe = animate ? 1.0 + 0.05 * (0.5 + 0.5 * math.sin(t * 2 * math.pi)) : 1.0;
    final coreRadius = radius * 0.62;

    // --- Outer soft glow layers ---
    final glowColors = [
      AppColors.glow,
      AppColors.accent,
      AppColors.accentAlt,
    ];
    for (var i = 0; i < 3; i++) {
      final layerRadius = radius * (1.0 - i * 0.18) * breathe;
      final paint = Paint()
        ..color = glowColors[i].withValues(alpha: (0.16 - i * 0.03) * intensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * (0.5 - i * 0.08));
      canvas.drawCircle(center, layerRadius, paint);
    }

    // --- Core disc with subtle radial-ish shading ---
    final corePaint = Paint()
      ..shader = ui.Gradient.linear(
        center - Offset(coreRadius, coreRadius),
        center + Offset(coreRadius, coreRadius),
        [
          AppColors.glow.withValues(alpha: 0.22 * intensity),
          AppColors.accent.withValues(alpha: 0.30 * intensity),
          AppColors.accentAlt.withValues(alpha: 0.22 * intensity),
        ],
        const [0.0, 0.5, 1.0],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, coreRadius * breathe, corePaint);

    // --- Thin border ring ---
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = ui.Gradient.sweep(
        center,
        [
          AppColors.glow.withValues(alpha: 0.6 * intensity),
          AppColors.accent.withValues(alpha: 0.6 * intensity),
          AppColors.accentAlt.withValues(alpha: 0.6 * intensity),
          AppColors.glow.withValues(alpha: 0.6 * intensity),
        ],
        const [0.0, 0.33, 0.66, 1.0],
        TileMode.clamp,
        animate ? t * 2 * math.pi : 0,
      );
    canvas.drawCircle(center, coreRadius * breathe, ringPaint);

    // --- Wave lines clipped inside the core circle ---
    canvas.save();
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: coreRadius * breathe));
    canvas.clipPath(clipPath);

    final waveColors = [
      AppColors.glow,
      AppColors.accent,
      AppColors.accentAlt,
    ];
    for (var w = 0; w < 3; w++) {
      final phase = (animate ? t : 0.0) * 2 * math.pi + w * (math.pi * 2 / 3);
      final amplitude = coreRadius * (0.16 - w * 0.03) * intensity;
      final yOffset = center.dy + (w - 1) * coreRadius * 0.28;

      final path = Path();
      const steps = 48;
      final left = center.dx - coreRadius;
      final width = coreRadius * 2;
      for (var i = 0; i <= steps; i++) {
        final fx = i / steps;
        final x = left + fx * width;
        final y = yOffset +
            amplitude * math.sin(fx * 2 * math.pi * 1.6 + phase) +
            amplitude * 0.4 * math.sin(fx * 2 * math.pi * 3.1 - phase * 1.3);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final wavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = waveColors[w].withValues(alpha: (0.55 - w * 0.1) * intensity);
      canvas.drawPath(path, wavePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlowOrbPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.intensity != intensity ||
        oldDelegate.animate != animate;
  }
}
