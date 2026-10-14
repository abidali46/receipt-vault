// lib/features/receipts/presentation/receipts_screen.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/features/receipts/domain/entities/receipt_card_data.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/category_filter_row.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/receipt_card.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/receipt_search_bar.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/receipts_empty_state.dart';

/// Screen displaying the user's receipts with search, category filtering,
/// and receipt card listing or empty state.
///
/// Follows DESIGN.md specifications and the updated 5-tab mockup.
class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({
    super.key,
    this.receipts = const [],
    this.onReceiptTap,
  });

  /// Receipts list to display. Defaults to an empty list until the local
  /// database and repository are integrated in Phase 1 / Phase 2.
  final List<ReceiptCardData> receipts;

  /// Optional callback invoked when a receipt card is tapped.
  final ValueChanged<ReceiptCardData>? onReceiptTap;

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  static const List<String> _categories = [
    'All',
    'Electronics',
    'Food',
    'Others',
  ];

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

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = 'All';
    });
  }

  bool get _isFiltered =>
      _searchQuery.isNotEmpty || _selectedCategory.toLowerCase() != 'all';

  List<ReceiptCardData> get _filteredReceipts {
    return widget.receipts.where((receipt) {
      // Category filter
      if (_selectedCategory.toLowerCase() != 'all') {
        if (receipt.category.toLowerCase() != _selectedCategory.toLowerCase()) {
          return false;
        }
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesProduct = receipt.productName.toLowerCase().contains(
          query,
        );
        final matchesStore =
            receipt.storeName?.toLowerCase().contains(query) ?? false;
        final matchesCategory = receipt.category.toLowerCase().contains(query);

        if (!matchesProduct && !matchesStore && !matchesCategory) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filtered = _filteredReceipts;

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
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onPressed: () {},
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
                  const SizedBox(height: 16),

                  // Receipt List or Empty State
                  Expanded(
                    child: filtered.isEmpty
                        ? ReceiptsEmptyState(
                            isFiltered: _isFiltered,
                            onClearFilters: _resetFilters,
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            padding: const EdgeInsets.only(bottom: 24),
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final receipt = filtered[index];
                              return ReceiptCard(
                                receipt: receipt,
                                onTap: () => widget.onReceiptTap?.call(receipt),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
