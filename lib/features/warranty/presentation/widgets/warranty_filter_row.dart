// lib/features/warranty/presentation/widgets/warranty_filter_row.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/features/warranty/presentation/providers/warranty_providers.dart';

/// Horizontally scrollable row of pill-shaped filter chips for warranty states.
class WarrantyFilterRow extends StatelessWidget {
  const WarrantyFilterRow({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    this.counts,
  });

  final WarrantyFilter selectedFilter;
  final ValueChanged<WarrantyFilter> onFilterSelected;
  final Map<WarrantyFilter, int>? counts;

  String _labelFor(WarrantyFilter filter) {
    final count = counts?[filter];
    final countSuffix = count != null ? ' ($count)' : '';
    switch (filter) {
      case WarrantyFilter.all:
        return 'All$countSuffix';
      case WarrantyFilter.active:
        return 'Active$countSuffix';
      case WarrantyFilter.expiringSoon:
        return 'Expiring Soon$countSuffix';
      case WarrantyFilter.expired:
        return 'Expired$countSuffix';
    }
  }

  Key _keyFor(WarrantyFilter filter) {
    switch (filter) {
      case WarrantyFilter.all:
        return const Key('warranty_filter_all');
      case WarrantyFilter.active:
        return const Key('warranty_filter_active');
      case WarrantyFilter.expiringSoon:
        return const Key('warranty_filter_expiring_soon');
      case WarrantyFilter.expired:
        return const Key('warranty_filter_expired');
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
        children: WarrantyFilter.values.map((filter) {
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
