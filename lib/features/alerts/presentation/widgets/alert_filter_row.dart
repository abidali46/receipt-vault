// lib/features/alerts/presentation/widgets/alert_filter_row.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/features/alerts/presentation/providers/alerts_providers.dart';

/// Horizontally scrollable row of pill-shaped filter chips for alert states.
class AlertFilterRow extends StatelessWidget {
  const AlertFilterRow({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    this.counts,
  });

  final AlertFilter selectedFilter;
  final ValueChanged<AlertFilter> onFilterSelected;
  final Map<AlertFilter, int>? counts;

  String _labelFor(AlertFilter filter) {
    final count = counts?[filter];
    final countSuffix = count != null ? ' ($count)' : '';
    switch (filter) {
      case AlertFilter.all:
        return 'All$countSuffix';
      case AlertFilter.expiringSoon:
        return 'Expiring Soon$countSuffix';
      case AlertFilter.expired:
        return 'Expired$countSuffix';
    }
  }

  Key _keyFor(AlertFilter filter) {
    switch (filter) {
      case AlertFilter.all:
        return const Key('alert_filter_all');
      case AlertFilter.expiringSoon:
        return const Key('alert_filter_expiring_soon');
      case AlertFilter.expired:
        return const Key('alert_filter_expired');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: AlertFilter.values.map((filter) {
          final isSelected = filter == selectedFilter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              key: _keyFor(filter),
              label: Text(
                _labelFor(filter),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: AppColors.primaryContainer,
              backgroundColor: isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceLight,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primaryContainer
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: 1,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: AppShapes.radiusFull,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              onSelected: (_) => onFilterSelected(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}
