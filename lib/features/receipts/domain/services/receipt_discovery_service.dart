// lib/features/receipts/domain/services/receipt_discovery_service.dart

import 'package:receipt_vault/features/receipts/domain/entities/receipt_card_data.dart';
import 'package:receipt_vault/features/receipts/domain/entities/receipt_sort_option.dart';

/// Domain service providing case-insensitive search, category filtering,
/// and deterministic sorting for receipt lists.
class ReceiptDiscoveryService {
  const ReceiptDiscoveryService._();

  /// Filters a list of receipts by category and case-insensitive search query.
  ///
  /// - [selectedCategory]: Matches exact category (case-insensitive). 'All' includes all categories.
  /// - [searchQuery]: Matches substring in [ReceiptCardData.productName],
  ///   [ReceiptCardData.storeName], or [ReceiptCardData.category] (case-insensitive).
  static List<ReceiptCardData> filterReceipts(
    List<ReceiptCardData> receipts, {
    String selectedCategory = 'All',
    String searchQuery = '',
  }) {
    final trimmedCategory = selectedCategory.trim().toLowerCase();
    final trimmedQuery = searchQuery.trim().toLowerCase();

    return receipts.where((receipt) {
      // Category filter
      if (trimmedCategory.isNotEmpty && trimmedCategory != 'all') {
        if (receipt.category.trim().toLowerCase() != trimmedCategory) {
          return false;
        }
      }

      // Search query filter (product name, store name, or category)
      if (trimmedQuery.isNotEmpty) {
        final matchesProduct = receipt.productName.toLowerCase().contains(
          trimmedQuery,
        );
        final matchesStore =
            receipt.storeName?.toLowerCase().contains(trimmedQuery) ?? false;
        final matchesCategory = receipt.category.toLowerCase().contains(
          trimmedQuery,
        );

        if (!matchesProduct && !matchesStore && !matchesCategory) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Sorts a list of receipts deterministically using the specified [sortOption].
  ///
  /// Uses the receipt's numeric ID as a stable tie-breaker when primary attributes compare equally.
  static List<ReceiptCardData> sortReceipts(
    List<ReceiptCardData> receipts,
    ReceiptSortOption sortOption,
  ) {
    final list = List<ReceiptCardData>.from(receipts);

    switch (sortOption) {
      case ReceiptSortOption.newestPurchase:
        list.sort((a, b) {
          final dateA =
              a.purchaseDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateB =
              b.purchaseDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateCmp = dateB.compareTo(dateA);
          if (dateCmp != 0) return dateCmp;
          return (int.tryParse(b.id) ?? 0).compareTo(int.tryParse(a.id) ?? 0);
        });
        break;

      case ReceiptSortOption.oldestPurchase:
        list.sort((a, b) {
          final dateA =
              a.purchaseDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateB =
              b.purchaseDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateCmp = dateA.compareTo(dateB);
          if (dateCmp != 0) return dateCmp;
          return (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0);
        });
        break;

      case ReceiptSortOption.productName:
        list.sort((a, b) {
          final nameCmp = a.productName.toLowerCase().compareTo(
            b.productName.toLowerCase(),
          );
          if (nameCmp != 0) return nameCmp;
          return (int.tryParse(b.id) ?? 0).compareTo(int.tryParse(a.id) ?? 0);
        });
        break;

      case ReceiptSortOption.amountHighToLow:
        list.sort((a, b) {
          final priceCmp = b.price.compareTo(a.price);
          if (priceCmp != 0) return priceCmp;
          return (int.tryParse(b.id) ?? 0).compareTo(int.tryParse(a.id) ?? 0);
        });
        break;

      case ReceiptSortOption.amountLowToHigh:
        list.sort((a, b) {
          final priceCmp = a.price.compareTo(b.price);
          if (priceCmp != 0) return priceCmp;
          return (int.tryParse(b.id) ?? 0).compareTo(int.tryParse(a.id) ?? 0);
        });
        break;
    }

    return list;
  }

  /// Filters and sorts receipts in a single deterministic pipeline.
  static List<ReceiptCardData> filterAndSortReceipts(
    List<ReceiptCardData> receipts, {
    String selectedCategory = 'All',
    String searchQuery = '',
    ReceiptSortOption sortOption = ReceiptSortOption.newestPurchase,
  }) {
    final filtered = filterReceipts(
      receipts,
      selectedCategory: selectedCategory,
      searchQuery: searchQuery,
    );
    return sortReceipts(filtered, sortOption);
  }
}
