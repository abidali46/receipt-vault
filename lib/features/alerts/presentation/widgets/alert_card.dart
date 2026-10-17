// lib/features/alerts/presentation/widgets/alert_card.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/features/alerts/domain/entities/warranty_alert.dart';

/// An individual alert card displaying a warranty event (expiring soon or expired)
/// with category/store subtitle, urgency badge, and progress bar indicator.
class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert, this.onTap});

  final WarrantyAlert alert;
  final VoidCallback? onTap;

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

    final isExpiring = alert.isExpiringSoon;

    // Theme-tailored colors matching mockups
    final Color iconBgColor = isExpiring
        ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7))
        : (isDark
              ? colorScheme.errorContainer.withAlpha(90)
              : const Color(0xFFFEE2E2));

    final Color iconColor = isExpiring ? AppColors.warning : AppColors.error;
    final IconData icon = isExpiring
        ? Icons.warning_amber_rounded
        : Icons.error_outline_rounded;

    final Color badgeBg = isExpiring
        ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7))
        : (isDark
              ? colorScheme.errorContainer.withAlpha(90)
              : const Color(0xFFFEE2E2));

    final Color badgeTextColor = isExpiring
        ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E))
        : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B));

    final Color badgeBorderColor = isExpiring
        ? AppColors.warning.withAlpha(isDark ? 90 : 60)
        : AppColors.error.withAlpha(isDark ? 90 : 60);

    final Color cardBorderColor = isExpiring
        ? AppColors.warning.withAlpha(isDark ? 60 : 30)
        : AppColors.error.withAlpha(isDark ? 60 : 30);

    final Color barColor = isExpiring ? AppColors.warning : AppColors.error;
    final double barWidthFactor = alert.isExpired
        ? 1.0
        : alert.progress.clamp(0.0, 1.0);

    final storeName = alert.storeName?.trim();
    final category = alert.category.trim();
    final subtitle = [
      if (storeName != null && storeName.isNotEmpty) storeName,
      if (category.isNotEmpty) category,
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: AppShapes.radiusMd,
        border: Border.all(color: cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppShapes.radiusMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // 48x48 rounded icon avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 24, color: iconColor),
                ),
                const SizedBox(width: 14),

                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        alert.productName,
                        key: Key('alert_card_title_${alert.receipt.id}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: primaryTextColor,
                          decoration: alert.isExpired
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: secondaryTextColor.withAlpha(120),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle.isNotEmpty ? subtitle : 'Receipt Alert',
                        key: Key('alert_card_subtitle_${alert.receipt.id}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Right column: Urgency Pill + Mini Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      key: Key('alert_card_badge_${alert.receipt.id}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: AppShapes.radiusFull,
                        border: Border.all(color: badgeBorderColor),
                      ),
                      child: Text(
                        alert.urgencyLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeTextColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 96px x 4px mini progress bar
                    Container(
                      width: 96,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceVariantLight,
                        borderRadius: AppShapes.radiusFull,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: barWidthFactor,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
