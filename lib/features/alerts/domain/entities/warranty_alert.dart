// lib/features/alerts/domain/entities/warranty_alert.dart

import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/features/receipts/domain/services/warranty_calculator.dart';
import 'package:receipt_vault/shared/enums/warranty_status.dart';

/// Represents an actionable in-app warranty alert event (expiring soon or recently expired).
class WarrantyAlert {
  const WarrantyAlert({required this.receipt, required this.info});

  /// Factory constructor computing [WarrantyInfo] using centralized [WarrantyCalculator].
  factory WarrantyAlert.fromReceipt(Receipt receipt, {DateTime? now}) {
    final info = WarrantyCalculator.calculate(
      purchaseDate: receipt.purchaseDate,
      warrantyDurationDays: receipt.warrantyDurationDays,
      now: now,
    );
    return WarrantyAlert(receipt: receipt, info: info);
  }

  /// Underlying database receipt.
  final Receipt receipt;

  /// Centralized warranty calculation result.
  final WarrantyInfo info;

  String get productName => receipt.productName;
  String? get storeName => receipt.storeName;
  String get category => receipt.category ?? 'Uncategorized';
  DateTime get purchaseDate => receipt.purchaseDate;
  DateTime? get expiryDate => info.expiryDate;
  int? get remainingDays => info.remainingDays;
  double get progress => info.progress;
  WarrantyStatus get status => info.status;

  bool get isExpired => status == WarrantyStatus.expired;
  bool get isExpiringSoon => status == WarrantyStatus.expiringSoon;

  /// Human-friendly relative urgency string matching mockup specs.
  /// E.g. "Expires today", "Expires in 7 days", "Expired 2 days ago".
  String get urgencyLabel {
    if (remainingDays == null) return info.statusLabel;

    if (remainingDays == 0) {
      return 'Expires today';
    } else if (remainingDays == 1) {
      return 'Expires in 1 day';
    } else if (remainingDays! > 1) {
      return 'Expires in $remainingDays days';
    } else if (remainingDays == -1) {
      return 'Expired 1 day ago';
    } else {
      final daysAgo = -remainingDays!;
      return 'Expired $daysAgo days ago';
    }
  }
}
