// lib/features/receipts/presentation/widgets/receipt_search_bar.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';

/// Reusable search input field for the receipts screen.
///
/// Follows DESIGN.md specifications:
/// - 8px radius (AppShapes.radiusSm).
/// - White / dark surface fill with subtle border.
/// - Focused border transitions to Primary Blue.
/// - Suffix clear icon when text is entered.
class ReceiptSearchBar extends StatelessWidget {
  const ReceiptSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
    this.hintText = 'Search receipts, items, or stores...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fillColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final hintColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final iconColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: fillColor,
        hintText: hintText,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: hintColor,
          fontSize: 14,
        ),
        prefixIcon: Icon(Icons.search, color: iconColor, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.close, size: 18, color: iconColor),
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                  onClear?.call();
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: AppShapes.radiusSm,
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.radiusSm,
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppShapes.radiusSm,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
