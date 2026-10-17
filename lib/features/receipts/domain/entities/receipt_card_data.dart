// lib/features/receipts/domain/entities/receipt_card_data.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/features/receipts/domain/services/warranty_calculator.dart';
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
    this.imagePath,
    this.purchaseDate,
  });

  /// Maps a database [Receipt] entity to a [ReceiptCardData] presentation model.
  factory ReceiptCardData.fromReceipt(Receipt receipt, {DateTime? now}) {
    final warranty = WarrantyCalculator.calculate(
      purchaseDate: receipt.purchaseDate,
      warrantyDurationDays: receipt.warrantyDurationDays,
      now: now,
    );

    final category = receipt.category?.trim().isNotEmpty == true
        ? receipt.category!.trim()
        : 'Others';

    return ReceiptCardData(
      id: receipt.id.toString(),
      productName: receipt.productName,
      storeName: receipt.storeName,
      price: receipt.totalAmount,
      status: warranty.status,
      statusLabel: warranty.statusLabel,
      category: category,
      icon: WarrantyCalculator.iconForCategory(category),
      imagePath: receipt.imagePath,
      purchaseDate: receipt.purchaseDate,
    );
  }

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

  /// Optional local persistent image path for the receipt photo.
  final String? imagePath;

  /// Optional purchase date of the receipt, used for chronological sorting.
  final DateTime? purchaseDate;

  /// Formatted price string (e.g. '$899' or '$1,200.50').
  String get formattedPrice {
    if (price == price.roundToDouble()) {
      return '\$${price.toInt()}';
    }
    return '\$${price.toStringAsFixed(2)}';
  }
}
