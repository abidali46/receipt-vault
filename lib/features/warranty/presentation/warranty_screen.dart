// lib/features/warranty/presentation/warranty_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt_vault/app/router/app_router.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/features/receipts/domain/repositories/receipts_repository.dart';
import 'package:receipt_vault/features/warranty/domain/entities/warranty_item.dart';
import 'package:receipt_vault/features/warranty/presentation/providers/warranty_providers.dart';
import 'package:receipt_vault/features/warranty/presentation/widgets/warranty_card.dart';
import 'package:receipt_vault/features/warranty/presentation/widgets/warranty_empty_state.dart';
import 'package:receipt_vault/features/warranty/presentation/widgets/warranty_filter_row.dart';
import 'package:receipt_vault/shared/enums/warranty_status.dart';

/// Screen displaying all receipts with an attached warranty, grouped/filtered
/// by status (Active, Expiring Soon, Expired), with remaining progress bars.
class WarrantyScreen extends ConsumerStatefulWidget {
  const WarrantyScreen({super.key, this.initialItems, this.repository});

  /// Optional static items fixture for hermetic widget testing.
  final List<WarrantyItem>? initialItems;

  /// Optional repository override for hermetic widget testing.
  final ReceiptsRepository? repository;

  @override
  ConsumerState<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends ConsumerState<WarrantyScreen> {
  WarrantyFilter _selectedFilter = WarrantyFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final Widget bodyContent;
    if (widget.initialItems != null) {
      bodyContent = _buildContent(
        context,
        widget.initialItems!,
        theme,
        isDark,
        primaryTextColor,
        secondaryTextColor,
      );
    } else if (widget.repository != null) {
      bodyContent = StreamBuilder<List<WarrantyItem>>(
        stream: widget.repository!.watchReceipts().map(
          (receipts) => filterAndSortWarrantyItems(receipts),
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorBody(
              context,
              snapshot.error.toString(),
              theme,
              isDark,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildContent(
            context,
            snapshot.data!,
            theme,
            isDark,
            primaryTextColor,
            secondaryTextColor,
          );
        },
      );
    } else {
      final warrantiesAsync = ref.watch(warrantiesStreamProvider);
      bodyContent = warrantiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _buildErrorBody(context, error.toString(), theme, isDark),
        data: (items) => _buildContent(
          context,
          items,
          theme,
          isDark,
          primaryTextColor,
          secondaryTextColor,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.verified_user_outlined,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              size: 26,
            ),
            const SizedBox(width: 8),
            const Text(
              'Active Warranties',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: SafeArea(child: bodyContent),
    );
  }

  Widget _buildErrorBody(
    BuildContext context,
    String error,
    ThemeData theme,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load warranties',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<WarrantyItem> allItems,
    ThemeData theme,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    // Calculate counts for each filter category
    final activeCount = allItems
        .where((i) => i.status == WarrantyStatus.active)
        .length;
    final expiringCount = allItems
        .where((i) => i.status == WarrantyStatus.expiringSoon)
        .length;
    final expiredCount = allItems
        .where((i) => i.status == WarrantyStatus.expired)
        .length;

    final counts = {
      WarrantyFilter.all: allItems.length,
      WarrantyFilter.active: activeCount,
      WarrantyFilter.expiringSoon: expiringCount,
      WarrantyFilter.expired: expiredCount,
    };

    // Filter displayed items
    final List<WarrantyItem> filteredItems;
    switch (_selectedFilter) {
      case WarrantyFilter.all:
        filteredItems = allItems;
        break;
      case WarrantyFilter.active:
        filteredItems = allItems
            .where((i) => i.status == WarrantyStatus.active)
            .toList();
        break;
      case WarrantyFilter.expiringSoon:
        filteredItems = allItems
            .where((i) => i.status == WarrantyStatus.expiringSoon)
            .toList();
        break;
      case WarrantyFilter.expired:
        filteredItems = allItems
            .where((i) => i.status == WarrantyStatus.expired)
            .toList();
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),

        // Filter Chips Row
        WarrantyFilterRow(
          selectedFilter: _selectedFilter,
          onFilterSelected: (filter) {
            setState(() {
              _selectedFilter = filter;
            });
          },
          counts: counts,
        ),

        const SizedBox(height: 12),

        // Status Summary Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$activeCount Active',
                key: const Key('warranty_summary_active_count'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (expiringCount > 0)
                Text(
                  '$expiringCount Expiring Soon',
                  key: const Key('warranty_summary_expiring_count'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // List or Empty State
        Expanded(
          child: filteredItems.isEmpty
              ? WarrantyEmptyState(
                  filter: _selectedFilter,
                  onResetFilter: () {
                    setState(() {
                      _selectedFilter = WarrantyFilter.all;
                    });
                  },
                  onAddReceipt: () {
                    context.push(AppRoutes.add);
                  },
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView.builder(
                      key: const Key('warranty_items_list'),
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return WarrantyCard(
                          key: Key('warranty_card_${item.receipt.id}'),
                          item: item,
                          onTap: () {
                            context.push(
                              AppRoutes.receiptDetailPath(item.receipt.id),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
