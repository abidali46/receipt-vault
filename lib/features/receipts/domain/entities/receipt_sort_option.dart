// lib/features/receipts/domain/entities/receipt_sort_option.dart

/// Enumeration of available sorting strategies for receipt lists.
enum ReceiptSortOption {
  /// Newest purchase date first (most recent to oldest).
  newestPurchase('Newest purchase'),

  /// Oldest purchase date first (oldest to most recent).
  oldestPurchase('Oldest purchase'),

  /// Alphabetical product name order (A to Z).
  productName('Product name (A–Z)'),

  /// Highest purchase price first.
  amountHighToLow('Amount (high to low)'),

  /// Lowest purchase price first.
  amountLowToHigh('Amount (low to high)');

  const ReceiptSortOption(this.label);

  /// Human-readable display label.
  final String label;
}
