import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/call_theme.dart';
import '../../../shared/widgets/call_buttons.dart';
import '../../../shared/widgets/caller_avatar.dart';
import '../../../shared/widgets/dial_pad.dart';
import '../../fake_call/application/call_setup_provider.dart';
import '../../history/application/call_history_provider.dart';

/// 통화 중 화면 — iOS/Android 시스템 전화 UI 를 그대로 흉내낸다.
///
/// AI 대사 자막과 음성 파형은 일부러 그리지 않는다. 실제 통화 화면에는 없는
/// 요소라 옆 사람에게 즉시 앱임을 알려버리기 때문이다. 대사는 TTS 로만 들린다.
class ActiveCallScreen extends ConsumerStatefulWidget {
  const ActiveCallScreen({super.key});

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen> {
  Timer? _durationTimer;
  StreamSubscription<VoiceEvent>? _eventSub;

  int _elapsedSeconds = 0;
  bool _speakerOn = false;
  bool _micMuted = false;
  bool _showKeypad = false;
  bool _ending = false;
  bool _invalidSetup = false;

  VoiceService? _voiceService;

  @override
  void initState() {
    super.initState();

    final setup = ref.read(callSetupProvider);
    if (setup.caller == null || setup.scenario == null) {
      _invalidSetup = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(Routes.home);
      });
      return;
    }

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds += 1);
    });

    final voiceService = ref.read(voiceServiceProvider);
    _voiceService = voiceService;
    _eventSub = voiceService.events.listen(_onVoiceEvent);
    voiceService.start(scenarioId: setup.scenario!.id);
  }

  void _onVoiceEvent(VoiceEvent event) {
    if (!mounted) return;
    // 대사(event.message)는 화면에 띄우지 않는다 — TTS 가 소리로만 전달한다.
    if (event.callEnded && !_ending) {
      _ending = true;
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _endCall();
      });
    }
  }

  void _endCall() {
    _ending = true;
    _durationTimer?.cancel();
    // 음성 정지가 끝나기를 기다리면 오디오 백엔드가 느리거나 없는 환경에서
    // 화면 전환이 막히므로, 정리는 시작만 하고 즉시 전환한다.
    unawaited(_eventSub?.cancel());
    final voice = _voiceService;
    if (voice != null) unawaited(voice.stop());
    ref.read(lastCallDurationProvider.notifier).state = _elapsedSeconds;
    if (mounted) context.go(Routes.callComplete);
  }

  String get _formattedDuration {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _eventSub?.cancel();
    _voiceService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_invalidSetup) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SizedBox.shrink(),
      );
    }

    final caller = ref.watch(callSetupProvider).caller;
    final name = caller?.name ?? '';
    final palette = CallPalette.of(context);
    final isIos = callStyleOf(context) == CallStyle.ios;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: palette.background.last,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: palette.background,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // 키패드가 올라오면 실제 전화 앱처럼 상단이 접힌다.
                if (!_showKeypad) ...[
                  CallerAvatar(
                    name: name,
                    size: isIos ? 92 : 100,
                    variant: CallerAvatarVariant.call,
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: isIos ? 32 : 28,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isIos ? _formattedDuration : '통화 중  $_formattedDuration',
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 17,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                if (_showKeypad)
                  DialPad(
                    palette: palette,
                    onHide: () => setState(() => _showKeypad = false),
                  )
                else
                  _ControlGrid(
                    palette: palette,
                    isIos: isIos,
                    micMuted: _micMuted,
                    speakerOn: _speakerOn,
                    onToggleMic: () => setState(() => _micMuted = !_micMuted),
                    onToggleSpeaker: () =>
                        setState(() => _speakerOn = !_speakerOn),
                    onShowKeypad: () => setState(() => _showKeypad = true),
                  ),
                const Spacer(),
                _EndCallButton(
                  palette: palette,
                  isIos: isIos,
                  onTap: _ending ? null : _endCall,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 통화 중 컨트롤 3x2 그리드.
///
/// 음소거/스피커/키패드만 실제로 동작한다. 나머지는 실제 전화 화면에 있는
/// 버튼이라 연출상 자리를 지키지만, 가짜 통화에서는 의미가 없어 눌러도
/// 상태가 바뀌지 않는다(잉크 반응만 남긴다).
class _ControlGrid extends StatelessWidget {
  const _ControlGrid({
    required this.palette,
    required this.isIos,
    required this.micMuted,
    required this.speakerOn,
    required this.onToggleMic,
    required this.onToggleSpeaker,
    required this.onShowKeypad,
  });

  final CallPalette palette;
  final bool isIos;
  final bool micMuted;
  final bool speakerOn;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onShowKeypad;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row([
          CallControlButton(
            icon: Icons.mic_off,
            label: '음소거',
            palette: palette,
            active: micMuted,
            onTap: onToggleMic,
          ),
          CallControlButton(
            icon: Icons.dialpad,
            label: '키패드',
            palette: palette,
            onTap: onShowKeypad,
          ),
          CallControlButton(
            icon: Icons.volume_up,
            label: '스피커',
            palette: palette,
            active: speakerOn,
            onTap: onToggleSpeaker,
          ),
        ]),
        const SizedBox(height: 26),
        _row(
          isIos
              ? [
                  CallControlButton(
                    icon: Icons.add,
                    label: '통화 추가',
                    palette: palette,
                    onTap: () {},
                  ),
                  CallControlButton(
                    icon: Icons.videocam,
                    label: 'FaceTime',
                    palette: palette,
                    onTap: () {},
                  ),
                  CallControlButton(
                    icon: Icons.person,
                    label: '연락처',
                    palette: palette,
                    onTap: () {},
                  ),
                ]
              : [
                  CallControlButton(
                    icon: Icons.person_add_alt,
                    label: '통화 추가',
                    palette: palette,
                    onTap: () {},
                  ),
                  CallControlButton(
                    icon: Icons.pause,
                    label: '보류',
                    palette: palette,
                    onTap: () {},
                  ),
                  CallControlButton(
                    icon: Icons.videocam,
                    label: '영상 통화',
                    palette: palette,
                    onTap: () {},
                  ),
                ],
        ),
      ],
    );
  }

  Widget _row(List<Widget> buttons) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 30),
          buttons[i],
        ],
      ],
    );
  }
}

/// 통화 종료 버튼. iOS 는 원형, Android(구글 다이얼러)는 알약형.
class _EndCallButton extends StatelessWidget {
  const _EndCallButton({
    required this.palette,
    required this.isIos,
    required this.onTap,
  });

  final CallPalette palette;
  final bool isIos;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (isIos) {
      return SizedBox(
        width: palette.actionButtonSize,
        height: palette.actionButtonSize,
        child: Material(
          color: palette.decline,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Icon(Icons.call_end, color: Colors.white, size: 34),
          ),
        ),
      );
    }

    return SizedBox(
      width: 168,
      height: 60,
      child: Material(
        color: palette.decline,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: const Icon(Icons.call_end, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
