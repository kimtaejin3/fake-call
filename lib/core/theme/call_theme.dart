import 'package:flutter/material.dart';

// 수신/통화 화면 전용 디자인 토큰.
//
// 앱의 나머지 화면(홈/설정)은 [AppColors] 의 라이트 파스텔을 쓰지만,
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

  /// 원형 버튼 가장자리의 얇은 테두리. iOS 는 반투명 흰 테두리가 버튼을
  /// 배경에서 살짝 띄워 준다. 투명이면 테두리를 그리지 않는다.
  final Color controlBorder;

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
    required this.textPrimary,
    required this.textSecondary,
    required this.accept,
    required this.decline,
    required this.controlIdle,
    required this.controlBorder,
    required this.controlActive,
    required this.controlActiveIcon,
    required this.avatarBackground,
    required this.actionButtonSize,
    required this.controlButtonSize,
  });

  /// iOS 통화 화면 팔레트. 실제 아이폰 캡쳐에서 뽑은 값이다 — 배경 위에
  /// 얹히는 버튼이라 원색보다 한 톤 가라앉은 빨강/초록을 쓰고, 컨트롤은
  /// 반투명 흰 원에 얇은 흰 테두리를 두른다.
  static const ios = CallPalette(
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0x8CFFFFFF),
    accept: Color(0xFF3D8B3D),
    decline: Color(0xFFBE2C24),
    controlIdle: Color(0x24FFFFFF),
    controlBorder: Color(0x66FFFFFF),
    controlActive: Color(0xFFFAEEFA),
    controlActiveIcon: Color(0xFF000000),
    avatarBackground: Color(0xFF636366),
    actionButtonSize: 78,
    controlButtonSize: 78,
  );

  /// Android(구글 다이얼러 다크) 팔레트.
  static const android = CallPalette(
    textPrimary: Color(0xFFE8EAED),
    textSecondary: Color(0xFF9AA0A6),
    accept: Color(0xFF34A853),
    decline: Color(0xFFEA4335),
    controlIdle: Color(0x1FFFFFFF),
    controlBorder: Color(0x00000000),
    controlActive: Color(0xFFE8EAED),
    controlActiveIcon: Color(0xFF202124),
    avatarBackground: Color(0xFF5F6368),
    actionButtonSize: 72,
    controlButtonSize: 72,
  );

  static CallPalette of(BuildContext context) =>
      callStyleOf(context) == CallStyle.ios ? ios : android;
}

/// 통화 화면 배경.
///
/// 아이폰의 통화 화면은 설정된 배경화면 색을 따라 그라데이션이 바뀐다. 앱이
/// 사용자의 배경화면을 읽을 수는 없으므로, 자기 폰 배경과 비슷한 톤을 직접
/// 고르게 한다. 색은 왼쪽 위 → 오른쪽 아래 대각선 순서다.
enum CallBackground {
  /// 기본값. 실제 아이폰 캡쳐의 보라 배경.
  purple('보라', [
    Color(0xFF8C5079),
    Color(0xFF734689),
    Color(0xFF45388C),
    Color(0xFF2B2766),
  ]),
  blue('파랑', [
    Color(0xFF4F75A8),
    Color(0xFF3D5C9C),
    Color(0xFF263A78),
    Color(0xFF17204A),
  ]),
  green('초록', [
    Color(0xFF5E8C70),
    Color(0xFF417467),
    Color(0xFF285650),
    Color(0xFF173634),
  ]),
  sunset('노을', [
    Color(0xFFC27C63),
    Color(0xFFA6596F),
    Color(0xFF6B3D70),
    Color(0xFF3A2548),
  ]),
  pink('핑크', [
    Color(0xFFC57FA2),
    Color(0xFFA36198),
    Color(0xFF6D4889),
    Color(0xFF3E2F60),
  ]),

  /// 배경화면이 어두운 사람용. 예전 기본값이던 시스템 다크 톤.
  dark('다크', [
    Color(0xFF3A3A3C),
    Color(0xFF2C2C2E),
    Color(0xFF1F1F21),
    Color(0xFF1C1C1E),
  ]);

  const CallBackground(this.label, this.colors);

  /// 설정 화면에 보여줄 한국어 라벨.
  final String label;

  /// 대각선 그라데이션 색(왼쪽 위 → 오른쪽 아래).
  final List<Color> colors;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      );
}

/// 통화 화면 전체를 덮는 배경.
///
/// 대각선 그라데이션 위에 아래로 갈수록 살짝 어두워지는 막을 한 겹 더 얹는다.
/// 실제 아이폰 화면도 아래쪽이 가라앉아 있어 하단 버튼 라벨이 잘 읽힌다.
class CallBackgroundView extends StatelessWidget {
  const CallBackgroundView({
    super.key,
    required this.background,
    required this.child,
  });

  final CallBackground background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: background.gradient),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.45, 1],
            colors: [Color(0x00000000), Color(0x33000000)],
          ),
        ),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}
