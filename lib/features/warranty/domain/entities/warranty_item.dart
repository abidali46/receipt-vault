// lib/features/warranty/domain/entities/warranty_item.dart

import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/features/receipts/domain/services/warranty_calculator.dart';
import 'package:receipt_vault/shared/enums/warranty_status.dart';

/// Presentation entity representing a saved receipt that has an attached warranty.
class WarrantyItem {
  const WarrantyItem({required this.receipt, required this.warrantyInfo});

  /// Factory constructor to map a [Receipt] database entity to a [WarrantyItem].
  factory WarrantyItem.fromReceipt(Receipt receipt, {DateTime? now}) {
    final info = WarrantyCalculator.calculate(
      purchaseDate: receipt.purchaseDate,
      warrantyDurationDays: receipt.warrantyDurationDays,
      now: now,
    );
    return WarrantyItem(receipt: receipt, warrantyInfo: info);
  }

  /// Underlying receipt record.
  final Receipt receipt;

  /// Centralized calculated warranty information.
  final WarrantyInfo warrantyInfo;

  /// Evaluated warranty status.
  WarrantyStatus get status => warrantyInfo.status;

  /// Human-readable label for UI badges (e.g. '120 days left', 'Expired').
  String get statusLabel => warrantyInfo.statusLabel;

  /// Expiry date (null if no warranty).
  DateTime? get expiryDate => warrantyInfo.expiryDate;

  /// Remaining calendar days until expiration.
  int? get remainingDays => warrantyInfo.remainingDays;

  /// Remaining ratio of warranty duration (0.0 to 1.0).
  double get progress => warrantyInfo.progress;

  /// Integer percentage of warranty remaining (0 to 100).
  int get progressPercentage => (progress * 100).round();
}
