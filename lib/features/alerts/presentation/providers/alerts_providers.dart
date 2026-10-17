// lib/features/alerts/presentation/providers/alerts_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/features/alerts/domain/entities/warranty_alert.dart';
import 'package:receipt_vault/features/receipts/presentation/providers/receipts_providers.dart';

/// Filter categories for the Alerts screen.
enum AlertFilter { all, expiringSoon, expired }

/// Deterministic comparison function for sorting warranty alerts:
/// 1. Expiring soon alerts precede expired alerts.
/// 2. Within expiring soon: soonest to expire first (ascending remainingDays).
/// 3. Within expired: most recently expired first (descending remainingDays, e.g. -1 before -10).
/// 4. Tie-breaker: newest receipt first (descending receipt.id).
int compareAlerts(WarrantyAlert a, WarrantyAlert b) {
  if (a.isExpiringSoon && b.isExpired) return -1;
  if (a.isExpired && b.isExpiringSoon) return 1;

  if (a.isExpiringSoon && b.isExpiringSoon) {
    final aDays = a.remainingDays ?? 0;
    final bDays = b.remainingDays ?? 0;
    final cmp = aDays.compareTo(bDays);
    if (cmp != 0) return cmp;
    return b.receipt.id.compareTo(a.receipt.id);
  }

  if (a.isExpired && b.isExpired) {
    final aDays = a.remainingDays ?? 0;
    final bDays = b.remainingDays ?? 0;
    final cmp = bDays.compareTo(aDays);
    if (cmp != 0) return cmp;
    return b.receipt.id.compareTo(a.receipt.id);
  }

  return b.receipt.id.compareTo(a.receipt.id);
}

/// Generates a sorted, deterministic list of [WarrantyAlert] events from raw [Receipt]s.
///
/// Receipts without a valid warranty duration (null or <= 0) or with status
/// active (> 30 days remaining) are excluded because they do not require immediate action.
/// Expired receipts older than [maxExpiredDays] (default 90 days) are omitted
/// so stale history does not clutter actionable reminders.
List<WarrantyAlert> generateWarrantyAlerts(
  List<Receipt> receipts, {
  DateTime? now,
  int? maxExpiredDays = 90,
}) {
  final alerts = <WarrantyAlert>[];

  for (final receipt in receipts) {
    if (receipt.warrantyDurationDays == null ||
        receipt.warrantyDurationDays! <= 0) {
      continue;
    }

    final alert = WarrantyAlert.fromReceipt(receipt, now: now);

    if (alert.isExpiringSoon) {
      alerts.add(alert);
    } else if (alert.isExpired) {
      if (maxExpiredDays == null ||
          (alert.remainingDays != null &&
              alert.remainingDays! >= -maxExpiredDays)) {
        alerts.add(alert);
      }
    }
  }

  alerts.sort(compareAlerts);
  return alerts;
}

/// Exposes all active warranty alerts as a reactive stream.
/// Kept alive for the duration of the app shell to avoid stream thrashing.
final alertsStreamProvider = StreamProvider<List<WarrantyAlert>>((ref) {
  final repository = ref.watch(receiptsRepositoryProvider);
  return repository.watchReceipts().map((receipts) {
    return generateWarrantyAlerts(receipts);
  });
});
