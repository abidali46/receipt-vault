// lib/features/receipts/domain/entities/receipt_card_data.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/shared/enums/warranty_status.dart';

/// Presentation entity representing a single receipt in list views.
class ReceiptCardData {
  const ReceiptCardData({
    required this.id,
    required this.productName,
    this.storeName,
    required this.price,
    required this.status,
    required this.statusLabel,
    this.category = 'Others',
    this.icon = Icons.receipt_long_outlined,
  });

  /// Unique identifier for the receipt.
  final String id;

  /// Name of the purchased item.
  final String productName;

  /// Retailer or store where purchased.
  final String? storeName;

  /// Purchase price in dollars.
  final double price;

  /// Warranty status indicator.
  final WarrantyStatus status;

  /// Human-readable warranty label (e.g., '120 days left', 'Expired').
  final String statusLabel;

  /// Category name (e.g., 'Electronics', 'Food', 'Others').
  final String category;

  /// Display icon for the item type.
  final IconData icon;

  /// Formatted price string (e.g. '$899' or '$1,200.50').
  String get formattedPrice {
    if (price == price.roundToDouble()) {
      return '\$${price.toInt()}';
    }
    return '\$${price.toStringAsFixed(2)}';
  }
}
