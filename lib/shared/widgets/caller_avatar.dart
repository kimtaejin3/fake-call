import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A circular avatar showing the caller's first-name initial on a soft
/// accent-gradient background.
///
/// Replaces emoji avatars, which render as tofu (□) glyphs on web/desktop
/// when no emoji-capable font is installed, and which read as "toy-like"
/// rather than the calm, premium voice-AI feel this app is going for.
class CallerAvatar extends StatelessWidget {
  const CallerAvatar({super.key, required this.name, this.size = 96});

  /// Full display name; only the first character is shown.
  final String name;

  /// Diameter of the circular avatar.
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    // Use `runes` (not `[0]`) so a surrogate-pair code point isn't cut in
    // half; good enough grapheme-safety without a new package dependency.
    final initial =
        trimmed.isNotEmpty ? String.fromCharCode(trimmed.runes.first) : '?';

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceBorder),
        gradient: RadialGradient(
          colors: [
            for (final color in AppColors.accentGradient)
              color.withValues(alpha: 0.20),
          ],
        ),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.accent,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
