import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_fake_call/core/router/app_router.dart';
import 'package:ai_fake_call/core/theme/app_theme.dart';
import 'package:ai_fake_call/shared/widgets/soft_orb.dart';

/// 수신/통화 화면이 실제 iOS·Android 시스템 전화 UI를 따라가는지 검증한다.
///
/// 플랫폼 분기는 `Theme.of(context).platform` 을 보므로, 테스트는 테마에
/// 플랫폼을 직접 주입한다. 전역 `debugDefaultTargetPlatformOverride` 는
/// 테스트 본문이 끝나기 전에 반드시 원복해야 하는데(원복 전에 expect 가
/// 실패하면 프레임워크가 별도 오류를 낸다) 그 제약이 성가시므로 쓰지 않는다.

/// 화면이 자리잡을 만큼만 프레임을 돌린다.
///
/// `pumpAndSettle` 을 쓸 수 없는 이유: 홈의 SoftOrb 마스코트가
/// 계속 숨쉬는 애니메이션을 돌리므로 위젯 트리가 영영 "정착"하지 않는다.
/// 애니메이션을 끄는 대신(그건 제품을 테스트에 맞춰 깎는 것) 테스트가
/// 정해진 시간만 감는다.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  /// 해당 플랫폼으로 고정된 앱. 라우터는 테스트마다 새로 만든다 — 전역
  /// 라우터를 공유하면 앞 테스트가 남긴 현재 경로가 다음 테스트로 샌다.
  Widget appOn(TargetPlatform platform) {
    return ProviderScope(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light.copyWith(platform: platform),
        routerConfig: createAppRouter(),
      ),
    );
  }

  /// 홈 탭 → (지연을 '지금'으로) → 수신 화면까지 이동시킨다.
  ///
  /// 수신/통화 화면에는 반복 애니메이션이 있어 pumpAndSettle 이 끝나지 않으므로
  /// 전환 이후로는 명시적인 pump 를 쓴다.
  Future<void> goToIncoming(
    WidgetTester tester,
    TargetPlatform platform,
  ) async {
    // 실제 폰 크기(iPhone 15 논리 해상도)로 잡아 레이아웃 오버플로가
    // 테스트에서 걸리게 한다.
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(appOn(platform));
    await settle(tester);

    // 기본 지연(30초)이면 카운트다운을 기다려야 하므로 '지금'으로 바꾼다.
    await tester.tap(find.text('30초 후'));
    await settle(tester);
    await tester.tap(find.text('지금'));
    await settle(tester);

    await tester.tap(find.byIcon(Icons.call));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
  }

  /// 수신 화면에서 응답까지 눌러 통화 화면으로 넘어간다.
  Future<void> goToActiveCall(
    WidgetTester tester,
    TargetPlatform platform,
  ) async {
    await goToIncoming(tester, platform);
    await tester.tap(find.byIcon(Icons.call));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
  }

  group('수신 화면', () {
    testWidgets('iOS: 이름 + 회선 라벨 + 알림/메시지 + 거절/응답', (tester) async {
      await goToIncoming(tester, TargetPlatform.iOS);

      expect(find.text('엄마'), findsOneWidget);
      // iOS 는 이름 아래에 회선 종류를 표시한다.
      expect(find.text('휴대전화'), findsOneWidget);
      // 수락/거절 위의 보조 액션 2종.
      expect(find.text('알림'), findsOneWidget);
      expect(find.text('메시지'), findsOneWidget);
      expect(find.text('거절'), findsOneWidget);
      expect(find.text('응답'), findsOneWidget);
    });

    testWidgets('Android: 수신 전화 라벨 + 번호 + 거절/응답', (tester) async {
      await goToIncoming(tester, TargetPlatform.android);

      expect(find.text('엄마'), findsOneWidget);
      expect(find.text('수신 전화'), findsOneWidget);
      // Android 통화 UI 는 이름 아래에 번호를 보여준다.
      expect(find.textContaining('010-'), findsOneWidget);
      expect(find.text('거절'), findsOneWidget);
      expect(find.text('응답'), findsOneWidget);
      // iOS 전용 보조 액션은 없어야 한다.
      expect(find.text('알림'), findsNothing);
    });

    testWidgets('마스코트 오브는 수신 화면에 등장하지 않는다', (tester) async {
      await goToIncoming(tester, TargetPlatform.iOS);

      // 눈 달린 파스텔 오브는 "진짜 전화" 연출을 깨뜨리므로 없어야 한다.
      expect(find.byType(SoftOrb), findsNothing);
    });
  });

  group('통화 중 화면', () {
    testWidgets('iOS: 6버튼 그리드 + 통화시간', (tester) async {
      await goToActiveCall(tester, TargetPlatform.iOS);

      expect(find.text('엄마'), findsOneWidget);
      expect(find.textContaining('00:0'), findsOneWidget);

      for (final label in [
        '음소거',
        '키패드',
        '스피커',
        '통화 추가',
        'FaceTime',
        '연락처',
      ]) {
        expect(find.text(label), findsOneWidget, reason: '$label 버튼이 있어야 합니다.');
      }
      expect(find.byIcon(Icons.call_end), findsOneWidget);
    });

    testWidgets('Android: 보류 포함 6버튼, FaceTime 없음', (tester) async {
      await goToActiveCall(tester, TargetPlatform.android);

      for (final label in [
        '음소거',
        '키패드',
        '스피커',
        '통화 추가',
        '보류',
        '영상 통화',
      ]) {
        expect(find.text(label), findsOneWidget, reason: '$label 버튼이 있어야 합니다.');
      }
      expect(find.text('FaceTime'), findsNothing);
    });

    testWidgets('AI 대사 자막은 표시하지 않는다', (tester) async {
      await goToActiveCall(tester, TargetPlatform.iOS);
      // 스크립트 첫 대사가 방출될 시간을 준다.
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('여보세요? 너 지금 어디야?'), findsNothing);
    });

    testWidgets('키패드 버튼을 누르면 숫자판이 올라온다', (tester) async {
      await goToActiveCall(tester, TargetPlatform.iOS);

      // 라벨이 아니라 원형 버튼이 탭 대상이다(실제 전화 UI 와 동일).
      await tester.tap(find.byIcon(Icons.dialpad));
      await tester.pump(const Duration(milliseconds: 400));

      // 숫자판의 대표 키들.
      for (final key in ['1', '5', '9', '0', '*', '#']) {
        expect(find.text(key), findsWidgets, reason: '$key 키가 있어야 합니다.');
      }
    });
  });

  group('카운트다운 화면', () {
    testWidgets('내용이 화면 가로 가운데에 놓인다', (tester) async {
      // 회귀 방지: Column 은 세로만 꽉 채우고 가로는 가장 넓은 자식에 맞춰
      // 줄어든다. 예전엔 폭 260 덩어리가 왼쪽에 붙어 화면 왼편으로 쏠렸다.
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(appOn(TargetPlatform.iOS));
      await settle(tester);

      // 기본 지연 30초 → 카운트다운 단계.
      await tester.tap(find.byIcon(Icons.call));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('초 후 전화가 옵니다'), findsOneWidget);
      const screenCenterX = 393 / 2;
      for (final label in ['초 후 전화가 옵니다', '취소']) {
        final centerX = tester.getRect(find.text(label)).center.dx;
        expect(
          centerX,
          closeTo(screenCenterX, 1),
          reason: '"$label" 이 가운데($screenCenterX)가 아니라 $centerX 에 있습니다.',
        );
      }
    });
  });
}
