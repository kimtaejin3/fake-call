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
  testWidgets('Home screen shows main CTA', (tester) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: AiFakeCallApp()));
    await settle(tester);

    expect(find.text('30초 후'), findsOneWidget);
  });
}
