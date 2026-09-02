import 'package:flutter/material.dart';

import '../../core/theme/call_theme.dart';

/// 수락/거절/종료용 큰 원형 버튼 + 아래 라벨.
///
/// 시스템 전화 UI 의 그 버튼들 — 색이 곧 의미이므로 [color] 를 직접 받는다.
class CallActionButton extends StatelessWidget {
  const CallActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.size,
    required this.labelColor,
    required this.onTap,
    this.rotateIcon = false,
  });

  final IconData icon;
  final Color color;

  /// 버튼 아래 캡션. 빈 문자열이면 라벨을 그리지 않는다.
  final String label;
  final double size;
  final Color labelColor;
  final VoidCallback onTap;

  /// 종료 아이콘을 135도 돌려 실제 전화 UI 의 "내려놓은 수화기" 각도로 맞춘다.
  final bool rotateIcon;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, color: Colors.white, size: size * 0.44);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(
                child: rotateIcon
                    ? Transform.rotate(angle: 2.356, child: glyph)
                    : glyph,
              ),
            ),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}

/// 통화 중 화면 그리드의 컨트롤 버튼 (음소거/키패드/스피커...).
///
/// [active] 가 true 면 실제 전화 앱처럼 배경이 반전된다. 동작하지 않는
/// 장식용 버튼([enabled] == false)도 눌리는 느낌은 나야 진짜처럼 보이므로
/// 잉크 반응은 남기고 상태만 바뀌지 않는다.
class CallControlButton extends StatelessWidget {
  const CallControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final CallPalette palette;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final size = palette.controlButtonSize;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Material(
            color: active ? palette.controlActive : palette.controlIdle,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Icon(
                icon,
                size: size * 0.4,
                color: active ? palette.controlActiveIcon : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: size + 16,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
