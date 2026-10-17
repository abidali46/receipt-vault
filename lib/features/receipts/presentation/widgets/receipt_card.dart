import 'dart:io';

import 'package:flutter/material.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/features/receipts/domain/entities/receipt_card_data.dart';
import 'package:receipt_vault/shared/enums/warranty_status.dart';

/// Reusable card component displaying a receipt item, price, and warranty status.
///
/// Follows the design specifications in DESIGN.md and mockup references:
/// - 8px corner radius with subtle 1px border and ambient shadow.
/// - Left: 48x48 icon circle + product title + store name.
/// - Right: Formatted price + pill status badge with indicator dot.
/// - Expired items show strikethrough text and reduced opacity (0.75).
class ReceiptCard extends StatelessWidget {
  const ReceiptCard({super.key, required this.receipt, this.onTap});

  final ReceiptCardData receipt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExpired = receipt.status == WarrantyStatus.expired;

    // Card colors
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark
        ? AppColors.borderDark
        : AppColors.surfaceVariantLight;
    final iconBg = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    // Status badge configuration
    final _BadgeColors badgeColors = _resolveBadgeColors(
      receipt.status,
      isDark,
    );

    final cardContent = Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppShapes.radiusSm,
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppShapes.radiusSm,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 48x48 Leading thumbnail or category icon
                _buildLeading(iconBg, secondaryTextColor),
                const SizedBox(width: 14),

                // Product & Store details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        receipt.productName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isExpired
                              ? secondaryTextColor
                              : primaryTextColor,
                          decoration: isExpired
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (receipt.storeName != null &&
                          receipt.storeName!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          receipt.storeName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Price & Status Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      receipt.formattedPrice,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isExpired
                            ? secondaryTextColor
                            : primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColors.background,
                        borderRadius: AppShapes.radiusFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: badgeColors.dot,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            receipt.statusLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: badgeColors.text,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isExpired) {
      return Opacity(opacity: 0.75, child: cardContent);
    }

    return cardContent;
  }

  Widget _buildLeading(Color iconBg, Color secondaryTextColor) {
    if (receipt.imagePath != null && receipt.imagePath!.trim().isNotEmpty) {
      final file = File(receipt.imagePath!);
      if (file.existsSync()) {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          clipBehavior: Clip.antiAlias,
          child: Image.file(
            file,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Icon(receipt.icon, size: 24, color: secondaryTextColor),
          ),
        );
      }
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
      child: Icon(receipt.icon, size: 24, color: secondaryTextColor),
    );
  }

  static _BadgeColors _resolveBadgeColors(WarrantyStatus status, bool isDark) {
    switch (status) {
      case WarrantyStatus.active:
        return _BadgeColors(
          dot: AppColors.success,
          background: isDark
              ? AppColors.success.withAlpha(40)
              : AppColors.success.withAlpha(25),
          text: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
        );
      case WarrantyStatus.expiringSoon:
        return _BadgeColors(
          dot: AppColors.error,
          background: isDark
              ? AppColors.error.withAlpha(40)
              : AppColors.error.withAlpha(25),
          text: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
        );
      case WarrantyStatus.expired:
        return _BadgeColors(
          dot: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          background: isDark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
          text: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        );
      case WarrantyStatus.none:
        return _BadgeColors(
          dot: isDark
              ? AppColors.textDisabledDark
              : AppColors.textDisabledLight,
          background: isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariantLight,
          text: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        );
    }
  }
}

class _BadgeColors {
  const _BadgeColors({
    required this.dot,
    required this.background,
    required this.text,
  });

  final Color dot;
  final Color background;
  final Color text;
}
