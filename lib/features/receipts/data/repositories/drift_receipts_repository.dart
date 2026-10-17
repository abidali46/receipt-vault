// lib/features/receipts/data/repositories/drift_receipts_repository.dart

import 'package:drift/drift.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/features/receipts/domain/entities/receipt_card_data.dart';
import 'package:receipt_vault/features/receipts/domain/repositories/receipts_repository.dart';

/// Concrete implementation of [ReceiptsRepository] using Drift and SQLite.
class DriftReceiptsRepository implements ReceiptsRepository {
  const DriftReceiptsRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<Receipt>> watchReceipts() {
    return (_database.select(_database.receipts)..orderBy([
          (tbl) => OrderingTerm.desc(tbl.purchaseDate),
          (tbl) => OrderingTerm.desc(tbl.id),
        ]))
        .watch();
  }

  @override
  Stream<List<ReceiptCardData>> watchReceiptCards({DateTime? now}) {
    return watchReceipts().map(
      (receipts) => receipts
          .map((receipt) => ReceiptCardData.fromReceipt(receipt, now: now))
          .toList(),
    );
  }

  @override
  Future<List<Receipt>> getAllReceipts() {
    return (_database.select(_database.receipts)..orderBy([
          (tbl) => OrderingTerm.desc(tbl.purchaseDate),
          (tbl) => OrderingTerm.desc(tbl.id),
        ]))
        .get();
  }

  @override
  Stream<Receipt?> watchReceiptById(int id) {
    return (_database.select(
      _database.receipts,
    )..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  @override
  Future<Receipt?> getReceiptById(int id) {
    return (_database.select(
      _database.receipts,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<int> insertReceipt(ReceiptsCompanion receipt) {
    return _database.into(_database.receipts).insert(receipt);
  }

  @override
  Future<bool> updateReceipt(Receipt receipt) {
    return _database.update(_database.receipts).replace(receipt);
  }

  @override
  Future<int> deleteReceipt(int id) {
    return (_database.delete(
      _database.receipts,
    )..where((tbl) => tbl.id.equals(id))).go();
  }
}
