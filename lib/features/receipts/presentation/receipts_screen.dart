// lib/features/receipts/presentation/receipts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt_vault/app/router/app_router.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/features/receipts/domain/entities/receipt_card_data.dart';
import 'package:receipt_vault/features/receipts/domain/entities/receipt_sort_option.dart';
import 'package:receipt_vault/features/receipts/domain/services/receipt_discovery_service.dart';
import 'package:receipt_vault/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/category_filter_row.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/receipt_card.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/receipt_search_bar.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/receipt_sort_filter_bar.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/receipts_empty_state.dart';

/// Screen displaying the user's receipts with real-time search, category filtering,
/// multiple sorting options, and receipt card listing or contextual empty states.
///
/// Follows DESIGN.md specifications and the updated 5-tab mockup.
/// Connects reactively to [receiptsStreamProvider] by default.
class ReceiptsScreen extends ConsumerStatefulWidget {
  const ReceiptsScreen({
    super.key,
    this.receipts,
    this.onReceiptTap,
    this.initialSort = ReceiptSortOption.newestPurchase,
  });

  /// Optional receipts list. If provided, this list is used directly instead
  /// of watching [receiptsStreamProvider] (useful for tests with static data).
  final List<ReceiptCardData>? receipts;

  /// Optional callback invoked when a receipt card is tapped.
  final ValueChanged<ReceiptCardData>? onReceiptTap;

  /// Optional initial sorting strategy.
  final ReceiptSortOption initialSort;

  @override
  ConsumerState<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends ConsumerState<ReceiptsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late ReceiptSortOption _selectedSort;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  static const List<String> _categories = [
    'All',
    'Electronics',
    'Food',
    'Clothing',
    'Home',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.initialSort;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
  }

  void _onSortSelected(ReceiptSortOption sortOption) {
    setState(() {
      _selectedSort = sortOption;
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = 'All';
    });
  }

  bool get _isFiltered =>
      _searchQuery.isNotEmpty || _selectedCategory.toLowerCase() != 'all';

  Widget _buildContent(List<ReceiptCardData> allReceipts) {
    final filteredAndSorted = ReceiptDiscoveryService.filterAndSortReceipts(
      allReceipts,
      selectedCategory: _selectedCategory,
      searchQuery: _searchQuery,
      sortOption: _selectedSort,
    );

    final totalCount = allReceipts.length;
    final filteredCount = filteredAndSorted.length;

    // Completely empty database
    if (totalCount == 0 && !_isFiltered) {
      return ReceiptsEmptyState(
        isFiltered: false,
        onClearFilters: _resetFilters,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (totalCount > 0)
          ReceiptSortFilterBar(
            filteredCount: filteredCount,
            totalCount: totalCount,
            isFiltered: _isFiltered,
            selectedSort: _selectedSort,
            onSortSelected: _onSortSelected,
            onResetFilters: _resetFilters,
          ),
        const SizedBox(height: 8),
        Expanded(
          child: filteredCount == 0
              ? ReceiptsEmptyState(
                  isFiltered: true,
                  searchQuery: _searchQuery,
                  selectedCategory: _selectedCategory,
                  onClearFilters: _resetFilters,
                )
              : ListView.separated(
                  itemCount: filteredCount,
                  padding: const EdgeInsets.only(bottom: 24),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final receipt = filteredAndSorted[index];
                    return ReceiptCard(
                      receipt: receipt,
                      onTap: () {
                        if (widget.onReceiptTap != null) {
                          widget.onReceiptTap!(receipt);
                        } else {
                          final id = int.tryParse(receipt.id);
                          if (id != null) {
                            context.push(AppRoutes.receiptDetailPath(id));
                          }
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load receipts',
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget bodyContent;
    if (widget.receipts != null) {
      bodyContent = _buildContent(widget.receipts!);
    } else {
      final receiptsAsync = ref.watch(receiptsStreamProvider);
      bodyContent = receiptsAsync.when(
        data: (receipts) => _buildContent(receipts),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'My Receipts',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'reset_filters') {
                _resetFilters();
              } else if (value == 'add_receipt') {
                context.push(AppRoutes.add);
              }
            },
            itemBuilder: (context) => [
              if (_isFiltered)
                const PopupMenuItem<String>(
                  value: 'reset_filters',
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt_off_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Reset filters & search'),
                    ],
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'add_receipt',
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Add receipt'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Search Bar
                  ReceiptSearchBar(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onClear: () => _onSearchChanged(''),
                  ),
                  const SizedBox(height: 12),

                  // Category Filter Chips
                  CategoryFilterRow(
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    onCategorySelected: _onCategorySelected,
                  ),
                  const SizedBox(height: 8),

                  // Receipt List, Empty State, Loading, or Error
                  Expanded(child: bodyContent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
