import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/soft_orb.dart';
import '../../fake_call/application/call_setup_provider.dart';
import '../../history/application/call_history_provider.dart';

const List<String> _kLikelihoodOptions = [
  '매우 그렇다',
  '그렇다',
  '보통',
  '아니다',
  '전혀 아니다',
];

/// Post-call feedback screen. Selections are only logged via [debugPrint]
/// for now — analytics wiring is Phase 4.
class CallCompleteScreen extends ConsumerStatefulWidget {
  const CallCompleteScreen({super.key});

  @override
  ConsumerState<CallCompleteScreen> createState() =>
      _CallCompleteScreenState();
}

class _CallCompleteScreenState extends ConsumerState<CallCompleteScreen> {
  bool? _helpful;
  int? _likelihoodIndex;

  void _finish() {
    debugPrint(
      'CallComplete feedback — helpful: $_helpful, '
      'likelihood: ${_likelihoodIndex != null ? _kLikelihoodOptions[_likelihoodIndex!] : null}',
    );
    final setup = ref.read(callSetupProvider);
    ref.read(callHistoryProvider.notifier).add(
          CallRecord(
            callerName: setup.caller?.name ?? '알 수 없음',
            scenarioTitle: setup.scenario?.title ?? '알 수 없음',
            endedAt: DateTime.now(),
            durationSeconds: ref.read(lastCallDurationProvider),
            feedback: _helpful == null
                ? null
                : (_helpful! ? 'positive' : 'negative'),
          ),
        );
    ref.read(callSetupProvider.notifier).reset();
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
              const SizedBox(height: 24),
              const Center(
                child: SoftOrb(size: 100, animate: false, showFace: true),
              ),
              const SizedBox(height: 16),
              const Text(
                '통화가 종료되었습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'AI Fake Call이 도움이 되었나요?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _FeedbackChoiceButton(
                      label: '👍 도움이 됐어요',
                      selected: _helpful == true,
                      onTap: () => setState(() => _helpful = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FeedbackChoiceButton(
                      label: '👎 별로였어요',
                      selected: _helpful == false,
                      onTap: () => setState(() => _helpful = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              const Text(
                '실제로 이런 상황에서 사용할 것 같나요?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(_kLikelihoodOptions.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LikelihoodOptionRow(
                    label: _kLikelihoodOptions[index],
                    selected: _likelihoodIndex == index,
                    onTap: () => setState(() => _likelihoodIndex = index),
                  ),
                );
              }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.accentGradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.20),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: _finish,
                      borderRadius: BorderRadius.circular(18),
                      child: const Center(
                        child: Text(
                          '완료',
                          style: TextStyle(
                            color: AppColors.background,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FeedbackChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.16)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.surfaceBorder,
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.accent : AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _LikelihoodOptionRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LikelihoodOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.12)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.surfaceBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: selected
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
