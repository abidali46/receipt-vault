// lib/features/warranty/presentation/providers/warranty_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:receipt_vault/features/warranty/domain/entities/warranty_item.dart';
import 'package:receipt_vault/shared/enums/warranty_status.dart';

/// Available filter categories for the Warranties screen.
enum WarrantyFilter { all, active, expiringSoon, expired }

/// Converts raw [Receipt] entities into sorted, valid [WarrantyItem]s.
///
/// Receipts without a valid warranty duration (null or <= 0) or with status
/// [WarrantyStatus.none] are strictly omitted to guarantee they are never
/// erroneously displayed as active warranties.
List<WarrantyItem> filterAndSortWarrantyItems(
  List<Receipt> receipts, {
  DateTime? now,
}) {
  final items = <WarrantyItem>[];

  for (final receipt in receipts) {
    if (receipt.warrantyDurationDays == null ||
        receipt.warrantyDurationDays! <= 0) {
      continue;
    }

    final item = WarrantyItem.fromReceipt(receipt, now: now);
    if (item.status != WarrantyStatus.none) {
      items.add(item);
    }
  }

  // Sort: Active and Expiring Soon items first (soonest to expire first),
  // followed by Expired items (most recently expired first).
  items.sort((a, b) {
    final aExpired = a.status == WarrantyStatus.expired;
    final bExpired = b.status == WarrantyStatus.expired;

    if (aExpired != bExpired) {
      return aExpired ? 1 : -1;
    }

    if (aExpired) {
      final aExp = a.expiryDate ?? a.receipt.purchaseDate;
      final bExp = b.expiryDate ?? b.receipt.purchaseDate;
      return bExp.compareTo(aExp);
    }

    final aDays = a.remainingDays ?? 999999;
    final bDays = b.remainingDays ?? 999999;
    return aDays.compareTo(bDays);
  });

  return items;
}

/// Exposes all receipts possessing a valid warranty as a reactive stream of [WarrantyItem]s.
final warrantiesStreamProvider = StreamProvider<List<WarrantyItem>>((ref) {
  final repository = ref.watch(receiptsRepositoryProvider);
  return repository.watchReceipts().map((receipts) {
    return filterAndSortWarrantyItems(receipts);
  });
});
