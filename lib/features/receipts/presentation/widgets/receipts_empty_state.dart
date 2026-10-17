// lib/features/receipts/presentation/widgets/receipts_empty_state.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';

/// Reusable empty state view for the receipts screen.
///
/// Supports two distinct states:
/// 1. Pristine / Default state: User has not captured any receipts yet.
/// 2. Filtered state: Search or category filter returned zero results, explaining
///    what criteria were applied and offering a reset action.
class ReceiptsEmptyState extends StatelessWidget {
  const ReceiptsEmptyState({
    super.key,
    this.isFiltered = false,
    this.searchQuery,
    this.selectedCategory,
    this.onClearFilters,
  });

  /// Whether the empty state is due to active filters/search or an empty database.
  final bool isFiltered;

  /// The active search query that yielded zero results.
  final String? searchQuery;

  /// The active category filter that yielded zero results.
  final String? selectedCategory;

  /// Callback to reset all search queries and filters.
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = isFiltered ? 'No matching receipts' : 'No receipts yet';

    final String subtitle;
    if (!isFiltered) {
      subtitle =
          'Receipts you capture will appear here. Tap + to add your first receipt.';
    } else {
      final hasSearch = searchQuery != null && searchQuery!.trim().isNotEmpty;
      final hasCategory =
          selectedCategory != null &&
          selectedCategory!.trim().toLowerCase() != 'all';

      if (hasSearch && hasCategory) {
        subtitle =
            'No receipts found matching "${searchQuery!.trim()}" in category "${selectedCategory!.trim()}". Try another search or reset filters.';
      } else if (hasSearch) {
        subtitle =
            'No receipts found matching "${searchQuery!.trim()}". Try another search term or reset filters.';
      } else if (hasCategory) {
        subtitle =
            'No receipts found in category "${selectedCategory!.trim()}". Try another category or reset filters.';
      } else {
        subtitle =
            "We couldn't find any receipts matching your query. Try another search or category.";
      }
    }

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
                key: const Key('receipts_empty_state_reset_button'),
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
