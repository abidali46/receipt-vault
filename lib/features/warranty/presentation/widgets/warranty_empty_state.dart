// lib/features/warranty/presentation/widgets/warranty_empty_state.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/features/warranty/presentation/providers/warranty_providers.dart';

/// Context-aware empty state for the Warranties screen based on current filter.
class WarrantyEmptyState extends StatelessWidget {
  const WarrantyEmptyState({
    super.key,
    required this.filter,
    this.onResetFilter,
    this.onAddReceipt,
  });

  final WarrantyFilter filter;
  final VoidCallback? onResetFilter;
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
      case WarrantyFilter.all:
        icon = Icons.verified_outlined;
        title = 'No Warranties Tracked';
        subtitle =
            'Receipts with a warranty duration will appear here. Add your first warranty by saving a receipt with a warranty duration.';
        buttonLabel = 'Add Receipt';
        buttonAction = onAddReceipt;
        actionKey = const Key('warranty_empty_add_button');
        break;

      case WarrantyFilter.active:
        icon = Icons.verified_user_outlined;
        title = 'No Active Warranties';
        subtitle = 'You do not have any active warranties at the moment.';
        buttonLabel = 'View All Warranties';
        buttonAction = onResetFilter;
        actionKey = const Key('warranty_empty_reset_button');
        break;

      case WarrantyFilter.expiringSoon:
        icon = Icons.schedule_outlined;
        title = 'No Warranties Expiring Soon';
        subtitle =
            'Great news! None of your tracked warranties are expiring within the next 30 days.';
        buttonLabel = 'View All Warranties';
        buttonAction = onResetFilter;
        actionKey = const Key('warranty_empty_reset_button');
        break;

      case WarrantyFilter.expired:
        icon = Icons.history_outlined;
        title = 'No Expired Warranties';
        subtitle = 'None of your tracked warranties have expired.';
        buttonLabel = 'View All Warranties';
        buttonAction = onResetFilter;
        actionKey = const Key('warranty_empty_reset_button');
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
