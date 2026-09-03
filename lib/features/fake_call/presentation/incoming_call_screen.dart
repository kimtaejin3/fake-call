import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/services/ringtone_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/call_theme.dart';
import '../../../shared/models/caller.dart';
import '../../../shared/widgets/call_buttons.dart';
import '../../../shared/widgets/caller_avatar.dart';
import '../../../shared/widgets/soft_orb.dart';
import '../../settings/application/settings_provider.dart';
import '../application/call_setup_provider.dart';

/// 전체화면 수신 플로우: 지연 카운트다운 단계 → 시스템 전화 UI 를 흉내낸
/// 수신 단계(벨소리 + 거절/응답).
///
/// 두 단계의 톤이 다른 건 의도한 것이다. 카운트다운은 사용자만 보는 앱 화면이라
/// 앱의 파스텔을 그대로 쓰고, 수신 단계는 옆 사람에게 보여야 하는 화면이라
/// iOS/Android 시스템 전화 UI 를 따라 다크로 전환한다 — 실제 전화가 올 때
/// 화면이 통째로 바뀌는 것과 같은 인상을 준다.
class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  ConsumerState<IncomingCallScreen> createState() =>
      _IncomingCallScreenState();
}

enum _Stage { waiting, ringing }

/// [ringAt] 까지 남은 초. 이미 지났으면 0.
///
/// 남은 시간을 틱마다 1씩 빼지 않고 벽시계로 계산하는 이유: 앱이 백그라운드로
/// 내려가면 OS 가 프로세스를 재우고 Timer 도 멈춘다. 빼기 방식이면 그동안
/// 흐른 시간이 통째로 사라져서, 30초를 걸어두고 잠깐 다른 앱을 보다 돌아오면
/// 여전히 30초가 남아 있다. 마감시각을 들고 있으면 자는 동안 흐른 시간도
/// 그대로 반영된다.
@visibleForTesting
int remainingSecondsUntil(DateTime ringAt, DateTime now) {
  final ms = ringAt.difference(now).inMilliseconds;
  if (ms <= 0) return 0;
  return (ms / 1000).ceil();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen>
    with WidgetsBindingObserver {
  _Stage _stage = _Stage.waiting;

  /// 벨이 울려야 하는 시각. 지연이 없으면 null.
  DateTime? _ringAt;
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
      return;
    }

    WidgetsBinding.instance.addObserver(this);
    _ringAt = DateTime.now().add(Duration(seconds: delaySeconds));
    _remainingSeconds = delaySeconds;
    // 1초보다 자주 확인한다. 마감시각과 틱이 어긋나 표시가 한 박자 늦게
    // 바뀌는 걸 줄인다.
    _countdownTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _tick(),
    );
  }

  /// 남은 시간을 다시 계산하고, 다 됐으면 벨을 울린다.
  void _tick() {
    if (!mounted) return;
    final ringAt = _ringAt;
    if (ringAt == null || _stage == _Stage.ringing) return;

    final remaining = remainingSecondsUntil(ringAt, DateTime.now());
    if (remaining != _remainingSeconds) {
      setState(() => _remainingSeconds = remaining);
    }
    if (remaining <= 0) {
      _countdownTimer?.cancel();
      _startRinging();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 백그라운드에 있는 동안 Timer 는 멈춰 있었다. 돌아오자마자 다시 계산해서,
    // 그 사이 마감시각이 지났으면 곧바로 울린다.
    if (state == AppLifecycleState.resumed) _tick();
  }

  void _startRinging() {
    if (!mounted) return;
    setState(() => _stage = _Stage.ringing);
    _ringtoneStarted = true;
    _ringtone = ref.read(ringtoneServiceProvider);
    unawaited(_ringtone!.start(mode: ref.read(ringtoneModeProvider)));
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
    WidgetsBinding.instance.removeObserver(this);
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

    if (_stage == _Stage.waiting) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: _buildWaitingStage()),
      );
    }

    final caller = ref.watch(callSetupProvider).caller;
    final palette = CallPalette.of(context);
    final style = callStyleOf(context);

    // 다크 통화 화면 위에서는 상태바 아이콘이 밝아야 한다.
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
            child: style == CallStyle.ios
                ? _IosRingingStage(
                    caller: caller,
                    palette: palette,
                    onAccept: _accept,
                    onReject: _reject,
                  )
                : _AndroidRingingStage(
                    caller: caller,
                    palette: palette,
                    onAccept: _accept,
                    onReject: _reject,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingStage() {
    // SizedBox 로 가로를 강제하는 이유: Column 은 세로만 꽉 채우고 가로는
    // 가장 넓은 자식에 맞춰 줄어든다. 그대로 두면 좁은 덩어리가 화면
    // 왼쪽에 붙어 가운데 정렬이 깨진다.
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const Spacer(flex: 3),
          const SoftOrb(size: 120, showFace: true),
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
      ),
    );
  }
}

/// iOS 수신 화면 — 이름/회선 라벨을 위에 크게, 아래에 알림·메시지 보조 액션과
/// 거절·응답 버튼.
class _IosRingingStage extends StatelessWidget {
  const _IosRingingStage({
    required this.caller,
    required this.palette,
    required this.onAccept,
    required this.onReject,
  });

  final Caller? caller;
  final CallPalette palette;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final name = caller?.name ?? '';

    return Column(
      children: [
        const Spacer(flex: 2),
        CallerAvatar(
          name: name,
          size: 104,
          variant: CallerAvatarVariant.call,
        ),
        const SizedBox(height: 22),
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 38,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '휴대전화',
          style: TextStyle(color: palette.textSecondary, fontSize: 18),
        ),
        const Spacer(flex: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 56),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IosSecondaryAction(
                icon: Icons.alarm,
                label: '알림',
                palette: palette,
              ),
              _IosSecondaryAction(
                icon: Icons.message,
                label: '메시지',
                palette: palette,
              ),
            ],
          ),
        ),
        const SizedBox(height: 34),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CallActionButton(
                icon: Icons.call_end,
                color: palette.decline,
                label: '거절',
                labelColor: palette.textPrimary,
                size: palette.actionButtonSize,
                onTap: onReject,
              ),
              CallActionButton(
                icon: Icons.call,
                color: palette.accept,
                label: '응답',
                labelColor: palette.textPrimary,
                size: palette.actionButtonSize,
                onTap: onAccept,
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
      ],
    );
  }
}

/// iOS 수신 화면의 작은 보조 액션(알림/메시지). 실제 전화 UI 에도 있는
/// 버튼이라 연출상 필요하지만, 가짜 통화에서는 동작이 없다.
class _IosSecondaryAction extends StatelessWidget {
  const _IosSecondaryAction({
    required this.icon,
    required this.label,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final CallPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Material(
            color: palette.controlIdle,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {},
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: palette.textPrimary, fontSize: 14),
        ),
      ],
    );
  }
}

/// Android(구글 다이얼러) 수신 화면 — 상단 "수신 전화" 라벨, 아바타, 이름,
/// 번호, 하단 거절/응답.
class _AndroidRingingStage extends StatelessWidget {
  const _AndroidRingingStage({
    required this.caller,
    required this.palette,
    required this.onAccept,
    required this.onReject,
  });

  final Caller? caller;
  final CallPalette palette;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final name = caller?.name ?? '';
    final number = caller?.phoneNumber ?? '';

    return Column(
      children: [
        const SizedBox(height: 28),
        Text(
          '수신 전화',
          style: TextStyle(
            color: palette.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
        const Spacer(flex: 2),
        CallerAvatar(
          name: name,
          size: 112,
          variant: CallerAvatarVariant.call,
        ),
        const SizedBox(height: 24),
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w400,
          ),
        ),
        if (number.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            number,
            style: TextStyle(color: palette.textSecondary, fontSize: 16),
          ),
        ],
        const Spacer(flex: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: palette.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              '메시지 보내기',
              style: TextStyle(color: palette.textSecondary, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 44),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CallActionButton(
                icon: Icons.call_end,
                color: palette.decline,
                label: '거절',
                labelColor: palette.textSecondary,
                size: palette.actionButtonSize,
                onTap: onReject,
              ),
              CallActionButton(
                icon: Icons.call,
                color: palette.accept,
                label: '응답',
                labelColor: palette.textSecondary,
                size: palette.actionButtonSize,
                onTap: onAccept,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

