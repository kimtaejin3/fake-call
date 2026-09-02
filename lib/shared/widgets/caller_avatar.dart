import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// [CallerAvatar] 가 그려질 화면의 톤.
enum CallerAvatarVariant {
  /// 앱 화면(기록 탭 등)용 라이트 파스텔 아바타.
  app,

  /// 수신/통화 화면용 다크 아바타. 실제 전화 앱의 연락처 원처럼
  /// 채도 없는 회색 원에 흰 이니셜만 얹는다.
  call,
}

/// 발신자 이름의 첫 글자를 보여주는 원형 아바타.
///
/// 이모지 아바타를 대체한다 — 이모지는 이모지 폰트가 없는 웹/데스크톱에서
/// 두부(□) 글리프로 깨지고, 앱이 노리는 톤보다 장난스럽게 읽힌다.
class CallerAvatar extends StatelessWidget {
  const CallerAvatar({
    super.key,
    required this.name,
    this.size = 96,
    this.variant = CallerAvatarVariant.app,
  });

  /// 표시 이름 전체. 첫 글자만 그려진다.
  final String name;

  /// 원의 지름.
  final double size;

  /// 그려질 화면의 톤.
  final CallerAvatarVariant variant;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    // `[0]` 대신 `runes` 를 쓰는 이유: 서로게이트 페어 코드포인트가 반으로
    // 잘리지 않게 하기 위해서다. 새 패키지 없이 확보할 수 있는 수준의
    // 자소 안전성.
    final initial =
        trimmed.isNotEmpty ? String.fromCharCode(trimmed.runes.first) : '?';
    final isCall = variant == CallerAvatarVariant.call;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCall ? const Color(0xFF636366) : null,
        border: isCall
            ? null
            : Border.all(color: AppColors.surfaceBorder),
        gradient: isCall
            ? null
            : RadialGradient(
                colors: [
                  for (final color in AppColors.accentGradient)
                    color.withValues(alpha: 0.20),
                ],
              ),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: isCall ? Colors.white : AppColors.accent,
          fontSize: size * 0.42,
          fontWeight: isCall ? FontWeight.w500 : FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
