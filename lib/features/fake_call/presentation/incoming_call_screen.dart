import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/services/ringtone_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/caller.dart';
import '../../../shared/widgets/glow_orb.dart';
import '../application/call_setup_provider.dart';

/// Full-screen incoming call flow: an optional "delay" countdown stage
/// followed by the native-style incoming call UI (ringtone + accept/reject).
class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  ConsumerState<IncomingCallScreen> createState() =>
      _IncomingCallScreenState();
}

enum _Stage { waiting, ringing }

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> {
  _Stage _stage = _Stage.waiting;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  bool _ringtoneStarted = false;
  bool _invalidSetup = false;
  RingtoneService? _ringtone;

  @override
  void initState() {
    super.initState();

    final setup = ref.read(callSetupProvider);
    if (setup.caller == null) {
      _invalidSetup = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(Routes.home);
      });
      return;
    }

    final delaySeconds = setup.delay?.seconds ?? 0;
    if (delaySeconds <= 0) {
      _startRinging();
    } else {
      _remainingSeconds = delaySeconds;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _remainingSeconds -= 1;
        });
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _startRinging();
        }
      });
    }
  }

  void _startRinging() {
    if (!mounted) return;
    setState(() => _stage = _Stage.ringing);
    _ringtoneStarted = true;
    _ringtone = ref.read(ringtoneServiceProvider);
    unawaited(_ringtone!.start());
  }

  // 벨소리 정지가 끝나기를 기다렸다가 화면을 전환하면 오디오 백엔드가 느리거나
  // 없는 환경에서 내비게이션이 막히므로, 정지는 시작만 하고 즉시 전환한다.
  void _stopRingtone() {
    if (_ringtoneStarted) {
      _ringtoneStarted = false;
      unawaited(_ringtone?.stop());
    }
  }

  void _cancelDuringWait() {
    // 대기 단계에서는 아직 벨소리가 울리지 않으므로 정지할 필요가 없다.
    ref.read(callSetupProvider.notifier).reset();
    context.go(Routes.home);
  }

  void _reject() {
    _stopRingtone();
    ref.read(callSetupProvider.notifier).reset();
    context.go(Routes.home);
  }

  void _accept() {
    _stopRingtone();
    context.go(Routes.activeCall);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _stopRingtone();
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _stage == _Stage.waiting
            ? _buildWaitingStage()
            : _buildRingingStage(caller),
      ),
    );
  }

  Widget _buildWaitingStage() {
    return Column(
      children: [
        const Spacer(flex: 3),
        const _GlowBackdrop(
          glowSize: 260,
          child: GlowOrb(size: 120, animate: true, intensity: 0.7),
        ),
        const SizedBox(height: 28),
        Text(
          '$_remainingSeconds',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 64,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '초 후 전화가 옵니다',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
        const Spacer(flex: 4),
        TextButton(
          onPressed: _cancelDuringWait,
          child: const Text(
            '취소',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRingingStage(Caller? caller) {
    final name = caller?.name ?? '';

    return Column(
      children: [
        const Spacer(flex: 2),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '수신 전화',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
        const Spacer(flex: 3),
        const _GlowBackdrop(
          glowSize: 380,
          child: GlowOrb(size: 190, animate: true),
        ),
        const Spacer(flex: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CallActionButton(
                color: AppColors.danger,
                icon: Icons.call_end,
                onTap: _reject,
              ),
              _CallActionButton(
                gradientColors: AppColors.accentGradient,
                glowColor: AppColors.accent,
                icon: Icons.call,
                onTap: _accept,
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

/// Soft radial glow positioned behind an orb-like child.
class _GlowBackdrop extends StatelessWidget {
  final double glowSize;
  final Widget child;

  const _GlowBackdrop({required this.glowSize, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          child: Container(
            width: glowSize,
            height: glowSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.16),
                  AppColors.accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final Color? color;
  final List<Color>? gradientColors;
  final Color? glowColor;
  final IconData icon;
  final VoidCallback onTap;

  const _CallActionButton({
    this.color,
    this.gradientColors,
    this.glowColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gradientColors == null ? color : null,
        gradient: gradientColors != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors!,
              )
            : null,
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Icon(icon, color: AppColors.background, size: 32),
        ),
      ),
    );
  }
}
