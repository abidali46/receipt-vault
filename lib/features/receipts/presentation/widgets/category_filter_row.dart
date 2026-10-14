// lib/features/receipts/presentation/widgets/category_filter_row.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';

/// Horizontally scrollable category filter chips row.
///
/// Follows DESIGN.md specifications:
/// - Pill-shaped (AppShapes.radiusFull).
/// - Active: Primary blue fill with white text.
/// - Inactive: Surface container with subtle border and secondary text.
class CategoryFilterRow extends StatelessWidget {
  const CategoryFilterRow({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.categories = const ['All', 'Electronics', 'Food', 'Others'],
  });

  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((category) {
          final isSelected =
              category.toLowerCase() == selectedCategory.toLowerCase();

          final backgroundColor = isSelected
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

          final textColor = isSelected
              ? Colors.white
              : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight);

          final borderColor = isSelected
              ? Colors.transparent
              : (isDark ? AppColors.borderDark : AppColors.borderLight);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: AppShapes.radiusFull,
                onTap: () => onCategorySelected(category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: AppShapes.radiusFull,
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Text(
                    category,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
