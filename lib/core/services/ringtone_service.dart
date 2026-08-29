import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Plays the incoming-call ringtone on loop and pulses haptic feedback
/// while a fake call is ringing.
class RingtoneService {
  RingtoneService() : _player = AudioPlayer();

  final AudioPlayer _player;
  Timer? _hapticTimer;
  bool _isPlaying = false;

  /// Starts looping the ringtone and periodic vibration. Safe to call
  /// multiple times; a no-op if already playing.
  Future<void> start() async {
    if (_isPlaying) return;
    _isPlaying = true;

    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('audio/ringtone.wav'));
    } catch (_) {
      // 오디오 재생이 불가능한 환경(테스트 등)에서도 수신 화면은 동작해야 한다.
    }

    HapticFeedback.vibrate();
    _hapticTimer?.cancel();
    _hapticTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      HapticFeedback.vibrate();
    });
  }

  /// Stops the ringtone and vibration.
  Future<void> stop() async {
    _isPlaying = false;
    _hapticTimer?.cancel();
    _hapticTimer = null;
    try {
      await _player.stop();
    } catch (_) {
      // start()와 동일하게 오디오 미지원 환경 보호.
    }
  }

  /// Releases underlying resources. Call when the service is no longer
  /// needed (e.g. provider disposal).
  Future<void> dispose() async {
    _hapticTimer?.cancel();
    _hapticTimer = null;
    await _player.dispose();
  }
}

/// Shared [RingtoneService] instance, disposed automatically with the
/// provider container.
final ringtoneServiceProvider = Provider<RingtoneService>((ref) {
  final service = RingtoneService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});
