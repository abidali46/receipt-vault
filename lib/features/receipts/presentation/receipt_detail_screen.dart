// lib/features/receipts/presentation/receipt_detail_screen.dart
//
// Receipt details screen displaying all saved information for a selected receipt:
// Product name, store, category, purchase date, total amount, warranty status & progress,
// notes, and persistent receipt photo preview. Includes Edit action to update the receipt.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt_vault/app/router/app_router.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/core/storage/receipt_image_service.dart';
import 'package:receipt_vault/features/receipts/domain/repositories/receipts_repository.dart';
import 'package:receipt_vault/features/receipts/domain/services/warranty_calculator.dart';
import 'package:receipt_vault/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:receipt_vault/shared/enums/warranty_status.dart';

/// Screen displaying the full details of a single saved receipt.
class ReceiptDetailScreen extends ConsumerStatefulWidget {
  const ReceiptDetailScreen({
    super.key,
    required this.receiptId,
    this.receipt,
    this.repository,
    this.imageService,
  });

  /// The database ID of the receipt to display.
  final int? receiptId;

  /// Optional static receipt entity (useful for testing or instant display).
  final Receipt? receipt;

  /// Optional repository override for testing.
  final ReceiptsRepository? repository;

  /// Optional image service override for testing.
  final ReceiptImageService? imageService;

  @override
  ConsumerState<ReceiptDetailScreen> createState() =>
      _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends ConsumerState<ReceiptDetailScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    if (_isDeleting) {
      return _buildLoadingState(context);
    }

    // If a static receipt was provided, render it directly.
    if (widget.receipt != null) {
      return _buildContent(context, widget.receipt!);
    }

    // Invalid ID state.
    if (widget.receiptId == null) {
      return _buildNotFoundState(context);
    }

    // If a custom repository is passed (e.g. in tests), query it via a StreamBuilder.
    if (widget.repository != null) {
      return StreamBuilder<Receipt?>(
        stream: widget.repository!.watchReceiptById(widget.receiptId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(context);
          }
          if (snapshot.hasError) {
            return _buildErrorState(context, snapshot.error!);
          }
          final loaded = snapshot.data;
          if (loaded == null) {
            return _buildNotFoundState(context);
          }
          return _buildContent(context, loaded);
        },
      );
    }

    final asyncReceipt = ref.watch(
      receiptDetailStreamProvider(widget.receiptId!),
    );

    return asyncReceipt.when(
      data: (loaded) {
        if (loaded == null) {
          return _buildNotFoundState(context);
        }
        return _buildContent(context, loaded);
      },
      loading: () => _buildLoadingState(context),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Details'),
        leading: BackButton(
          key: const Key('receipt_detail_back_button'),
          onPressed: () => _handleBack(context),
        ),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Details'),
        leading: BackButton(
          key: const Key('receipt_detail_back_button'),
          onPressed: () => _handleBack(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: isDark
                    ? AppColors.textDisabledDark
                    : AppColors.textDisabledLight,
              ),
              const SizedBox(height: 16),
              Text(
                'Receipt Not Found',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This receipt does not exist or has been removed.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                key: const Key('receipt_detail_not_found_back_button'),
                onPressed: () => _handleBack(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to Receipts'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimary,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppShapes.radiusFull,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Details'),
        leading: BackButton(
          key: const Key('receipt_detail_back_button'),
          onPressed: () => _handleBack(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load receipt details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _handleBack(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to Receipts'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Receipt item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final warrantyInfo = WarrantyCalculator.calculate(
      purchaseDate: item.purchaseDate,
      warrantyDurationDays: item.warrantyDurationDays,
    );

    return PopScope(
      canPop: !_isDeleting,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Receipt Details'),
          leading: BackButton(
            key: const Key('receipt_detail_back_button'),
            onPressed: _isDeleting ? null : () => _handleBack(context),
          ),
          actions: [
            IconButton(
              key: const Key('receipt_detail_app_bar_delete_button'),
              tooltip: 'Delete Receipt',
              icon: const Icon(Icons.delete_outline_rounded),
              color: colorScheme.error,
              onPressed: _isDeleting ? null : () => _confirmAndDelete(item),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header Section: Product Title & Badges
                    _buildHeaderSection(
                      item,
                      warrantyInfo,
                      theme,
                      colorScheme,
                      isDark,
                      primaryTextColor,
                      secondaryTextColor,
                    ),
                    const SizedBox(height: 20),

                    // 2. Photo Section (where available)
                    if (item.imagePath != null) ...[
                      _buildPhotoSection(
                        context,
                        item.imagePath!,
                        isDark,
                        colorScheme,
                        theme,
                        secondaryTextColor,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 3. Details Card
                    _buildDetailsCard(
                      item,
                      warrantyInfo,
                      isDark,
                      colorScheme,
                      theme,
                      primaryTextColor,
                      secondaryTextColor,
                    ),
                    const SizedBox(height: 24),

                    // 4. Action Section (Edit & Delete Buttons)
                    _buildActionsSection(context, item, colorScheme, isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
    Receipt item,
    WarrantyInfo warrantyInfo,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.productName,
          key: const Key('receipt_detail_product_name'),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Warranty Status Badge
            _buildWarrantyBadge(warrantyInfo, colorScheme, isDark),

            // Category Chip
            _buildCategoryChip(
              item.category ?? 'Others',
              colorScheme,
              isDark,
              secondaryTextColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWarrantyBadge(
    WarrantyInfo warrantyInfo,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    Color dotColor;
    Color bgColor;
    Color textColor;

    switch (warrantyInfo.status) {
      case WarrantyStatus.active:
        dotColor = AppColors.success;
        bgColor = colorScheme.tertiaryContainer;
        textColor = colorScheme.onTertiaryContainer;
        break;
      case WarrantyStatus.expiringSoon:
        dotColor = AppColors.warning;
        bgColor = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
        textColor = isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
        break;
      case WarrantyStatus.expired:
        dotColor = AppColors.error;
        bgColor = colorScheme.errorContainer;
        textColor = colorScheme.onErrorContainer;
        break;
      case WarrantyStatus.none:
        dotColor = isDark
            ? AppColors.textDisabledDark
            : AppColors.textDisabledLight;
        bgColor = isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight;
        textColor = isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight;
        break;
    }

    return Container(
      key: const Key('receipt_detail_warranty_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppShapes.radiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            warrantyInfo.statusLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    String category,
    ColorScheme colorScheme,
    bool isDark,
    Color secondaryTextColor,
  ) {
    final icon = WarrantyCalculator.iconForCategory(category);

    return Container(
      key: const Key('receipt_detail_category_chip'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: AppShapes.radiusFull,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: secondaryTextColor),
          const SizedBox(width: 5),
          Text(
            category,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(
    BuildContext context,
    String imagePath,
    bool isDark,
    ColorScheme colorScheme,
    ThemeData theme,
    Color secondaryTextColor,
  ) {
    final file = File(imagePath);
    final fileExists = file.existsSync();

    if (!fileExists) {
      return _buildMissingPhotoFallback(isDark, colorScheme, theme);
    }

    return Container(
      key: const Key('receipt_detail_photo_container'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
        borderRadius: AppShapes.radiusMd,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildMissingPhotoFallback(isDark, colorScheme, theme);
          },
        ),
      ),
    );
  }

  Widget _buildMissingPhotoFallback(
    bool isDark,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      key: const Key('receipt_detail_photo_missing_fallback'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
        borderRadius: AppShapes.radiusMd,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: isDark
                ? AppColors.textDisabledDark
                : AppColors.textDisabledLight,
          ),
          const SizedBox(height: 8),
          Text(
            'Photo not available on this device',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The photo file was moved, deleted, or cannot be accessed.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(
    Receipt item,
    WarrantyInfo warrantyInfo,
    bool isDark,
    ColorScheme colorScheme,
    ThemeData theme,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final formattedPrice = item.totalAmount == item.totalAmount.roundToDouble()
        ? '\$${item.totalAmount.toInt()}'
        : '\$${item.totalAmount.toStringAsFixed(2)}';

    return Container(
      key: const Key('receipt_detail_info_card'),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: AppShapes.radiusMd,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Store & Price Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STORE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.storeName?.isNotEmpty == true
                          ? item.storeName!
                          : '—',
                      key: const Key('receipt_detail_store_name'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PRICE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedPrice,
                    key: const Key('receipt_detail_price'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          const SizedBox(height: 16),

          // Two-column details grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDetailField(
                  icon: Icons.calendar_today_outlined,
                  label: 'PURCHASE DATE',
                  value: _formatDate(item.purchaseDate),
                  valueKey: const Key('receipt_detail_purchase_date'),
                  theme: theme,
                  primaryText: primaryTextColor,
                  secondaryText: secondaryTextColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailField(
                  icon: Icons.timer_outlined,
                  label: 'WARRANTY DURATION',
                  value: _formatDuration(item.warrantyDurationDays),
                  valueKey: const Key('receipt_detail_warranty_duration'),
                  theme: theme,
                  primaryText: primaryTextColor,
                  secondaryText: secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDetailField(
                  icon: Icons.event_busy_outlined,
                  label: 'EXPIRY DATE',
                  value: warrantyInfo.expiryDate != null
                      ? _formatDate(warrantyInfo.expiryDate!)
                      : 'None',
                  valueKey: const Key('receipt_detail_expiry_date'),
                  theme: theme,
                  primaryText: primaryTextColor,
                  secondaryText: secondaryTextColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailField(
                  icon: WarrantyCalculator.iconForCategory(item.category),
                  label: 'CATEGORY',
                  value: item.category ?? 'Others',
                  valueKey: const Key('receipt_detail_category_value'),
                  theme: theme,
                  primaryText: primaryTextColor,
                  secondaryText: secondaryTextColor,
                ),
              ),
            ],
          ),

          // Notes Section (if notes are present)
          if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notes_outlined,
                      size: 14,
                      color: secondaryTextColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'NOTES',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.notes!,
                  key: const Key('receipt_detail_notes'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: primaryTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ],

          // Warranty Progress Bar (when warranty is active / expired)
          if (item.warrantyDurationDays != null &&
              item.warrantyDurationDays! > 0) ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            const SizedBox(height: 16),
            _buildWarrantyProgressBar(
              item,
              warrantyInfo,
              theme,
              colorScheme,
              isDark,
              secondaryTextColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailField({
    required IconData icon,
    required String label,
    required String value,
    required Key valueKey,
    required ThemeData theme,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: secondaryText),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: secondaryText,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          key: valueKey,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: primaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWarrantyProgressBar(
    Receipt item,
    WarrantyInfo warrantyInfo,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    Color secondaryTextColor,
  ) {
    final progress = warrantyInfo.progress;

    Color progressColor;
    String statusTitle;
    switch (warrantyInfo.status) {
      case WarrantyStatus.active:
        progressColor = AppColors.success;
        statusTitle = 'Active';
        break;
      case WarrantyStatus.expiringSoon:
        progressColor = AppColors.warning;
        statusTitle = 'Expiring Soon';
        break;
      case WarrantyStatus.expired:
        progressColor = AppColors.error;
        statusTitle = 'Expired';
        break;
      case WarrantyStatus.none:
        progressColor = secondaryTextColor;
        statusTitle = 'None';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'WARRANTY PROGRESS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: secondaryTextColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            Text(
              statusTitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: AppShapes.radiusFull,
          child: LinearProgressIndicator(
            key: const Key('receipt_detail_warranty_progress_bar'),
            value: progress,
            minHeight: 6,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            backgroundColor: isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariantLight,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(
    BuildContext context,
    Receipt item,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 380;

        final editButton = SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            key: const Key('receipt_detail_edit_button'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: AppShapes.radiusFull,
              ),
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text(
              'Edit Details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            onPressed: _isDeleting ? null : () => _handleEdit(item),
          ),
        );

        final deleteButton = SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            key: const Key('receipt_detail_delete_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: AppShapes.radiusFull,
              ),
            ),
            icon: _isDeleting
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onErrorContainer,
                      ),
                    ),
                  )
                : const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(
              _isDeleting ? 'Deleting...' : 'Delete Receipt',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            onPressed: _isDeleting ? null : () => _confirmAndDelete(item),
          ),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: editButton),
              const SizedBox(width: 12),
              Expanded(child: deleteButton),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [editButton, const SizedBox(height: 12), deleteButton],
        );
      },
    );
  }

  Future<void> _handleEdit(Receipt item) async {
    await context.push(AppRoutes.editReceiptPath(item.id), extra: item);
  }

  Future<bool> _showDeleteConfirmationDialog(
    BuildContext dialogContext,
    Receipt item,
  ) async {
    final theme = Theme.of(dialogContext);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: dialogContext,
      barrierDismissible: !_isDeleting,
      builder: (ctx) {
        return AlertDialog(
          key: const Key('receipt_detail_delete_dialog'),
          shape: const RoundedRectangleBorder(borderRadius: AppShapes.radiusLg),
          backgroundColor: isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Delete Receipt',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${item.productName}"?\n\nThis action will permanently remove the receipt and cannot be undone.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            TextButton(
              key: const Key('receipt_detail_delete_cancel_button'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              key: const Key('receipt_detail_delete_confirm_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppShapes.radiusFull,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _confirmAndDelete(Receipt item) async {
    if (_isDeleting) return;

    final confirmed = await _showDeleteConfirmationDialog(context, item);
    if (!confirmed || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final ReceiptsRepository repository =
          widget.repository ?? ref.read(receiptsRepositoryProvider);
      final ReceiptImageService imageService =
          widget.imageService ?? ref.read(receiptImageServiceProvider);

      final imagePath = item.imagePath;

      // 1. Delete database record
      final affectedRows = await repository.deleteReceipt(item.id);
      if (affectedRows <= 0) {
        throw Exception(
          'Receipt record could not be found or was already deleted.',
        );
      }

      // 2. Safe image cleanup: never delete if another receipt references it.
      if (imagePath != null && imagePath.trim().isNotEmpty) {
        try {
          await imageService.deleteImageIfUnreferenced(
            imagePath,
            repository: repository,
          );
        } catch (_) {
          // If safe cleanup cannot be guaranteed, leave the unused file
          // rather than risk deleting an image still in use.
        }
      }

      if (!mounted || !context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt deleted successfully.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );

      _handleBack();
    } catch (error) {
      if (!mounted || !context.mounted) return;

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete receipt: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleBack([BuildContext? ctx]) {
    final effectiveContext = ctx ?? (mounted ? context : null);
    if (effectiveContext == null || !effectiveContext.mounted) return;

    if (Navigator.of(effectiveContext).canPop()) {
      Navigator.of(effectiveContext).pop();
    } else {
      effectiveContext.go(AppRoutes.receipts);
    }
  }

  String _formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDuration(int? days) {
    if (days == null || days <= 0) return 'None';
    if (days == 365) return '1 Year';
    if (days == 730) return '2 Years';
    if (days == 1095) return '3 Years';
    if (days == 180) return '6 Months';
    if (days % 365 == 0) return '${days ~/ 365} Years';
    return '$days Days';
  }
}
