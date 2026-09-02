import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 앱 마스코트 — 숨쉬는 그라데이션 구체에 윙크하는 얼굴.
///
/// 평소에는 눈 두 개지만 몇 초에 한 번 윙크한다. 이 앱은 사용자가 곤란한
/// 자리에서 빠져나가도록 대신 전화를 걸어주는 공범이고, 윙크가 그 관계를 한
/// 번에 말한다. 다만 계속 감고 있으면 그냥 정지 그림이라, 가끔 한 번씩
/// 지나가야 살아 있어 보인다.
class SoftOrb extends StatefulWidget {
  const SoftOrb({
    super.key,
    this.size = 180,
    this.animate = true,
    this.speaking = false,
    this.showFace = true,
    this.holdingPhone = true,
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

  /// 귀에 스마트폰을 대고 있는 모습으로 그릴지. 앱 아이콘과 같은 구도다.
  /// 전화 앱의 마스코트라는 걸 형태로 보여준다.
  final bool holdingPhone;

  @override
  State<SoftOrb> createState() => _SoftOrbState();
}

/// 오브 지름(D)을 1 로 봤을 때의 배치 값. 앱 아이콘(store/play/src/icon.html)
/// 과 같은 구도라 두 그림이 어긋나지 않는다.
const _kArtWidth = 1.20;      // 폰까지 포함한 전체 폭
const _kPhoneLeft = 0.845;
const _kPhoneTop = 0.182;
const _kPhoneWidth = 0.30;
const _kPhoneHeight = 0.618;
const _kPhoneTilt = 18 * math.pi / 180;

/// 폰이 붙으면 얼굴을 살짝 왼쪽으로 옮긴다 — 가운데 그대로 두면 폰 쪽으로
/// 쏠려 보인다.
const _kFaceShift = -0.073;

class _SoftOrbState extends State<SoftOrb> with TickerProviderStateMixin {
  final math.Random _random = math.Random();

  late final AnimationController _bodyController;
  late final AnimationController _blinkController;
  late final AnimationController _bounceController;
  Timer? _blinkTimer;

  /// 이번에 감는 것이 윙크(오른눈만)인지, 일반 깜빡임(양눈)인지.
  bool _isWink = false;

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
    final delayMs = 3200 + _random.nextInt(1400); // 3.2-4.6s
    _blinkTimer = Timer(Duration(milliseconds: delayMs), _runBlink);
  }

  Future<void> _runBlink() async {
    if (!mounted || !widget.animate) return;
    // 셋 중 두 번은 윙크. 매번 윙크하면 버릇처럼 보이고, 어쩌다 한 번이면
    // 못 보고 지나친다.
    _isWink = _random.nextInt(3) != 0;
    try {
      await _blinkController.forward();
      if (!mounted) return;
      if (_isWink) {
        await Future<void>.delayed(const Duration(milliseconds: 420));
        if (!mounted || !widget.animate) return;
      }
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
    final artWidth =
        widget.size * (widget.holdingPhone ? _kArtWidth : 1.0);
    return RepaintBoundary(
      child: SizedBox(
        width: artWidth,
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

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: widget.size * 0.9 + floatY,
                  left: (widget.size - widget.size * 0.62) / 2,
                  child: _buildShadow(),
                ),
                // 오브와 폰은 한 덩어리로 숨쉬고 떠야 한다 — 따로 움직이면
                // 폰이 귀에서 떨어진다.
                Positioned(
                  left: 0,
                  top: floatY,
                  child: Transform.scale(
                    scale: breathe,
                    child: SizedBox(
                      width: artWidth,
                      height: widget.size,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            child: _buildBody(widget.size),
                          ),
                          if (widget.holdingPhone)
                            Positioned(
                              left: widget.size * _kPhoneLeft,
                              top: widget.size * _kPhoneTop,
                              child: _buildPhone(widget.size),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 귀에 댄 스마트폰. 흰 몸체에 그림자를 줘야 밝은 배경에서도 떠 보인다.
  Widget _buildPhone(double orbSize) {
    final w = orbSize * _kPhoneWidth;
    final h = orbSize * _kPhoneHeight;
    return Transform.rotate(
      angle: _kPhoneTilt,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(w * 0.30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B49B8).withValues(alpha: 0.30),
              blurRadius: orbSize * 0.06,
              offset: Offset(0, orbSize * 0.022),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: w * 0.64,
            height: h * 0.75,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(w * 0.15),
            ),
          ),
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
      child: widget.showFace
          ? Center(
              child: Transform.translate(
                offset: Offset(
                  widget.holdingPhone ? orbSize * _kFaceShift : 0,
                  0,
                ),
                child: _buildFace(orbSize),
              ),
            )
          : null,
    );
  }

  Widget _buildFace(double orbSize) {
    final gap = orbSize * 0.14;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildEye(orbSize, phaseOffset: 0),
        SizedBox(width: gap),
        _buildEye(orbSize, phaseOffset: math.pi / 4, isWinkEye: true),
      ],
    );
  }

  /// 말하는 중일 때 눈이 통통 튀는 정도.
  double _eyeBounce(double orbSize, double phaseOffset) {
    if (!widget.animate || !widget.speaking) return 0;
    return -orbSize *
        0.05 *
        math.sin(_bounceController.value * math.pi + phaseOffset).abs();
  }

  Widget _buildEye(
    double orbSize, {
    required double phaseOffset,
    bool isWinkEye = false,
  }) {
    // 윙크 중이면 감기는 건 윙크하는 눈 하나뿐이다.
    final closing = (_isWink && !isWinkEye) ? 0.0 : _blinkController.value;
    final heightScale = (1.0 - 0.95 * closing).clamp(0.05, 1.0);
    final eyeWidth = orbSize * 0.11;
    final eyeHeight = orbSize * 0.24;
    final bounce = _eyeBounce(orbSize, phaseOffset);

    // 윙크할 때만 감은 눈 호를 띄운다(일반 깜빡임은 눌리기만 한다).
    // 눈과 호가 같은 속도로 겹치면 전환 중간에 둘이 함께 보여 뭉개지므로,
    // 눈이 절반 넘게 감긴 뒤에야 호가 나타나게 타이밍을 어긋낸다.
    final arcOpacity = (isWinkEye && _isWink)
        ? ((closing - 0.45) / 0.55).clamp(0.0, 1.0)
        : 0.0;

    return Transform.translate(
      offset: Offset(0, bounce),
      child: SizedBox(
        width: orbSize * 0.20,
        height: eyeHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: eyeWidth,
              height: eyeHeight * heightScale,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(eyeWidth / 2),
              ),
            ),
            if (arcOpacity > 0)
              Opacity(
                opacity: arcOpacity.clamp(0.0, 1.0),
                child: CustomPaint(
                  size: Size(orbSize * 0.20, eyeHeight),
                  // 너무 납작하면 둥근 끝이 뭉쳐 덩어리로 보이고, 너무
                  // 높으면 갈매기 표시(^)처럼 뾰족해진다. 이 비율이 감은
                  // 눈으로 읽히는 지점.
                  painter: _WinkPainter(
                    strokeWidth: orbSize * 0.062,
                    rise: orbSize * 0.068,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 감은 눈 하나를 그린다. 위로 볼록한 호에 둥근 끝을 붙여, 웃으며 감은
/// 눈처럼 보이게 한다.
class _WinkPainter extends CustomPainter {
  const _WinkPainter({required this.strokeWidth, required this.rise});

  final double strokeWidth;

  /// 호가 가운데에서 위로 솟는 높이.
  final double rise;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final baseY = size.height / 2 + rise / 2;
    // 양 끝을 선 두께만큼 들여 그리면 호의 실제 폭이 그만큼 줄어 가팔라진다.
    // 끝까지 그리고 둥근 끝(strokeCap)이 밖으로 뻗게 둔다.
    final path = Path()
      ..moveTo(0, baseY)
      // 이차 베지어의 정점은 제어점의 절반만큼 올라가므로 rise 의 두 배를 준다.
      ..quadraticBezierTo(size.width / 2, baseY - rise * 2, size.width, baseY);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WinkPainter old) =>
      old.strokeWidth != strokeWidth || old.rise != rise;
}
