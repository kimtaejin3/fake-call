import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_fake_call/app.dart';

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
    await tester.pumpAndSettle();

    // 홈 탭: 기본 선택(엄마 / 집에 들어오라고 해줘 / 30초 후)이 미리 채워져 있어
    // 바로 '전화 받기'를 누를 수 있다.
    expect(find.text('전화 받기'), findsOneWidget);

    // 기본 delay(30초)는 대기 카운트다운을 유발하므로, 테스트에서는 '지금' 칩을
    // 먼저 선택해 즉시 수신되도록 한다.
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();

    // '전화 받기' → 수신 화면 (pulse 애니메이션이 반복되므로 pumpAndSettle 금지)
    await tester.tap(find.text('전화 받기'));
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
    await tester.pumpAndSettle();
    expect(find.text('통화가 종료되었습니다.'), findsOneWidget);

    // 피드백 선택 후 완료 → 홈 복귀
    await tester.tap(find.textContaining('도움이 됐어요'));
    await tester.pump();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    // 홈 탭으로 복귀 + 하단 네비게이션(NavigationBar 또는 BottomNavigationBar) 확인
    expect(find.text('전화 받기'), findsOneWidget);
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
