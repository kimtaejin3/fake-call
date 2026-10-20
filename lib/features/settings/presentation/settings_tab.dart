import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/call_theme.dart';
import '../application/settings_provider.dart';

/// 설정 탭.
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  /// 벨소리 모드 선택 시트. 홈의 지연 선택 시트와 같은 형태를 쓴다.
  void _showRingtoneSheet(BuildContext context, WidgetRef ref) {
    final current = ref.read(ringtoneModeProvider);
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
                      '전화가 오면',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final mode in RingtoneMode.values)
                  ListTile(
                    onTap: () {
                      ref.read(ringtoneModeProvider.notifier).select(mode);
                      Navigator.of(sheetContext).pop();
                    },
                    title: Text(
                      mode.label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: mode == current
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: mode == current
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

  /// 통화 화면 배경 선택 시트. 이름만으로는 색을 떠올리기 어려우므로
  /// 실제 그라데이션 견본을 같이 보여준다.
  void _showBackgroundSheet(BuildContext context, WidgetRef ref) {
    final current = ref.read(callBackgroundProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  '통화 화면 배경',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '내 폰 배경화면과 비슷한 색을 고르면 더 진짜 같아요.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  children: [
                    for (final background in CallBackground.values)
                      _BackgroundSwatch(
                        background: background,
                        selected: background == current,
                        onTap: () {
                          ref
                              .read(callBackgroundProvider.notifier)
                              .select(background);
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ringtoneMode = ref.watch(ringtoneModeProvider);
    final callBackground = ref.watch(callBackgroundProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: Text(
              '설정',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: ringtoneMode.playsSound
                    ? Icons.music_note_outlined
                    : ringtoneMode.vibrates
                        ? Icons.vibration
                        : Icons.notifications_off_outlined,
                title: '벨소리',
                trailingLabel: ringtoneMode.label,
                onTap: () => _showRingtoneSheet(context, ref),
              ),
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: '통화 화면 배경',
                trailingLabel: callBackground.label,
                onTap: () => _showBackgroundSheet(context, ref),
              ),
              _SettingsTile(
                icon: Icons.record_voice_over_outlined,
                title: 'AI 음성',
                // 아직 내보내지 않은 기능. 고를 수 있는 척하는 대신
                // 나중에 나온다는 것만 알린다.
                trailingLabel: kAiVoiceEnabled ? '켜짐' : null,
                badgeLabel: kAiVoiceEnabled ? null : '출시 예정',
                onTap: null,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: '앱 정보',
                trailingLabel: '버전 1.0.0',
                onTap: null,
                showDivider: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 배경 선택 시트의 견본 하나 — 폰 화면 비율의 작은 그라데이션 카드.
class _BackgroundSwatch extends StatelessWidget {
  const _BackgroundSwatch({
    required this.background,
    required this.selected,
    required this.onTap,
  });

  final CallBackground background;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 112,
            decoration: BoxDecoration(
              gradient: background.gradient,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.surfaceBorder,
                width: selected ? 3 : 1,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            background.label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingLabel,
    this.badgeLabel,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;

  /// 오른쪽에 붙는 현재 값. [badgeLabel] 이 있으면 대개 생략한다.
  final String? trailingLabel;

  /// 아직 나오지 않은 기능임을 알리는 배지 문구.
  final String? badgeLabel;

  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.textSecondary, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (badgeLabel != null) _ComingSoonBadge(label: badgeLabel!),
                  if (trailingLabel != null)
                    Text(
                      trailingLabel!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  if (onTap != null) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.surfaceBorder),
      ],
    );
  }
}

/// "아직 나오지 않은 기능" 배지.
///
/// 회색 보조 텍스트로 적으면 그냥 현재 값처럼 읽히므로, 알약형 배경을 줘서
/// 값이 아니라 상태 표시라는 걸 분명히 한다.
class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}
