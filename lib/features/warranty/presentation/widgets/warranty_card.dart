// lib/features/warranty/presentation/widgets/warranty_card.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/features/warranty/domain/entities/warranty_item.dart';
import 'package:receipt_vault/shared/enums/warranty_status.dart';

/// Reusable card displaying an individual warranty item with status badge,
/// key dates, remaining duration, and color-coded progress bar.
class WarrantyCard extends StatelessWidget {
  const WarrantyCard({super.key, required this.item, this.onTap});

  final WarrantyItem item;
  final VoidCallback? onTap;

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = months[date.month - 1];
    return '$m ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    // Badge styling & progress bar color based on centralized WarrantyStatus
    final Color badgeBg;
    final Color badgeText;
    final Color barColor;
    final IconData badgeIcon;
    final Color? cornerGradientColor;

    switch (item.status) {
      case WarrantyStatus.active:
        badgeBg = isDark
            ? colorScheme.tertiaryContainer
            : const Color(0xFFDCFCE7); // subtle green
        badgeText = isDark
            ? colorScheme.onTertiaryContainer
            : const Color(0xFF166534);
        barColor = AppColors.success;
        badgeIcon = Icons.check_circle_outline_rounded;
        cornerGradientColor = null;
        break;

      case WarrantyStatus.expiringSoon:
        badgeBg = isDark
            ? const Color(0xFF78350F)
            : const Color(0xFFFEF3C7); // subtle amber
        badgeText = isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
        barColor = AppColors.warning;
        badgeIcon = Icons.schedule_rounded;
        cornerGradientColor = const Color(
          0xFFF59E0B,
        ).withAlpha(isDark ? 25 : 20);
        break;

      case WarrantyStatus.expired:
        badgeBg = isDark
            ? colorScheme.errorContainer
            : const Color(0xFFFEE2E2); // subtle red
        badgeText = isDark
            ? colorScheme.onErrorContainer
            : const Color(0xFF991B1B);
        barColor = AppColors.error;
        badgeIcon = Icons.warning_amber_rounded;
        cornerGradientColor = AppColors.error.withAlpha(isDark ? 30 : 20);
        break;

      case WarrantyStatus.none:
        badgeBg = isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight;
        badgeText = secondaryTextColor;
        barColor = AppColors.textDisabledLight;
        badgeIcon = Icons.info_outline_rounded;
        cornerGradientColor = null;
        break;
    }

    final storeName = item.receipt.storeName?.trim();
    final categoryName = item.receipt.category?.trim();
    final subtitle = [
      if (storeName != null && storeName.isNotEmpty) storeName,
      if (categoryName != null && categoryName.isNotEmpty) categoryName,
    ].join(' • ');

    final expiryText = item.expiryDate != null
        ? item.status == WarrantyStatus.expired
              ? 'Expired: ${_formatDate(item.expiryDate!)}'
              : 'Expires: ${_formatDate(item.expiryDate!)}'
        : 'No Expiry';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: AppShapes.radiusMd,
        border: Border.all(
          color: item.status == WarrantyStatus.expired
              ? (isDark
                    ? AppColors.error.withAlpha(80)
                    : AppColors.error.withAlpha(40))
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // Subtle gradient overlay for warning/error cards
              if (cornerGradientColor != null)
                Positioned(
                  top: 0,
                  right: 0,
                  width: 120,
                  height: 120,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.2,
                        colors: [cornerGradientColor, Colors.transparent],
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Product Name & Status Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.receipt.productName,
                                key: Key(
                                  'warranty_card_title_${item.receipt.id}',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: primaryTextColor,
                                ),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  key: Key(
                                    'warranty_card_subtitle_${item.receipt.id}',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Status Badge Pill
                        Container(
                          key: Key('warranty_card_badge_${item.receipt.id}'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: AppShapes.radiusFull,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(badgeIcon, size: 14, color: badgeText),
                              const SizedBox(width: 4),
                              Text(
                                item.statusLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: badgeText,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Middle Row: Purchased & Expiry Dates, plus Progress Percentage
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            expiryText,
                            key: Key('warranty_card_expiry_${item.receipt.id}'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: item.status == WarrantyStatus.expired
                                  ? (isDark
                                        ? const Color(0xFFFCA5A5)
                                        : AppColors.error)
                                  : secondaryTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.progressPercentage}%',
                          key: Key('warranty_card_progress_${item.receipt.id}'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: item.status == WarrantyStatus.expired
                                ? (isDark
                                      ? const Color(0xFFFCA5A5)
                                      : AppColors.error)
                                : primaryTextColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Progress Bar
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceVariantLight,
                        borderRadius: AppShapes.radiusFull,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: item.progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: AppShapes.radiusFull,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
