import 'package:flutter_test/flutter_test.dart';

import 'package:ai_fake_call/core/services/voice_service.dart';

/// 음성을 끈 상태의 [MockVoiceService] 동작 검증.
///
/// `testWidgets` 를 쓰는 이유: 서비스가 실제 [Timer] 로 대사 간격을 잡는데,
/// 위젯 테스트 바인딩의 가짜 시계라야 `tester.pump` 로 시간을 앞으로 감을 수
/// 있다. 순수 `test` 에서는 30초를 실제로 기다려야 한다.
void main() {
  /// [service] 가 통화 종료 이벤트를 낼 때까지 가짜 시간을 앞으로 감고,
  /// 걸린 시간을 돌려준다.
  Future<Duration> runUntilCallEnded(
    WidgetTester tester,
    List<VoiceEvent> events, {
    Duration cap = const Duration(seconds: 90),
  }) async {
    const step = Duration(milliseconds: 200);
    var elapsed = Duration.zero;
    while (elapsed < cap && !events.any((e) => e.callEnded)) {
      await tester.pump(step);
      elapsed += step;
    }
    return elapsed;
  }

  testWidgets('음성이 꺼져 있으면 마이크를 잡지 않는다', (tester) async {
    final service = MockVoiceService(voiceEnabled: false);
    addTearDown(service.dispose);

    await service.start(scenarioId: 'come_home');
    await tester.pump(const Duration(seconds: 2));

    // 마이크를 잡지 않아야 통화 시작 직후 권한 팝업이 뜨지 않는다.
    expect(service.micInUse, isFalse);

    // 스크립트 중간에 끝나므로 남은 타이머를 본문 안에서 정리한다.
    // (addTearDown 은 프레임워크의 "타이머 미정리" 검사보다 늦게 돈다.)
    await service.stop();
  });

  testWidgets('음성이 꺼져도 대사 이벤트와 자동 종료는 그대로다', (tester) async {
    final service = MockVoiceService(voiceEnabled: false);
    addTearDown(service.dispose);

    final events = <VoiceEvent>[];
    final sub = service.events.listen(events.add);
    addTearDown(sub.cancel);

    await service.start(scenarioId: 'come_home');
    await runUntilCallEnded(tester, events);

    expect(
      events.where((e) => e.message != null).map((e) => e.message).toList(),
      [
        '여보세요? 너 지금 어디야?',
        '아빠가 너 찾고 있어. 조금 일찍 들어와.',
        '응. 좀 빨리 왔으면 좋겠어.',
        '그래. 조심해서 와.',
      ],
    );
    expect(events.last.callEnded, isTrue);
  });

  testWidgets('음성이 꺼져도 통화 길이는 20~40초대를 유지한다', (tester) async {
    // TTS 가 켜져 있으면 발화가 끝나야 speak() 가 반환되므로 대사 길이가
    // 자연스럽게 페이싱을 만든다. 음성을 끄면 그 신호가 사라져 통화가
    // 통째로 짧아지므로, 대사 길이로 발화 시간을 어림잡아 보정한다.
    final service = MockVoiceService(voiceEnabled: false);
    addTearDown(service.dispose);

    final events = <VoiceEvent>[];
    final sub = service.events.listen(events.add);
    addTearDown(sub.cancel);

    await service.start(scenarioId: 'come_home');
    final elapsed = await runUntilCallEnded(tester, events);

    expect(
      elapsed.inSeconds,
      inInclusiveRange(20, 45),
      reason: 'PRD 기준 통화는 20~40초. 실제: ${elapsed.inSeconds}초',
    );
  });

  testWidgets('stop() 이후에는 대사 이벤트가 더 나오지 않는다', (tester) async {
    final service = MockVoiceService(voiceEnabled: false);
    addTearDown(service.dispose);

    final events = <VoiceEvent>[];
    final sub = service.events.listen(events.add);
    addTearDown(sub.cancel);

    await service.start(scenarioId: 'come_home');
    await tester.pump(const Duration(seconds: 1));
    await service.stop();
    final countAtStop = events.length;

    await tester.pump(const Duration(seconds: 30));
    expect(events.length, countAtStop, reason: 'stop() 후 유령 이벤트가 없어야 합니다.');
  });
}
