// lib/features/receipts/presentation/widgets/receipts_empty_state.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';

/// Reusable empty state view for the receipts screen.
///
/// Supports two distinct states:
/// 1. Pristine / Default state: User has not captured any receipts yet.
/// 2. Filtered state: Search or category filter returned zero results.
class ReceiptsEmptyState extends StatelessWidget {
  const ReceiptsEmptyState({
    super.key,
    this.isFiltered = false,
    this.onClearFilters,
  });

  final bool isFiltered;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = isFiltered ? 'No matching receipts' : 'No receipts yet';
    final subtitle = isFiltered
        ? "We couldn't find any receipts matching your query. Try another search or category."
        : 'Receipts you capture will appear here. Tap + to add your first receipt.';
    final icon = isFiltered
        ? Icons.search_off_outlined
        : Icons.receipt_long_outlined;

    final iconBg = theme.colorScheme.primary.withAlpha(isDark ? 35 : 20);
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: AppShapes.radiusLg,
              ),
              child: Icon(icon, size: 36, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondaryTextColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFiltered && onClearFilters != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                label: const Text('Reset filters'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppShapes.radiusFull,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
