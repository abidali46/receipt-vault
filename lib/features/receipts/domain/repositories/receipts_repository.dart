// lib/features/receipts/domain/repositories/receipts_repository.dart

import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/features/receipts/domain/entities/receipt_card_data.dart';

/// Repository interface for querying and mutating receipts in storage.
abstract class ReceiptsRepository {
  /// Emits reactive updates of raw database [Receipt] records.
  Stream<List<Receipt>> watchReceipts();

  /// Emits reactive updates of receipts mapped to [ReceiptCardData] presentation models.
  Stream<List<ReceiptCardData>> watchReceiptCards({DateTime? now});

  /// Emits reactive updates for a single receipt by [id], or null if not found.
  Stream<Receipt?> watchReceiptById(int id);

  /// Fetches all receipts once, ordered newest purchase date first.
  Future<List<Receipt>> getAllReceipts();

  /// Fetches a single receipt by [id].
  Future<Receipt?> getReceiptById(int id);

  /// Inserts a new receipt and returns the generated row ID.
  Future<int> insertReceipt(ReceiptsCompanion receipt);

  /// Updates an existing receipt record.
  Future<bool> updateReceipt(Receipt receipt);

  /// Deletes a receipt record by [id].
  Future<int> deleteReceipt(int id);
}
