import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/data/app_data.dart';
import '../../../shared/models/caller.dart';
import '../../../shared/widgets/soft_orb.dart';
import '../../fake_call/application/call_setup_provider.dart';

/// 홈 탭 — 앱의 메인 화면(하단 네비 셸 안에 들어간다).
///
/// 구성: 인사 → SoftOrb 마스코트 → 발신자 이름 입력(+ 자주 쓰는 이름 칩) →
/// 하단 pill(지연 선택 + 통화 버튼).
///
/// 시나리오(왜 전화했나요)는 화면에 두지 않는다. AI 음성을 끈 뒤로는 골라도
/// 눈에 보이는 차이가 없고(통화 길이와 기록 라벨에만 쓰인다), 홈은 "누가
/// 언제" 두 가지만 정하면 되는 화면으로 두는 편이 빠르다.
class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

/// 시나리오 UI 를 없앤 뒤 쓰는 고정 시나리오.
const _kDefaultScenarioId = 'come_home';

/// 저장된 이름이 없을 때 이름칸에 채워둘 값 — 처음 켜도 바로 통화할 수 있게.
const _kFallbackName = '엄마';

class _HomeTabState extends ConsumerState<HomeTab> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    // 마지막에 전화한 상대를 그대로 다시 부르는 경우가 흔하다. 매번
    // 기본값으로 되돌리면 통화가 끝날 때마다 다시 타이핑해야 한다.
    final saved = ref.read(sharedPreferencesProvider)?.getString(
          PrefKeys.lastCallerName,
        );
    _nameController = TextEditingController(
      text: (saved != null && saved.trim().isNotEmpty)
          ? saved
          : _kFallbackName,
    )
      // 이름이 비면 통화 버튼을 잠가야 하므로 변경마다 다시 그린다.
      ..addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(callSetupProvider.notifier);
      final setup = ref.read(callSetupProvider);
      if (setup.scenario == null) {
        notifier.selectScenario(
          kScenarios.firstWhere((s) => s.id == _kDefaultScenarioId),
        );
      }
      if (setup.delay == null) {
        notifier.selectDelay(
          kDelayOptions.firstWhere((d) => d.seconds == 30),
        );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _name => _nameController.text.trim();

  /// 입력된 이름에 해당하는 발신자.
  ///
  /// 미리 들어 있는 이름(엄마/아빠/…)이면 그 연락처를 그대로 써서 번호까지
  /// 유지하고, 직접 입력한 이름이면 즉석에서 만든다.
  Caller _callerFor(String name) {
    for (final caller in kCallers) {
      if (caller.name == name) return caller;
    }
    return Caller.custom(name);
  }

  void _startCall() {
    final name = _name;
    if (name.isEmpty) return;

    // 입력 중 키보드가 떠 있으면 수신 화면 위로 남을 수 있어 먼저 내린다.
    FocusScope.of(context).unfocus();

    ref.read(sharedPreferencesProvider)?.setString(
          PrefKeys.lastCallerName,
          name,
        );

    final notifier = ref.read(callSetupProvider.notifier);
    notifier.selectCaller(_callerFor(name));
    if (ref.read(callSetupProvider).scenario == null) {
      notifier.selectScenario(
        kScenarios.firstWhere((s) => s.id == _kDefaultScenarioId),
      );
    }
    context.go(Routes.incomingCall);
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(callSetupProvider);

    return ColoredBox(
      color: AppColors.background,
      child: Stack(
        children: [
          const Positioned.fill(child: _PastelBlurBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    '말 꺼내기 어려울 땐,',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '먼저 일어나도 괜찮아요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      // FittedBox — 키보드가 올라와 공간이 줄면 넘치는 대신
                      // 오브가 작아진다.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: const SoftOrb(
                          size: 200,
                          showFace: true,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      '누가 전화할까요?',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _NameField(controller: _nameController),
                  const SizedBox(height: 12),
                  _PresetNameChips(
                    selectedName: _name,
                    onSelect: (name) {
                      _nameController
                        ..text = name
                        ..selection = TextSelection.collapsed(
                          offset: name.length,
                        );
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  const SizedBox(height: 18),
                  _BottomPillBar(
                    delayLabel: setup.delay?.label ??
                        kDelayOptions
                            .firstWhere((d) => d.seconds == 30)
                            .label,
                    canCall: _name.isNotEmpty,
                    onTapDelay: () => _showDelaySheet(context, ref),
                    onTapCall: _startCall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDelaySheet(BuildContext context, WidgetRef ref) {
    final currentSeconds = ref.read(callSetupProvider).delay?.seconds;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '언제 전화할까요?',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final option in kDelayOptions)
                  ListTile(
                    onTap: () {
                      ref.read(callSetupProvider.notifier).selectDelay(option);
                      Navigator.of(sheetContext).pop();
                    },
                    title: Text(
                      option.label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: option.seconds == currentSeconds
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: option.seconds == currentSeconds
                        ? const Icon(Icons.check, color: AppColors.accent)
                        : null,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 발신자 이름 입력칸.
class _NameField extends StatelessWidget {
  const _NameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.done,
        maxLength: 20,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          hintText: '이름을 입력하세요',
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          prefixIcon: Icon(
            Icons.person_outline,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// 자주 쓰는 이름을 한 번에 채워 넣는 칩 줄.
class _PresetNameChips extends StatelessWidget {
  const _PresetNameChips({
    required this.selectedName,
    required this.onSelect,
  });

  final String selectedName;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final caller in kCallers)
          ActionChip(
            label: Text(caller.name),
            onPressed: () => onSelect(caller.name),
            backgroundColor: caller.name == selectedName
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.surface,
            side: BorderSide(
              color: caller.name == selectedName
                  ? AppColors.accent
                  : AppColors.surfaceBorder,
            ),
            labelStyle: TextStyle(
              color: caller.name == selectedName
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: caller.name == selectedName
                  ? FontWeight.w700
                  : FontWeight.w600,
            ),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          ),
      ],
    );
  }
}

/// 화면 구석에 깔리는 옅은 파스텔 원들 — DESIGN_V3 의 "몽글몽글한" 배경.
class _PastelBlurBackground extends StatelessWidget {
  const _PastelBlurBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _blurCircle(320, AppColors.accent, 0.22),
          ),
          Positioned(
            top: -40,
            right: -100,
            child: _blurCircle(260, AppColors.accentAlt, 0.18),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _blurCircle(280, AppColors.glow, 0.16),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(double size, Color color, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// 하단 pill 바: 왼쪽 지연 선택, 오른쪽 원형 그라데이션 통화 버튼.
class _BottomPillBar extends StatelessWidget {
  const _BottomPillBar({
    required this.delayLabel,
    required this.canCall,
    required this.onTapDelay,
    required this.onTapCall,
  });

  final String delayLabel;
  final bool canCall;
  final VoidCallback onTapDelay;
  final VoidCallback onTapCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.only(left: 20, right: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onTapDelay,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      delayLabel,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _CallButton(enabled: canCall, onTap: onTapCall),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.accentGradient,
              ),
            ),
            child: const Icon(Icons.call, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
