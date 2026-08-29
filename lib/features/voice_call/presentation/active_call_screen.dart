import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glow_orb.dart';
import '../../../shared/widgets/wave_line.dart';
import '../../fake_call/application/call_setup_provider.dart';
import '../../history/application/call_history_provider.dart';

/// Active (mock) voice call screen: call timer, avatar, AI subtitle feed,
/// and speaker/mute/end-call controls.
class ActiveCallScreen extends ConsumerStatefulWidget {
  const ActiveCallScreen({super.key});

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen> {
  Timer? _durationTimer;
  StreamSubscription<VoiceEvent>? _eventSub;

  int _elapsedSeconds = 0;
  String? _currentMessage;
  bool _speakerOn = false;
  bool _micMuted = false;
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
    if (event.message != null) {
      setState(() => _currentMessage = event.message);
    }
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
    final aiSpeaking = _currentMessage != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formattedDuration,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(flex: 2),
            // The backdrop glow is rendered via OverflowBox so its larger
            // visual footprint doesn't inflate this Column's layout size.
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  OverflowBox(
                    maxWidth: 300,
                    maxHeight: 300,
                    child: IgnorePointer(
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.accent.withValues(alpha: 0.14),
                              AppColors.accent.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  GlowOrb(
                    size: 200,
                    animate: true,
                    intensity: aiSpeaking ? 1.2 : 1.0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                height: 52,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    _currentMessage ?? '',
                    key: ValueKey(_currentMessage),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: VoiceWaveLine(height: 28, active: aiSpeaking),
            ),
            const Spacer(flex: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ToggleButton(
                  icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
                  active: _speakerOn,
                  onTap: () => setState(() => _speakerOn = !_speakerOn),
                ),
                const SizedBox(width: 28),
                _ToggleButton(
                  icon: _micMuted ? Icons.mic_off : Icons.mic,
                  active: _micMuted,
                  onTap: () => setState(() => _micMuted = !_micMuted),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.danger.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _ending ? null : _endCall,
                  customBorder: const CircleBorder(),
                  child: const Icon(
                    Icons.call_end,
                    color: AppColors.background,
                    size: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.accent.withValues(alpha: 0.18) : AppColors.surface,
        border: Border.all(
          color: active ? AppColors.accent : AppColors.surfaceBorder,
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            color: active ? AppColors.accent : AppColors.textPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
}
