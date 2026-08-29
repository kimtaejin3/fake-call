import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';

// ---------------------------------------------------------------------------
// Tunable constants
// ---------------------------------------------------------------------------
//
// [_pollInterval] — how often we sample microphone amplitude while a call
// is active. 150-200ms is frequent enough to catch the start of speech
// quickly (for barge-in) without hammering the platform channel.
//
// [_speechThresholdDb] — dBFS level above which the mic signal is treated
// as the user speaking, used while the AI is silent (normal case).
//
// [_speechThresholdDbWhileAiSpeaking] — a deliberately *higher* (louder)
// threshold used while the AI is actively speaking through the phone's
// speaker. Speaker output commonly leaks back into the microphone
// (acoustic echo/feedback), and without compensation that leakage alone
// can cross [_speechThresholdDb] and be misread as the user talking. We
// don't want to simply ignore the mic while the AI talks though, because
// the user should still be able to interrupt (barge-in) — so instead we
// raise the bar: only a clearly louder signal (i.e. the user actually
// talking over the AI, not just echo) counts as speech during AI playback.
//
// [_silenceHoldDuration] — hysteresis for the speaking -> not-speaking
// transition. The amplitude signal dips below threshold constantly during
// natural pauses between words/syllables; requiring the signal to stay
// below threshold for this long before declaring "done talking" avoids
// treating every micro-pause as end-of-turn.
const _pollInterval = Duration(milliseconds: 180);
const _speechThresholdDb = -25.0;
const _speechThresholdDbWhileAiSpeaking = -18.0;
const _silenceHoldDuration = Duration(milliseconds: 1000);

/// Detects whether the user is currently speaking, by polling microphone
/// amplitude at a fixed interval and applying a dBFS threshold (with
/// hysteresis on the "stopped speaking" edge).
///
/// Used to drive voice-call turn-taking: [MockVoiceService] barges in
/// (stops TTS) when this reports speech starting, and waits for this to
/// report silence before speaking its next line.
///
/// Every platform call here is wrapped in try/catch. Permission denial,
/// an unsupported platform (e.g. web, where [AudioRecorder.getAmplitude]
/// always reports zero rather than throwing — see package docs), or a
/// missing plugin (e.g. running under `flutter test` with no platform
/// implementation registered) must never crash the app or the call flow;
/// they simply leave this detector inert, with [speakingStream] never
/// emitting `true`.
class UserSpeechDetector {
  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();

  Timer? _pollTimer;
  StreamSubscription<Uint8List>? _rawStreamSub;
  DateTime? _belowThresholdSince;
  bool _isSpeaking = false;
  bool _started = false;

  /// Whether the AI is currently speaking (set by the call orchestrator).
  /// Used to pick the echo-resistant threshold — see
  /// [_speechThresholdDbWhileAiSpeaking] above.
  bool _aiSpeaking = false;

  /// Whether the user is currently considered to be speaking.
  bool get isSpeaking => _isSpeaking;

  /// Emits the current speaking state whenever it changes (not on every
  /// poll tick).
  Stream<bool> get speakingStream => _speakingController.stream;

  /// Tells the detector whether the AI is currently speaking, so it can
  /// switch to the higher, echo-resistant threshold described above.
  /// Safe to call at any time, including before [start].
  void setAiSpeaking(bool speaking) {
    _aiSpeaking = speaking;
  }

  /// Requests mic permission and begins listening for speech. Returns
  /// `true` if amplitude polling is now active, `false` if permission was
  /// denied, the platform doesn't support amplitude metering, or the
  /// underlying plugin is unavailable — in every such case this detector
  /// simply stays inert rather than throwing.
  Future<bool> start() async {
    if (_started) return true;

    // The `record` plugin reports it always returns zero amplitude on
    // platforms it doesn't support metering for (web being the notable
    // one for this app). A dBFS reading of 0.0 is actually the loudest
    // possible value, so blindly trusting it would make the detector
    // think the user is *always* speaking. Rather than try to
    // heuristically detect that from readings, we just don't attempt
    // amplitude-based detection on web at all.
    if (kIsWeb) return false;

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return false;

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          autoGain: false,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );
      // We only need getAmplitude() polling below; the raw PCM bytes
      // aren't persisted anywhere. We still drain the stream (rather than
      // leaving it unlistened) so platform-side buffers don't build up.
      _rawStreamSub = stream.listen(
        (_) {},
        onError: (_) {},
        cancelOnError: false,
      );

      _started = true;
      _belowThresholdSince = DateTime.now();
      _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
      return true;
    } catch (_) {
      // Permission plumbing failure, no recorder plugin registered for
      // this platform (e.g. `flutter test`), or any other setup error.
      await _safeStopRecorder();
      _started = false;
      return false;
    }
  }

  Future<void> _poll() async {
    if (!_started) return;
    try {
      final amplitude = await _recorder.getAmplitude();
      final threshold =
          _aiSpeaking ? _speechThresholdDbWhileAiSpeaking : _speechThresholdDb;
      final loud = amplitude.current > threshold;

      if (loud) {
        _belowThresholdSince = null;
        _setSpeaking(true);
      } else {
        _belowThresholdSince ??= DateTime.now();
        if (DateTime.now().difference(_belowThresholdSince!) >=
            _silenceHoldDuration) {
          _setSpeaking(false);
        }
      }
    } catch (_) {
      // A single failed poll (e.g. transient platform hiccup) shouldn't
      // tear down the whole detector — just skip this tick.
    }
  }

  void _setSpeaking(bool value) {
    if (_isSpeaking == value) return;
    _isSpeaking = value;
    if (!_speakingController.isClosed) _speakingController.add(value);
  }

  /// Stops listening. Safe to call even if [start] was never called or
  /// failed. Does not close [speakingStream] — call [dispose] for that.
  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _belowThresholdSince = null;
    final wasStarted = _started;
    _started = false;
    if (wasStarted) {
      unawaited(_safeStopRecorder());
    }
    _setSpeaking(false);
  }

  Future<void> _safeStopRecorder() async {
    try {
      await _rawStreamSub?.cancel();
    } catch (_) {
      // Ignore.
    }
    _rawStreamSub = null;
    try {
      await _recorder.stop();
    } catch (_) {
      // Ignore — nothing to stop, or engine unavailable.
    }
  }

  /// Releases resources. The detector must not be used after this.
  void dispose() {
    stop();
    unawaited(_recorder.dispose().catchError((_) {}));
    if (!_speakingController.isClosed) _speakingController.close();
  }
}
