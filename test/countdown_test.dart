import 'package:flutter_test/flutter_test.dart';

import 'package:ai_fake_call/features/fake_call/presentation/incoming_call_screen.dart';

/// 카운트다운이 벽시계 기준인지 검증한다.
///
/// 앱이 백그라운드로 내려가면 OS 가 Timer 를 멈춘다. 틱마다 1 씩 빼는 방식이면
/// 그동안 흐른 시간이 사라져, 30초를 걸어두고 다른 앱을 보다 돌아와도 여전히
/// 30초가 남는다. 마감시각과 현재 시각의 차이로 계산하면 자는 동안 흐른
/// 시간도 그대로 반영된다.
void main() {
  final now = DateTime(2026, 9, 3, 12, 0, 0);

  test('남은 시간은 마감시각과의 차이로 계산된다', () {
    expect(remainingSecondsUntil(now.add(const Duration(seconds: 30)), now), 30);
    expect(remainingSecondsUntil(now.add(const Duration(seconds: 1)), now), 1);
  });

  test('백그라운드에 있던 시간만큼 줄어 있다', () {
    final ringAt = now.add(const Duration(seconds: 30));
    // 25초 동안 앱이 잠들어 있었다면 돌아왔을 때 5초 남아야 한다.
    final afterSleep = now.add(const Duration(seconds: 25));
    expect(remainingSecondsUntil(ringAt, afterSleep), 5);
  });

  test('이미 지난 마감시각은 0 이다 — 음수로 내려가지 않는다', () {
    final ringAt = now.add(const Duration(seconds: 10));
    // 자는 동안 마감시각을 한참 넘겼다.
    expect(remainingSecondsUntil(ringAt, now.add(const Duration(minutes: 5))), 0);
    expect(remainingSecondsUntil(ringAt, ringAt), 0);
  });

  test('1초가 안 남았어도 0 으로 떨어지기 전까진 1 로 보인다', () {
    // 올림이라 "0초 후 전화가 옵니다" 가 잠깐 보이는 일이 없다.
    final ringAt = now.add(const Duration(milliseconds: 200));
    expect(remainingSecondsUntil(ringAt, now), 1);
  });
}
