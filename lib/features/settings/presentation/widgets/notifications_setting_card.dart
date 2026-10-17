// lib/features/settings/presentation/widgets/notifications_setting_card.dart
//
// Settings tile for enabling/disabling scheduled warranty notifications
// and requesting platform notification permissions.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/features/settings/presentation/providers/settings_providers.dart';

/// Card tile for managing warranty notification preferences.
class NotificationsSettingCard extends ConsumerWidget {
  const NotificationsSettingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final isEnabled = ref.watch(warrantyNotificationsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer.withAlpha(isDark ? 40 : 20),
            ),
            child: Icon(
              isEnabled
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              color: isEnabled
                  ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  : (isDark
                        ? AppColors.textDisabledDark
                        : AppColors.textDisabledLight),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Warranty Notifications',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Receive reminders 30 days and 7 days before warranties expire',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: secondaryTextColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            key: const Key('settings_warranty_notifications_switch'),
            value: isEnabled,
            activeTrackColor: isDark
                ? AppColors.primaryDark
                : AppColors.primaryLight,
            onChanged: (newValue) async {
              final success = await ref
                  .read(warrantyNotificationsProvider.notifier)
                  .setNotificationsEnabled(newValue);

              if (!context.mounted) return;

              if (newValue && !success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    key: Key(
                      'settings_notifications_permission_denied_snackbar',
                    ),
                    content: Text(
                      'Notification permission is required to schedule warranty reminders. Please enable it in system settings.',
                    ),
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
