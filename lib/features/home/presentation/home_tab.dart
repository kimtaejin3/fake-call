import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/data/app_data.dart';
import '../../../shared/models/caller.dart';
import '../../../shared/models/scenario.dart';
import '../../../shared/widgets/soft_orb.dart';
import '../../fake_call/application/call_setup_provider.dart';

/// Home tab — the app's main screen (lives inside the bottom-nav shell).
///
/// Simple, single-screen "레퍼런스" layout (see docs/DESIGN_V3.md, "홈 탭 —
/// 심플 구성"): greeting → big SoftOrb mascot → 2x2 quick-scenario chips →
/// bottom pill bar (delay picker + call button).
class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  @override
  void initState() {
    super.initState();
    // Pre-select sensible defaults (엄마가 불러요 프리셋 + 30초 후) so the call
    // button works with a single tap, without clobbering anything the user
    // already picked (e.g. returning to this tab after a call).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(callSetupProvider.notifier);
      final setup = ref.read(callSetupProvider);
      final defaultPreset = _presets.first;
      if (setup.caller == null) {
        notifier.selectCaller(defaultPreset.caller);
      }
      if (setup.scenario == null) {
        notifier.selectScenario(defaultPreset.scenario);
      }
      if (setup.delay == null) {
        final defaultDelay =
            kDelayOptions.where((d) => d.seconds == 30).firstOrNull ??
                kDelayOptions.first;
        notifier.selectDelay(defaultDelay);
      }
    });
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
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    '안녕하세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '곤란한 순간, 빠져나올까요?',
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
                      // animate: false — a continuously-repeating breathing
                      // animation would keep WidgetTester.pumpAndSettle()
                      // from ever settling on this screen.
                      child: const SoftOrb(
                        size: 210,
                        animate: false,
                        showFace: true,
                      ),
                    ),
                  ),
                  _PresetGrid(
                    selectedCallerId: setup.caller?.id,
                    selectedScenarioId: setup.scenario?.id,
                    onSelect: (preset) {
                      final notifier = ref.read(callSetupProvider.notifier);
                      notifier.selectCaller(preset.caller);
                      notifier.selectScenario(preset.scenario);
                    },
                  ),
                  const SizedBox(height: 20),
                  _BottomPillBar(
                    delayLabel: setup.delay?.label ?? kDelayOptions
                        .firstWhere((d) => d.seconds == 30)
                        .label,
                    onTapDelay: () => _showDelaySheet(context, ref),
                    onTapCall: () => context.go(Routes.incomingCall),
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
      backgroundColor: Colors.white,
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
                      ref
                          .read(callSetupProvider.notifier)
                          .selectDelay(option);
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

/// Two or three softly-blurred pastel circles pinned to the corners of the
/// screen, per DESIGN_V3's "몽글몽글한" background treatment.
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

/// A quick-start caller+scenario combo, shown as one chip in the 2x2 grid.
class _Preset {
  final String label;
  final IconData icon;
  final String callerId;
  final String scenarioId;

  const _Preset({
    required this.label,
    required this.icon,
    required this.callerId,
    required this.scenarioId,
  });

  Caller get caller => kCallers.firstWhere((c) => c.id == callerId);
  Scenario get scenario => kScenarios.firstWhere((s) => s.id == scenarioId);
}

const _presets = [
  _Preset(
    label: '엄마가 불러요',
    icon: Icons.family_restroom,
    callerId: 'mom',
    scenarioId: 'come_home',
  ),
  _Preset(
    label: '회사에 일이',
    icon: Icons.work,
    callerId: 'boss',
    scenarioId: 'work_problem',
  ),
  _Preset(
    label: '급한 일이',
    icon: Icons.priority_high,
    callerId: 'friend',
    scenarioId: 'urgent',
  ),
  _Preset(
    label: '그냥 통화',
    icon: Icons.favorite,
    callerId: 'partner',
    scenarioId: 'casual',
  ),
];

class _PresetGrid extends StatelessWidget {
  const _PresetGrid({
    required this.selectedCallerId,
    required this.selectedScenarioId,
    required this.onSelect,
  });

  final String? selectedCallerId;
  final String? selectedScenarioId;
  final ValueChanged<_Preset> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildChip(_presets[0])),
            const SizedBox(width: 14),
            Expanded(child: _buildChip(_presets[1])),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildChip(_presets[2])),
            const SizedBox(width: 14),
            Expanded(child: _buildChip(_presets[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(_Preset preset) {
    final selected = preset.callerId == selectedCallerId &&
        preset.scenarioId == selectedScenarioId;
    return _PresetChip(
      preset: preset,
      selected: selected,
      onTap: () => onSelect(preset),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final _Preset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.1)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.surfaceBorder,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                preset.icon,
                color: selected ? AppColors.accent : AppColors.textSecondary,
                size: 26,
              ),
              const SizedBox(height: 8),
              Text(
                preset.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom pill bar: delay-picker text on the left, circular gradient call
/// button on the right — mirrors the reference design's input-bar position.
class _BottomPillBar extends StatelessWidget {
  const _BottomPillBar({
    required this.delayLabel,
    required this.onTapDelay,
    required this.onTapCall,
  });

  final String delayLabel;
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
          _CallButton(onTap: onTapCall),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
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
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
