import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_fake_call/core/router/app_router.dart';
import 'package:ai_fake_call/core/theme/app_theme.dart';

/// 홈의 발신자 이름 입력과 설정의 벨소리 선택 검증.

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
  Widget app() {
    return ProviderScope(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light.copyWith(platform: TargetPlatform.iOS),
        routerConfig: createAppRouter(),
      ),
    );
  }

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(app());
    await settle(tester);
  }

  /// 지연을 '지금'으로 바꿔 카운트다운 없이 바로 수신되게 한다.
  Future<void> setDelayToNow(WidgetTester tester) async {
    await tester.tap(find.text('30초 후'));
    await settle(tester);
    await tester.tap(find.text('지금'));
    await settle(tester);
  }

  group('홈 — 발신자 이름', () {
    testWidgets('이름을 직접 입력하면 수신 화면에 그 이름이 뜬다', (tester) async {
      await pumpApp(tester);

      await tester.enterText(find.byType(TextField), '김대리');
      await settle(tester);
      await setDelayToNow(tester);

      await tester.tap(find.byIcon(Icons.call));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('김대리'), findsOneWidget);
    });

    testWidgets('프리셋 이름 칩을 누르면 입력칸이 그 이름으로 채워진다', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.widgetWithText(ActionChip, '아빠'));
      await settle(tester);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, '아빠');
    });

    testWidgets('시나리오 선택 UI는 홈에 없다', (tester) async {
      await pumpApp(tester);

      // 음성을 끈 뒤로 시나리오는 화면에 드러나지 않는다.
      expect(find.text('왜 전화했나요?'), findsNothing);
      expect(find.text('회사에 일이'), findsNothing);
      expect(find.text('엄마가 불러요'), findsNothing);
    });

    testWidgets('이름을 비우면 통화 버튼이 눌리지 않는다', (tester) async {
      await pumpApp(tester);

      await tester.enterText(find.byType(TextField), '');
      await settle(tester);
      await tester.tap(find.byIcon(Icons.call));
      await settle(tester);

      // 수신 화면으로 넘어가지 않고 홈에 남아 있어야 한다.
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('설정 — 벨소리', () {
    Future<void> goToSettings(WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await settle(tester);
    }

    testWidgets('기본값은 진동만', (tester) async {
      await goToSettings(tester);
      expect(find.text('진동만'), findsOneWidget);
    });

    testWidgets('벨소리를 누르면 준비 중 SnackBar 대신 선택지가 뜬다', (tester) async {
      await goToSettings(tester);

      await tester.tap(find.text('벨소리'));
      await settle(tester);

      // 흰 배경에 흰 글씨로 떠서 "정체불명의 흰 UI"로 보이던 그 SnackBar.
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('벨소리 + 진동'), findsOneWidget);
      expect(find.text('무음'), findsOneWidget);
    });

    testWidgets('선택하면 설정 라벨이 바뀐다', (tester) async {
      await goToSettings(tester);

      await tester.tap(find.text('벨소리'));
      await settle(tester);
      await tester.tap(find.text('무음'));
      await settle(tester);

      expect(find.text('무음'), findsOneWidget);
      expect(find.text('진동만'), findsNothing);
    });
  });

  group('설정 — AI 음성', () {
    Future<void> goToSettings(WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await settle(tester);
    }

    testWidgets('아직 나오지 않은 기능이라 출시 예정 배지가 붙는다', (tester) async {
      await goToSettings(tester);

      expect(find.text('AI 음성'), findsOneWidget);
      expect(find.text('출시 예정'), findsOneWidget);
      // 배지가 상태 라벨을 대신하므로 '꺼짐' 을 같이 보여주지 않는다.
      expect(find.text('꺼짐'), findsNothing);
    });

    testWidgets('눌러도 아무 일도 일어나지 않는다', (tester) async {
      await goToSettings(tester);

      await tester.tap(find.text('AI 음성'));
      await settle(tester);

      expect(find.byType(SnackBar), findsNothing);
      // 선택 시트가 뜨지 않아야 한다.
      expect(find.text('전화가 오면'), findsNothing);
    });
  });
}
