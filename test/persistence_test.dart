import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_fake_call/core/router/app_router.dart';
import 'package:ai_fake_call/core/storage/preferences.dart';
import 'package:ai_fake_call/core/theme/app_theme.dart';

/// 화면이 자리잡을 만큼만 프레임을 돌린다.
///
/// `pumpAndSettle` 을 쓸 수 없는 이유: 홈의 SoftOrb 마스코트가
/// 계속 숨쉬는 애니메이션을 돌리므로 위젯 트리가 영영 "정착"하지 않는다.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// 앱을 껐다 켜도 설정과 마지막 발신자 이름이 남는지 검증한다.
void main() {
  /// 저장된 값을 심어둔 채 앱을 띄운다.
  Future<SharedPreferences> pumpAppWith(
    WidgetTester tester,
    Map<String, Object> stored,
  ) async {
    SharedPreferences.setMockInitialValues(stored);
    final prefs = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light.copyWith(platform: TargetPlatform.iOS),
          routerConfig: createAppRouter(),
        ),
      ),
    );
    await settle(tester);
    return prefs;
  }

  testWidgets('저장된 벨소리 모드를 켤 때 읽어온다', (tester) async {
    await pumpAppWith(tester, {PrefKeys.ringtoneMode: 'silent'});

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await settle(tester);

    expect(find.text('무음'), findsOneWidget);
    expect(find.text('진동만'), findsNothing);
  });

  testWidgets('벨소리 모드를 바꾸면 저장된다', (tester) async {
    final prefs = await pumpAppWith(tester, {});

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await settle(tester);
    await tester.tap(find.text('벨소리'));
    await settle(tester);
    await tester.tap(find.text('벨소리 + 진동'));
    await settle(tester);

    expect(prefs.getString(PrefKeys.ringtoneMode), 'soundAndVibration');
  });

  testWidgets('저장된 값이 없으면 기본값(진동만)을 쓴다', (tester) async {
    await pumpAppWith(tester, {});

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await settle(tester);

    expect(find.text('진동만'), findsOneWidget);
  });

  testWidgets('저장된 값이 망가져 있어도 기본값으로 버틴다', (tester) async {
    // 예전 버전이 쓴 값이거나 손상된 값 — 앱이 죽으면 안 된다.
    await pumpAppWith(tester, {PrefKeys.ringtoneMode: 'not_a_real_mode'});

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await settle(tester);

    expect(find.text('진동만'), findsOneWidget);
  });

  testWidgets('마지막에 전화한 이름을 켤 때 이름칸에 채운다', (tester) async {
    await pumpAppWith(tester, {PrefKeys.lastCallerName: '김대리'});

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '김대리');
  });

  testWidgets('전화를 걸면 그 이름이 저장된다', (tester) async {
    final prefs = await pumpAppWith(tester, {});

    await tester.enterText(find.byType(TextField), '박팀장');
    await settle(tester);
    await tester.tap(find.byIcon(Icons.call));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));

    expect(prefs.getString(PrefKeys.lastCallerName), '박팀장');
  });

  testWidgets('저장해 둔 이름 태그를 켤 때 읽어온다', (tester) async {
    await pumpAppWith(tester, {
      PrefKeys.callerTags: ['김대리', '박팀장'],
    });

    expect(find.widgetWithText(ActionChip, '김대리'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '박팀장'), findsOneWidget);
    // 기본값은 저장된 값이 있으면 쓰지 않는다.
    expect(find.widgetWithText(ActionChip, '엄마'), findsNothing);
  });

  testWidgets('기본 태그에는 관계를 가리키는 말이 없다', (tester) async {
    await pumpAppWith(tester, {});

    // 연락처에 저장해 둘 이름만 남긴다. "직장 상사" 가 수신 화면에 뜨면
    // 그 자체로 가짜라는 표시가 된다.
    for (final name in ['엄마', '아빠']) {
      expect(find.widgetWithText(ActionChip, name), findsOneWidget);
    }
    for (final name in ['친구', '직장 상사', '연인']) {
      expect(find.widgetWithText(ActionChip, name), findsNothing);
    }
  });

  testWidgets('입력한 이름을 태그로 저장하면 기기에 남는다', (tester) async {
    final prefs = await pumpAppWith(tester, {});

    await tester.enterText(find.byType(TextField), '박선배');
    await settle(tester);

    // 저장되지 않은 이름일 때만 '저장' 칩이 뜬다.
    await tester.tap(find.widgetWithText(ActionChip, '저장'));
    await settle(tester);

    expect(prefs.getStringList(PrefKeys.callerTags), contains('박선배'));
    expect(find.widgetWithText(ActionChip, '박선배'), findsOneWidget);
    // 이미 저장했으니 '저장' 칩은 사라진다.
    expect(find.widgetWithText(ActionChip, '저장'), findsNothing);
  });

  testWidgets('태그를 길게 눌러 삭제한다', (tester) async {
    final prefs = await pumpAppWith(tester, {
      PrefKeys.callerTags: ['엄마', '김대리'],
    });

    await tester.longPress(find.widgetWithText(ActionChip, '김대리'));
    await settle(tester);
    await tester.tap(find.text('삭제'));
    await settle(tester);

    expect(prefs.getStringList(PrefKeys.callerTags), ['엄마']);
    expect(find.widgetWithText(ActionChip, '김대리'), findsNothing);
  });
}
