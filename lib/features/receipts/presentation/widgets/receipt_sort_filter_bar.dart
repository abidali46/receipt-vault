// lib/features/receipts/presentation/widgets/receipt_sort_filter_bar.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/features/receipts/domain/entities/receipt_sort_option.dart';

/// Reusable bar displaying receipt count, active filter indicator with reset action,
/// and a sorting selection popup menu.
class ReceiptSortFilterBar extends StatelessWidget {
  const ReceiptSortFilterBar({
    super.key,
    required this.filteredCount,
    required this.totalCount,
    required this.isFiltered,
    required this.selectedSort,
    required this.onSortSelected,
    required this.onResetFilters,
  });

  /// The number of receipts currently displayed after filtering.
  final int filteredCount;

  /// The total number of receipts available before filtering.
  final int totalCount;

  /// Whether filtering (search or category) is currently active.
  final bool isFiltered;

  /// The currently applied sort strategy.
  final ReceiptSortOption selectedSort;

  /// Callback when a new sort option is selected.
  final ValueChanged<ReceiptSortOption> onSortSelected;

  /// Callback to reset all search queries and category filters.
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;

    final countLabel = isFiltered
        ? '$filteredCount of $totalCount receipts'
        : '$totalCount ${totalCount == 1 ? 'receipt' : 'receipts'}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Result Count & Inline Clear Button
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  countLabel,
                  key: const Key('receipts_results_count_label'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isFiltered) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('receipts_bar_clear_button'),
                      borderRadius: AppShapes.radiusFull,
                      onTap: onResetFilters,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          borderRadius: AppShapes.radiusFull,
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.close_rounded,
                              size: 13,
                              color: secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Clear',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Right: Sort Selection PopupMenuButton
          PopupMenuButton<ReceiptSortOption>(
            key: const Key('receipts_sort_button'),
            tooltip: 'Sort receipts',
            initialValue: selectedSort,
            onSelected: onSortSelected,
            position: PopupMenuPosition.under,
            shape: const RoundedRectangleBorder(
              borderRadius: AppShapes.radiusMd,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: AppShapes.radiusFull,
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sort_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    selectedSort.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
            itemBuilder: (context) {
              return ReceiptSortOption.values.map((option) {
                final isSelected = option == selectedSort;
                return PopupMenuItem<ReceiptSortOption>(
                  value: option,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? colorScheme.primary : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }
}
