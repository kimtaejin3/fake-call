import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../history/presentation/history_tab.dart';
import '../../home/presentation/home_tab.dart';
import '../../settings/presentation/settings_tab.dart';

/// App shell: bottom-navigation host for the three main tabs (홈/기록/설정).
///
/// Uses [IndexedStack] so switching tabs preserves each tab's scroll
/// position and state instead of rebuilding it from scratch.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  static const _tabs = [
    HomeTab(),
    HistoryTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.accent.withValues(alpha: 0.16),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            );
          }),
          destinations: [
            NavigationDestination(
              icon: const Icon(
                Icons.phone_in_talk_outlined,
                color: AppColors.textSecondary,
              ),
              selectedIcon: const Icon(
                Icons.phone_in_talk,
                color: AppColors.accent,
              ),
              label: '홈',
            ),
            NavigationDestination(
              icon: const Icon(
                Icons.history,
                color: AppColors.textSecondary,
              ),
              selectedIcon: const Icon(
                Icons.history,
                color: AppColors.accent,
              ),
              label: '기록',
            ),
            NavigationDestination(
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.textSecondary,
              ),
              selectedIcon: const Icon(
                Icons.settings,
                color: AppColors.accent,
              ),
              label: '설정',
            ),
          ],
        ),
      ),
    );
  }
}
