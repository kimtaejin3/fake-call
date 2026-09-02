import 'package:flutter/material.dart';

// 수신/통화 화면 전용 디자인 토큰.
//
// 앱의 나머지 화면(홈/기록/설정/완료)은 [AppColors] 의 라이트 파스텔을 쓰지만,
// 이 두 화면만은 실제 시스템 전화 UI 를 흉내내야 하므로 별도의 다크 팔레트를
// 쓴다. 파스텔 통화 화면은 옆 사람 눈에 즉시 "앱"으로 보이기 때문이다.
// (docs/PRD.md — "Incoming/Active Call 화면은 iOS/Android 시스템 전화 UI에서
// 크게 벗어나지 않게")

/// 어느 OS 의 전화 UI 를 흉내낼지.
enum CallStyle { ios, android }

/// 현재 플랫폼에 맞는 [CallStyle] 을 고른다.
///
/// macOS 를 iOS 로 묶는 이유는 데스크톱 실행/위젯 테스트에서도 Cupertino 룩을
/// 보기 위해서다. 그 외(Android/웹/리눅스/윈도우)는 Material 룩으로 떨어진다.
CallStyle callStyleOf(BuildContext context) {
  switch (Theme.of(context).platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return CallStyle.ios;
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return CallStyle.android;
  }
}

/// 한 플랫폼의 통화 화면 색/치수 묶음.
///
/// 화면 코드가 `style == CallStyle.ios ? A : B` 를 곳곳에 뿌리는 대신
/// 팔레트 하나를 받아 쓰도록 해서, 분기를 이 파일 안에 가둔다.
class CallPalette {
  /// 배경 그라데이션(위 → 아래).
  final List<Color> background;

  /// 발신자 이름 등 주 텍스트.
  final Color textPrimary;

  /// 회선 라벨·통화시간 등 보조 텍스트.
  final Color textSecondary;

  /// 수락 버튼.
  final Color accept;

  /// 거절/종료 버튼.
  final Color decline;

  /// 통화 중 컨트롤 버튼의 기본(꺼짐) 배경.
  final Color controlIdle;

  /// 컨트롤 버튼이 켜졌을 때의 배경.
  final Color controlActive;

  /// 컨트롤 버튼이 켜졌을 때의 아이콘 색.
  final Color controlActiveIcon;

  /// 연락처 아바타 원의 배경.
  final Color avatarBackground;

  /// 원형 액션 버튼(수락/거절/종료) 지름.
  final double actionButtonSize;

  /// 통화 중 컨트롤 버튼 지름.
  final double controlButtonSize;

  const CallPalette({
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.accept,
    required this.decline,
    required this.controlIdle,
    required this.controlActive,
    required this.controlActiveIcon,
    required this.avatarBackground,
    required this.actionButtonSize,
    required this.controlButtonSize,
  });

  /// iOS 통화 화면 팔레트 (systemGreen/systemRed + 반투명 흰 컨트롤).
  static const ios = CallPalette(
    background: [Color(0xFF3A3A3C), Color(0xFF1C1C1E)],
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0x99EBEBF5),
    accept: Color(0xFF34C759),
    decline: Color(0xFFFF3B30),
    controlIdle: Color(0x2EFFFFFF),
    controlActive: Color(0xFFFFFFFF),
    controlActiveIcon: Color(0xFF1C1C1E),
    avatarBackground: Color(0xFF636366),
    actionButtonSize: 76,
    controlButtonSize: 74,
  );

  /// Android(구글 다이얼러 다크) 팔레트.
  static const android = CallPalette(
    background: [Color(0xFF202124), Color(0xFF202124)],
    textPrimary: Color(0xFFE8EAED),
    textSecondary: Color(0xFF9AA0A6),
    accept: Color(0xFF34A853),
    decline: Color(0xFFEA4335),
    controlIdle: Color(0x1FFFFFFF),
    controlActive: Color(0xFFE8EAED),
    controlActiveIcon: Color(0xFF202124),
    avatarBackground: Color(0xFF5F6368),
    actionButtonSize: 72,
    controlButtonSize: 72,
  );

  static CallPalette of(BuildContext context) =>
      callStyleOf(context) == CallStyle.ios ? ios : android;
}
