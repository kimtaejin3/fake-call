import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_fake_call/core/router/app_router.dart';
import 'package:ai_fake_call/core/storage/preferences.dart';
import 'package:ai_fake_call/core/theme/app_theme.dart';

/// 화면이 자리잡을 만큼만 프레임을 돌린다.
///
/// `pumpAndSettle` 을 쓸 수 없는 이유: 홈/완료/기록의 SoftOrb 마스코트가
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
}
