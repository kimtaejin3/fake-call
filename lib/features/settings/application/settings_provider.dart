import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences.dart';

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
  RingtoneMode build() {
    final saved = ref.watch(sharedPreferencesProvider)?.getString(
          PrefKeys.ringtoneMode,
        );
    if (saved == null) return RingtoneMode.vibrationOnly;
    // 저장된 값이 옛 버전 것이거나 손상됐을 수 있다 — 못 알아보면 기본값.
    for (final mode in RingtoneMode.values) {
      if (mode.name == saved) return mode;
    }
    return RingtoneMode.vibrationOnly;
  }

  void select(RingtoneMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider)?.setString(
          PrefKeys.ringtoneMode,
          mode.name,
        );
  }
}

/// 현재 벨소리 모드. 기기에 저장되어 앱을 다시 켜도 유지된다.
final ringtoneModeProvider =
    NotifierProvider<RingtoneModeNotifier, RingtoneMode>(
  RingtoneModeNotifier.new,
);
