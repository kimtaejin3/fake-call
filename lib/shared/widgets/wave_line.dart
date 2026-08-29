import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A horizontal "voice waveform" line, shown while the AI is speaking.
///
/// Three composited sine waves flow continuously. When [active] is true the
/// amplitude is larger and the flow is faster; when false it renders a low,
/// calm line. Colors follow the accent gradient with a fade at both ends.
class VoiceWaveLine extends StatefulWidget {
  const VoiceWaveLine({super.key, this.height = 48, this.active = false});

  /// Overall height of the widget (the wave amplitude scales within it).
  final double height;

  /// Whether the waveform is "speaking" (larger, faster) or idle (small,
  /// calm).
  final bool active;

  @override
  State<VoiceWaveLine> createState() => _VoiceWaveLineState();
}

class _VoiceWaveLineState extends State<VoiceWaveLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
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
        height: widget.height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(width, widget.height),
                  painter: _WaveLinePainter(
                    t: _controller.value,
                    active: widget.active,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _WaveLinePainter extends CustomPainter {
  _WaveLinePainter({required this.t, required this.active});

  final double t;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final speed = active ? 1.8 : 0.6;
    final phase = t * 2 * math.pi * speed;
    final midY = size.height / 2;
    final maxAmp = size.height / 2 * 0.85;
    final amplitude = active ? maxAmp : maxAmp * 0.28;

    final gradient = ui.Gradient.linear(
      Offset.zero,
      Offset(size.width, 0),
      [
        AppColors.glow.withValues(alpha: 0.0),
        AppColors.glow.withValues(alpha: 0.85),
        AppColors.accent.withValues(alpha: 0.9),
        AppColors.accentAlt.withValues(alpha: 0.85),
        AppColors.accentAlt.withValues(alpha: 0.0),
      ],
      const [0.0, 0.15, 0.5, 0.85, 1.0],
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? 2.4 : 1.6
      ..strokeCap = StrokeCap.round
      ..shader = gradient;

    const steps = 96;
    for (var layer = 0; layer < 3; layer++) {
      final layerAmp = amplitude * (1.0 - layer * 0.28);
      final freq = 1.4 + layer * 0.9;
      final layerPhase = phase + layer * (math.pi / 2.3);
      final layerAlpha = 1.0 - layer * 0.32;

      final path = Path();
      for (var i = 0; i <= steps; i++) {
        final fx = i / steps;
        final x = fx * size.width;
        final y = midY +
            layerAmp *
                math.sin(fx * 2 * math.pi * freq + layerPhase) *
                (0.6 + 0.4 * math.sin(fx * math.pi)); // taper near edges
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = paint.strokeWidth * layerAlpha
          ..strokeCap = StrokeCap.round
          ..shader = gradient,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveLinePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.active != active;
  }
}
