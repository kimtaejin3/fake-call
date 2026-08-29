import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'user_speech_detector.dart';

/// A single event emitted by a [VoiceService] during an active call.
///
/// [message] is a line of AI speech to display as a subtitle (null for
/// events that don't carry speech). [callEnded] signals that the AI has
/// naturally ended the call and the UI should transition away.
class VoiceEvent {
  final String? message;
  final bool callEnded;

  const VoiceEvent({this.message, this.callEnded = false});
}

/// Abstraction over the AI voice-call engine.
///
/// Phase 3 will back this with a real streaming voice AI. For now,
/// [MockVoiceService] plays back a scripted conversation per scenario id,
/// emitting subtitle lines with realistic timing, spoken aloud via
/// on-device TTS (flutter_tts).
abstract class VoiceService {
  /// Begins the mock/real conversation for [scenarioId]. Emits events on
  /// [events] as the "conversation" progresses.
  Future<void> start({required String scenarioId});

  /// Stream of conversation events (subtitles, call-ended signal).
  Stream<VoiceEvent> get events;

  /// Stops the conversation early (e.g. user hangs up).
  Future<void> stop();

  /// Releases resources. The service must not be used after this.
  void dispose();
}

class _ScriptLine {
  final String message;

  const _ScriptLine(this.message);
}

/// Mock implementation of [VoiceService] that plays a fixed Korean script
/// per scenario id, simulating an AI speaking over a real phone call.
///
/// Each line is emitted as a subtitle [VoiceEvent] and spoken aloud via
/// [FlutterTts] at the same time. Because [FlutterTts.awaitSpeakCompletion]
/// is enabled, the service knows exactly when a line finishes being
/// spoken and waits an extra pause afterwards (giving the user room to
/// reply) before moving on to the next line — instead of relying on a
/// fixed, guessed-at delay per line as the old silent mock did.
///
/// Turn-taking: a [UserSpeechDetector] listens to the microphone while a
/// call is active. If the user starts talking while the AI is mid-line,
/// the AI is interrupted immediately (barge-in). Before starting each
/// line, the service waits for the user to stop talking (silence) so the
/// AI never talks over the user — bounded by [_maxUserSpeechWait] so a
/// stuck detector can't stall the call forever. The detector fails safe:
/// if the mic/plugin is unavailable (denied permission, unsupported
/// platform, no plugin registered under `flutter test`), it simply never
/// reports speech and the service behaves exactly as before.
class MockVoiceService implements VoiceService {
  final StreamController<VoiceEvent> _controller =
      StreamController<VoiceEvent>.broadcast();
  final FlutterTts _tts = FlutterTts();
  final List<Timer> _timers = [];
  final UserSpeechDetector _speechDetector = UserSpeechDetector();
  StreamSubscription<bool>? _speechSub;

  /// Bumped on every [start]/[stop]/[dispose] so any in-flight async
  /// continuation from a previous run knows to abandon itself instead of
  /// emitting stale events or scheduling further speech.
  int _runId = 0;

  bool _ttsConfigured = false;

  /// Whether the mic listener has been (attempted to be) started for the
  /// current call. Reset on [stop] so the mic is re-armed per call rather
  /// than left open between calls.
  bool _detectorReady = false;

  /// Whether the AI is currently in the middle of speaking a line — used
  /// both to decide whether an incoming "user is speaking" event should
  /// trigger barge-in, and to tell [_speechDetector] which amplitude
  /// threshold to apply.
  bool _aiSpeaking = false;

  /// Gap after the AI finishes speaking a line before the next line
  /// begins, giving the user a natural beat to reply.
  static const _postSpeechPause = Duration(seconds: 4);

  /// Extra delay after the last spoken line before the call auto-ends.
  static const _endCallDelay = Duration(seconds: 2);

  /// How long to wait, at most, for the user to stop talking before the
  /// AI proceeds with its next line anyway. Prevents a stuck/over-eager
  /// speech detector from stalling the call indefinitely.
  static const _maxUserSpeechWait = Duration(seconds: 10);

  /// Poll interval used while waiting for the user to fall silent.
  static const _silenceWaitPoll = Duration(milliseconds: 200);

  static const Map<String, List<_ScriptLine>> _scripts = {
    'come_home': [
      _ScriptLine('여보세요? 너 지금 어디야?'),
      _ScriptLine('아빠가 너 찾고 있어. 조금 일찍 들어와.'),
      _ScriptLine('응. 좀 빨리 왔으면 좋겠어.'),
      _ScriptLine('그래. 조심해서 와.'),
    ],
    'urgent': [
      _ScriptLine('여보세요? 야, 지금 통화 돼?'),
      _ScriptLine('미안한데 지금 급한 일이 생겨서. 지금 바로 좀 와줄 수 있어?'),
      _ScriptLine('어, 자세한 건 만나서 얘기하자. 오래 안 걸릴 거야.'),
      _ScriptLine('그래, 조심해서 빨리 와. 기다리고 있을게.'),
    ],
    'work_problem': [
      _ScriptLine('여보세요, 지금 통화 가능하세요? 급한 일이 좀 생겨서요.'),
      _ScriptLine('다름이 아니라 지금 회사에 문제가 좀 생겨서, 확인이 필요할 것 같아요.'),
      _ScriptLine('네, 지금 바로 와주시면 좋을 것 같습니다.'),
      _ScriptLine('네, 알겠습니다. 조심히 오세요.'),
    ],
    'casual': [
      _ScriptLine('여보세요? 뭐 해?'),
      _ScriptLine('그냥 심심해서 전화해봤어. 별일 없지?'),
      _ScriptLine('그렇구나. 나도 그냥 그래.'),
      _ScriptLine('알았어, 나중에 또 통화하자. 끊을게.'),
    ],
  };

  @override
  Stream<VoiceEvent> get events => _controller.stream;

  /// Applies voice settings once. Safe to call repeatedly (e.g. across
  /// multiple [start] calls reusing the same service instance).
  Future<void> _ensureTtsConfigured() async {
    if (_ttsConfigured) return;
    _ttsConfigured = true;

    try {
      await _tts.setLanguage('ko-KR');
      // flutter_tts speech-rate scales differ by platform: mobile
      // (Android/iOS) engines use a 0.0-1.0 range where ~0.5 is normal
      // speaking pace, while the web Speech Synthesis API uses a
      // 0.1-10 range where 1.0 is normal pace. A rate below "normal"
      // reads as a calmer, more natural phone-call voice on mobile;
      // on web we keep it at the platform's own "normal" (1.0) since
      // web engines already sound reasonably natural at that rate.
      await _tts.setSpeechRate(kIsWeb ? 1.0 : 0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      // Resolve speak() only once the utterance has actually finished
      // being spoken, so we can pace the next line off of real speech
      // duration instead of a guessed fixed delay.
      await _tts.awaitSpeakCompletion(true);

      // NOTE (Android "sounds like a real call"): by default TTS plays
      // through the media/speaker audio stream, not the in-call voice
      // stream, and there's no telephony audio routing here since this
      // is a fully local mock call (no real telephony session). If a
      // more authentic in-call feel is needed later, look at
      // AndroidAudioAttributes (STREAM_VOICE_CALL) via
      // _tts.setAndroidAudioAttributes / setQueueMode, or route through
      // an actual phone-accessory audio session. Not required for the
      // current mock flow, which just needs audible speaker output.
    } catch (_) {
      // No TTS engine/voices available on this platform/device — the
      // call still proceeds silently via subtitles, same as the old
      // pure-mock behavior.
    }
  }

  @override
  Future<void> start({required String scenarioId}) async {
    _cancelTimers();
    final runId = ++_runId;

    await _ensureTtsConfigured();
    if (runId != _runId || _controller.isClosed) return;

    // Don't await mic setup — permission prompts can be slow/blocked on
    // user interaction, and the call must not stall waiting on it. If it
    // fails or isn't ready yet, turn-taking checks below simply see "not
    // speaking" until (if ever) it comes online.
    unawaited(_ensureDetectorReady());

    final script = _scripts[scenarioId] ?? _scripts['casual']!;
    unawaited(_playScript(script, runId));
  }

  /// Starts [_speechDetector] and wires it up to barge-in handling. Safe
  /// to call multiple times; only does real work once per call (until
  /// [stop] resets [_detectorReady]).
  Future<void> _ensureDetectorReady() async {
    if (_detectorReady) return;
    _detectorReady = true;

    try {
      final ok = await _speechDetector.start();
      if (!ok) return;

      _speechSub = _speechDetector.speakingStream.listen((speaking) {
        if (speaking && _aiSpeaking) {
          // Barge-in: the user started talking while the AI was mid-line.
          // Stop the current utterance immediately; the pending
          // `await _tts.speak(...)` in `_playScript` resolves (or throws,
          // which is caught) and the flow moves on to the post-speech
          // pause / silence wait as usual.
          unawaited(_tts.stop().catchError((_) {}));
        }
      });
    } catch (_) {
      // No mic permission, unsupported platform, or plugin unavailable
      // (e.g. running under `flutter test`) — proceed without
      // turn-taking, same as the original TTS-only mock behavior.
    }
  }

  Future<void> _playScript(List<_ScriptLine> script, int runId) async {
    for (final line in script) {
      if (!_isCurrent(runId)) return;

      // Don't start a new line on top of the user still talking (e.g.
      // they were already speaking when the call connected, or kept
      // speaking through the post-speech pause below).
      await _waitForUserSilence(runId);
      if (!_isCurrent(runId)) return;

      _controller.add(VoiceEvent(message: line.message));

      // Speak the line aloud. With awaitSpeakCompletion(true) this
      // resolves once the utterance actually finishes playing (or once
      // barge-in calls `_tts.stop()`), so the pacing below reflects real
      // speech length rather than a guess.
      _aiSpeaking = true;
      _speechDetector.setAiSpeaking(true);
      try {
        await _tts.speak(line.message);
      } catch (_) {
        // Speech failed/unavailable/interrupted; keep the scripted flow
        // moving so the subtitle-driven UI still progresses.
      } finally {
        _aiSpeaking = false;
        _speechDetector.setAiSpeaking(false);
      }
      if (!_isCurrent(runId)) return;

      await _cancellableDelay(_postSpeechPause, runId);
      if (!_isCurrent(runId)) return;
    }

    await _cancellableDelay(_endCallDelay, runId);
    if (!_isCurrent(runId)) return;
    _controller.add(const VoiceEvent(callEnded: true));
  }

  /// Waits for [_speechDetector] to report the user has stopped talking,
  /// polling at [_silenceWaitPoll] intervals, capped at
  /// [_maxUserSpeechWait] total so a stuck detector can't stall the call.
  /// Uses the same cancellable-delay/[_runId] mechanism as the rest of
  /// the script player so [stop]/[dispose] abandon it cleanly.
  Future<void> _waitForUserSilence(int runId) async {
    if (!_speechDetector.isSpeaking) return;

    final deadline = DateTime.now().add(_maxUserSpeechWait);
    while (_isCurrent(runId) &&
        _speechDetector.isSpeaking &&
        DateTime.now().isBefore(deadline)) {
      await _cancellableDelay(_silenceWaitPoll, runId);
    }
  }

  bool _isCurrent(int runId) => runId == _runId && !_controller.isClosed;

  Future<void> _cancellableDelay(Duration duration, int runId) {
    final completer = Completer<void>();
    late final Timer timer;
    timer = Timer(duration, () {
      _timers.remove(timer);
      if (!completer.isCompleted) completer.complete();
    });
    _timers.add(timer);
    return completer.future;
  }

  @override
  Future<void> stop() async {
    _runId++;
    _cancelTimers();
    _aiSpeaking = false;
    _speechDetector.setAiSpeaking(false);
    await _speechSub?.cancel();
    _speechSub = null;
    _detectorReady = false;
    _speechDetector.stop();
    try {
      await _tts.stop();
    } catch (_) {
      // Ignore — nothing to stop or engine unavailable.
    }
  }

  @override
  void dispose() {
    _runId++;
    _cancelTimers();
    unawaited(_tts.stop().catchError((_) {}));
    unawaited(_speechSub?.cancel());
    _speechSub = null;
    _speechDetector.dispose();
    _controller.close();
  }

  void _cancelTimers() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }
}

/// Shared [VoiceService] instance (mock-backed for Phase 1~2, now with
/// real TTS audio output).
final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = MockVoiceService();
  ref.onDispose(service.dispose);
  return service;
});
