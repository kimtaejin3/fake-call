import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/data/app_data.dart';
import '../../../shared/models/caller.dart';
import '../../../shared/models/scenario.dart';
import '../../../shared/widgets/caller_avatar.dart';
import '../../../shared/widgets/glow_orb.dart';
import '../../fake_call/application/call_setup_provider.dart';

/// Home tab — the app's main screen (lives inside the bottom-nav shell).
///
/// Replaces the old caller/scenario/delay funnel: every choice is made on
/// one scrollable screen, with sensible defaults pre-selected so a single
/// tap on the CTA is enough to start a call (see docs/HOME_V2.md).
class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  @override
  void initState() {
    super.initState();
    // Pre-select sensible defaults (엄마 / 집에 들어오라고 해줘 / 30초 후) so the
    // screen is usable with a single tap, without clobbering anything the
    // user already picked (e.g. returning to this tab after a call).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(callSetupProvider.notifier);
      final setup = ref.read(callSetupProvider);
      if (setup.caller == null) {
        final defaultCaller =
            kCallers.where((c) => c.id == 'mom').firstOrNull ??
                kCallers.first;
        notifier.selectCaller(defaultCaller);
      }
      if (setup.scenario == null) {
        final defaultScenario =
            kScenarios.where((s) => s.id == 'come_home').firstOrNull ??
                kScenarios.first;
        notifier.selectScenario(defaultScenario);
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
          // Subtle top radial glow vignette behind the hero orb.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.9),
                    radius: 0.9,
                    colors: [
                      AppColors.accent.withValues(alpha: 0.14),
                      AppColors.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        '곤란한 순간,\n자연스럽게 빠져나오세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // animate: false — a continuously-repeating breathing
                      // animation would keep WidgetTester.pumpAndSettle()
                      // from ever settling on this screen.
                      const Center(child: GlowOrb(size: 130, animate: false)),
                      const SizedBox(height: 36),
                      _SectionTitle('누가 전화할까요?'),
                      const SizedBox(height: 16),
                      _CallerRow(
                        selectedId: setup.caller?.id,
                        onSelect: (caller) => ref
                            .read(callSetupProvider.notifier)
                            .selectCaller(caller),
                      ),
                      const SizedBox(height: 32),
                      _SectionTitle('왜 전화했나요?'),
                      const SizedBox(height: 16),
                      _ScenarioList(
                        selectedId: setup.scenario?.id,
                        onSelect: (scenario) => ref
                            .read(callSetupProvider.notifier)
                            .selectScenario(scenario),
                      ),
                      const SizedBox(height: 32),
                      _SectionTitle('언제 전화할까요?'),
                      const SizedBox(height: 16),
                      _DelayRow(
                        selectedSeconds: setup.delay?.seconds,
                        onSelect: (delay) => ref
                            .read(callSetupProvider.notifier)
                            .selectDelay(delay),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: _GradientCtaButton(
                    label: '전화 받기',
                    onPressed: setup.isComplete
                        ? () => context.go(Routes.incomingCall)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Section 1 — horizontally scrolling caller avatars.
class _CallerRow extends StatelessWidget {
  const _CallerRow({required this.selectedId, required this.onSelect});

  final String? selectedId;
  final ValueChanged<Caller> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: kCallers.length,
        itemBuilder: (context, index) {
          final caller = kCallers[index];
          final selected = caller.id == selectedId;
          return Padding(
            padding: EdgeInsets.only(
              right: index == kCallers.length - 1 ? 0 : 14,
            ),
            child: _CallerChip(
              caller: caller,
              selected: selected,
              onTap: () => onSelect(caller),
            ),
          );
        },
      ),
    );
  }
}

class _CallerChip extends StatelessWidget {
  const _CallerChip({
    required this.caller,
    required this.selected,
    required this.onTap,
  });

  final Caller caller;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        selected ? AppColors.accent : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.45),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: CallerAvatar(name: caller.name, size: 56),
              ),
              const SizedBox(height: 8),
              Text(
                caller.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      selected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section 2 — compact vertical scenario cards.
class _ScenarioList extends StatelessWidget {
  const _ScenarioList({required this.selectedId, required this.onSelect});

  final String? selectedId;
  final ValueChanged<Scenario> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < kScenarios.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == kScenarios.length - 1 ? 0 : 10,
            ),
            child: _ScenarioCard(
              scenario: kScenarios[i],
              selected: kScenarios[i].id == selectedId,
              onTap: () => onSelect(kScenarios[i]),
            ),
          ),
      ],
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.scenario,
    required this.selected,
    required this.onTap,
  });

  final Scenario scenario;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.surfaceBorder,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  blurRadius: 14,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    scenario.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color:
                      selected ? AppColors.accent : AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Section 3 — horizontally scrolling delay chips.
class _DelayRow extends StatelessWidget {
  const _DelayRow({required this.selectedSeconds, required this.onSelect});

  final int? selectedSeconds;
  final ValueChanged<DelayOption> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: kDelayOptions.length,
        itemBuilder: (context, index) {
          final delay = kDelayOptions[index];
          final selected = delay.seconds == selectedSeconds;
          return Padding(
            padding: EdgeInsets.only(
              right: index == kDelayOptions.length - 1 ? 0 : 10,
            ),
            child: _DelayChip(
              delay: delay,
              selected: selected,
              onTap: () => onSelect(delay),
            ),
          );
        },
      ),
    );
  }
}

class _DelayChip extends StatelessWidget {
  const _DelayChip({
    required this.delay,
    required this.selected,
    required this.onTap,
  });

  final DelayOption delay;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.transparent : AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.accentGradient,
                  )
                : null,
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.surfaceBorder,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            delay.label,
            style: TextStyle(
              color: selected ? AppColors.background : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Accent-gradient filled pill CTA, matching the Voice AI design spec.
class _GradientCtaButton extends StatelessWidget {
  const _GradientCtaButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: enabled
              ? AppColors.accentGradient
              : AppColors.accentGradient
                  .map((c) => c.withValues(alpha: 0.35))
                  .toList(),
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary.withValues(
                  alpha: enabled ? 1 : 0.6,
                ),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
