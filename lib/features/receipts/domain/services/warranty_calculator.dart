// lib/features/receipts/domain/services/warranty_calculator.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/shared/enums/warranty_status.dart';

/// Structured result of warranty calculation.
class WarrantyInfo {
  const WarrantyInfo({
    required this.status,
    required this.statusLabel,
    this.remainingDays,
    this.expiryDate,
    this.progress = 0.0,
  });

  /// The evaluated warranty status.
  final WarrantyStatus status;

  /// Human-readable label for UI badges (e.g. '120 days left', 'Expired').
  final String statusLabel;

  /// Remaining calendar days until expiration (negative if expired, null if no warranty).
  final int? remainingDays;

  /// Expiry date (null if no warranty).
  final DateTime? expiryDate;

  /// Progress ratio of warranty duration remaining (0.0 to 1.0, 0.0 if expired or no warranty).
  final double progress;
}

/// Centralized utility for computing warranty statuses, remaining durations,
/// and category icon mappings.
class WarrantyCalculator {
  const WarrantyCalculator._();

  /// Calculates the warranty status and display label for a purchase.
  ///
  /// - If [warrantyDurationDays] is null or <= 0, returns [WarrantyStatus.none] with 'No warranty'.
  /// - If the warranty expiration date is before [now], returns [WarrantyStatus.expired] with 'Expired'.
  /// - If 0 days remain, returns [WarrantyStatus.expiringSoon] with 'Expires today'.
  /// - If <= 30 days remain, returns [WarrantyStatus.expiringSoon] with 'X day(s) left'.
  /// - If >= 365 days remain, returns [WarrantyStatus.active] with 'X year(s) left'.
  /// - Otherwise (> 30 days), returns [WarrantyStatus.active] with 'X days left'.
  static WarrantyInfo calculate({
    required DateTime purchaseDate,
    required int? warrantyDurationDays,
    DateTime? now,
  }) {
    if (warrantyDurationDays == null || warrantyDurationDays <= 0) {
      return const WarrantyInfo(
        status: WarrantyStatus.none,
        statusLabel: 'No warranty',
        remainingDays: null,
        expiryDate: null,
        progress: 0.0,
      );
    }

    final currentDate = now ?? DateTime.now();
    final today = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final expiryDate = purchaseDate.add(Duration(days: warrantyDurationDays));
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    final daysRemaining = expiry.difference(today).inDays;

    if (daysRemaining < 0) {
      return WarrantyInfo(
        status: WarrantyStatus.expired,
        statusLabel: 'Expired',
        remainingDays: daysRemaining,
        expiryDate: expiryDate,
        progress: 0.0,
      );
    }

    if (daysRemaining == 0) {
      return WarrantyInfo(
        status: WarrantyStatus.expiringSoon,
        statusLabel: 'Expires today',
        remainingDays: 0,
        expiryDate: expiryDate,
        progress: 0.0,
      );
    }

    final progress = (daysRemaining / warrantyDurationDays).clamp(0.0, 1.0);

    if (daysRemaining <= 30) {
      return WarrantyInfo(
        status: WarrantyStatus.expiringSoon,
        statusLabel:
            '$daysRemaining ${daysRemaining == 1 ? 'day' : 'days'} left',
        remainingDays: daysRemaining,
        expiryDate: expiryDate,
        progress: progress,
      );
    }

    if (daysRemaining >= 365) {
      final years = daysRemaining ~/ 365;
      return WarrantyInfo(
        status: WarrantyStatus.active,
        statusLabel: '$years ${years == 1 ? 'year' : 'years'} left',
        remainingDays: daysRemaining,
        expiryDate: expiryDate,
        progress: progress,
      );
    }

    return WarrantyInfo(
      status: WarrantyStatus.active,
      statusLabel: '$daysRemaining days left',
      remainingDays: daysRemaining,
      expiryDate: expiryDate,
      progress: progress,
    );
  }

  /// Maps a category name to a corresponding Material [IconData].
  static IconData iconForCategory(String? category) {
    switch (category?.toLowerCase().trim()) {
      case 'electronics':
        return Icons.devices_outlined;
      case 'food':
      case 'groceries':
        return Icons.restaurant_outlined;
      case 'clothing':
      case 'apparel':
        return Icons.checkroom_outlined;
      case 'home':
      case 'appliances':
        return Icons.home_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}
