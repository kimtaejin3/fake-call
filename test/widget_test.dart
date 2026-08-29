import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_fake_call/app.dart';

void main() {
  testWidgets('Home screen shows main CTA', (tester) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: AiFakeCallApp()));
    await tester.pumpAndSettle();

    expect(find.text('전화 받기'), findsOneWidget);
  });
}
