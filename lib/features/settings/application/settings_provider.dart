import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 수신 시 어떻게 알릴지.
enum RingtoneMode {
  /// 벨소리 + 진동.
  soundAndVibration('벨소리 + 진동'),

  /// 진동만. 기본값 — 가짜 통화는 대개 조용해야 하는 자리에서 쓰이고,
  /// 벨소리가 울리면 오히려 시선을 끈다.
  vibrationOnly('진동만'),

  /// 아무 소리도 진동도 없음.
  silent('무음');

  const RingtoneMode(this.label);

  /// 설정 화면에 보여줄 한국어 라벨.
  final String label;

  bool get playsSound => this == RingtoneMode.soundAndVibration;
  bool get vibrates => this != RingtoneMode.silent;
}

class RingtoneModeNotifier extends Notifier<RingtoneMode> {
  @override
  RingtoneMode build() => RingtoneMode.vibrationOnly;

  void select(RingtoneMode mode) => state = mode;
}

/// 현재 벨소리 모드.
///
/// MVP 기준 메모리 보관 — 앱을 다시 켜면 기본값으로 돌아간다. 통화 기록과
/// 같은 정책이며, 영속화는 저장소를 도입할 때 함께 붙인다.
final ringtoneModeProvider =
    NotifierProvider<RingtoneModeNotifier, RingtoneMode>(
  RingtoneModeNotifier.new,
);
