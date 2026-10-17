// lib/features/alerts/presentation/widgets/alerts_empty_state.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/features/alerts/presentation/providers/alerts_providers.dart';

/// Context-aware empty state for the Alerts screen based on current filter.
class AlertsEmptyState extends StatelessWidget {
  const AlertsEmptyState({
    super.key,
    required this.filter,
    this.onResetFilter,
    this.onViewWarranties,
    this.onAddReceipt,
  });

  final AlertFilter filter;
  final VoidCallback? onResetFilter;
  final VoidCallback? onViewWarranties;
  final VoidCallback? onAddReceipt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final IconData icon;
    final String title;
    final String subtitle;
    final String buttonLabel;
    final VoidCallback? buttonAction;
    final Key actionKey;

    switch (filter) {
      case AlertFilter.all:
        icon = Icons.notifications_none_rounded;
        title = 'All Clear';
        subtitle =
            'No active warranty alerts. We\'ll notify you here when warranties are approaching expiration or have recently expired.';
        if (onViewWarranties != null) {
          buttonLabel = 'View Warranties';
          buttonAction = onViewWarranties;
          actionKey = const Key('alerts_empty_view_warranties_button');
        } else {
          buttonLabel = 'Add Receipt';
          buttonAction = onAddReceipt;
          actionKey = const Key('alerts_empty_add_button');
        }
        break;

      case AlertFilter.expiringSoon:
        icon = Icons.schedule_outlined;
        title = 'No Warranties Expiring Soon';
        subtitle =
            'Great news! None of your tracked warranties are expiring within the next 30 days.';
        buttonLabel = 'View All Alerts';
        buttonAction = onResetFilter;
        actionKey = const Key('alerts_empty_reset_button');
        break;

      case AlertFilter.expired:
        icon = Icons.history_outlined;
        title = 'No Expired Warranties';
        subtitle =
            'None of your tracked warranties have expired in the past 90 days.';
        buttonLabel = 'View All Alerts';
        buttonAction = onResetFilter;
        actionKey = const Key('alerts_empty_reset_button');
        break;
    }

    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariantLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.primaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondaryTextColor,
                height: 1.4,
              ),
            ),
            if (buttonAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                key: actionKey,
                onPressed: buttonAction,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppShapes.radiusFull,
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
