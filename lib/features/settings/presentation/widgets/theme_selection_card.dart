// lib/features/settings/presentation/widgets/theme_selection_card.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';

/// Card containing selectable tiles for System Default, Light, and Dark theme modes.
class ThemeSelectionCard extends StatelessWidget {
  const ThemeSelectionCard({
    super.key,
    required this.currentThemeMode,
    required this.onThemeChanged,
  });

  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final items = [
      (
        mode: ThemeMode.system,
        title: 'System Default',
        subtitle: 'Match device appearance settings',
        icon: Icons.brightness_auto_rounded,
        key: const Key('settings_theme_system'),
      ),
      (
        mode: ThemeMode.light,
        title: 'Light',
        subtitle: 'Always use clean light appearance',
        icon: Icons.light_mode_rounded,
        key: const Key('settings_theme_light'),
      ),
      (
        mode: ThemeMode.dark,
        title: 'Dark',
        subtitle: 'Always use sleek dark appearance',
        icon: Icons.dark_mode_rounded,
        key: const Key('settings_theme_dark'),
      ),
    ];

    return RadioGroup<ThemeMode>(
      groupValue: currentThemeMode,
      onChanged: (mode) {
        if (mode != null) onThemeChanged(mode);
      },
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _ThemeTile(
              key: items[i].key,
              mode: items[i].mode,
              title: items[i].title,
              subtitle: items[i].subtitle,
              icon: items[i].icon,
              isSelected: items[i].mode == currentThemeMode,
              onTap: () => onThemeChanged(items[i].mode),
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
            if (i < items.length - 1)
              Divider(
                height: 1,
                indent: 68,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
          ],
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    super.key,
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.isDark,
  });

  final ThemeMode mode;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primaryContainer.withAlpha(isDark ? 50 : 25)
                    : (isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariantLight),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? (isDark
                          ? AppColors.primaryLight
                          : AppColors.primaryContainer)
                    : secondaryTextColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: primaryTextColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Radio<ThemeMode>(
              value: mode,
              activeColor: AppColors.primaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}
