import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_fake_call/app.dart';

/// 화면이 자리잡을 만큼만 프레임을 돌린다.
///
/// `pumpAndSettle` 을 쓸 수 없는 이유: 홈/완료/기록의 SoftOrb 마스코트가
/// 계속 숨쉬는 애니메이션을 돌리므로 위젯 트리가 영영 "정착"하지 않는다.
/// 애니메이션을 끄는 대신(그건 제품을 테스트에 맞춰 깎는 것) 테스트가
/// 정해진 시간만 감는다.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('전체 가짜통화 플로우: 홈 탭 → 수신 → 통화 → 피드백 → 홈',
      (tester) async {
    // 홈 탭은 스크롤 가능한 한 화면 구성이라 기본 800x600 테스트 표면에서는
    // 하단 섹션(딜레이 칩/CTA)이 뷰포트 밖에 놓인다. 실제 폰 화면 크기에
    // 가깝게 표면을 키워 스크롤 없이 모든 섹션을 바로 찾을 수 있게 한다.
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const ProviderScope(child: AiFakeCallApp()));
    await settle(tester);

    // 홈 탭: 기본 선택(엄마가 불러요 프리셋 / 30초 후)이 미리 채워져 있어
    // 시간 pill이 "30초 후"로 표시된다.
    expect(find.text('30초 후'), findsOneWidget);

    // 기본 delay(30초)는 대기 카운트다운을 유발하므로, 테스트에서는 시간 pill을
    // 눌러 바텀시트에서 '지금'을 먼저 선택해 즉시 수신되도록 한다.
    await tester.tap(find.text('30초 후'));
    await settle(tester);
    await tester.tap(find.text('지금'));
    await settle(tester);

    // 통화 버튼(Icons.call) → 수신 화면 (pulse 애니메이션이 반복되므로
    // pumpAndSettle 금지). 이 시점에는 화면 전환 전이라 Icons.call이 유일하다.
    await tester.tap(find.byIcon(Icons.call));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('엄마'), findsOneWidget);
    expect(find.byIcon(Icons.call), findsOneWidget);
    expect(find.byIcon(Icons.call_end), findsOneWidget);

    // 응답 → 통화 화면
    await tester.tap(find.byIcon(Icons.call));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('엄마'), findsOneWidget);

    // 통화 시간이 흐르는지 확인 (00:0X 형식)
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('00:0'), findsOneWidget);

    // 통화 종료 → 피드백 화면
    await tester.tap(find.byIcon(Icons.call_end));
    await tester.pump(const Duration(milliseconds: 300));
    await settle(tester);
    expect(find.text('통화가 종료되었습니다.'), findsOneWidget);

    // 피드백 선택 후 완료 → 홈 복귀
    await tester.tap(find.textContaining('도움이 됐어요'));
    await tester.pump();
    await tester.tap(find.text('완료'));
    await settle(tester);

    // 홈 탭으로 복귀 + 하단 네비게이션(NavigationBar 또는 BottomNavigationBar) 확인
    // (call_complete_screen에서 callSetupProvider가 reset되므로 홈의
    // postFrameCallback이 다시 기본값을 채워 시간 pill이 "30초 후"로 보인다)
    expect(find.text('30초 후'), findsOneWidget);
    final hasNavigationBar = find.byType(NavigationBar).evaluate().isNotEmpty;
    final hasBottomNavigationBar =
        find.byType(BottomNavigationBar).evaluate().isNotEmpty;
    expect(
      hasNavigationBar || hasBottomNavigationBar,
      isTrue,
      reason: '하단 네비게이션 바(NavigationBar 또는 BottomNavigationBar)가 있어야 합니다.',
    );
  });
}
