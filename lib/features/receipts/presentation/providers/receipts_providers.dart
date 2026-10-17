// lib/features/receipts/presentation/providers/receipts_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/core/storage/database_provider.dart';
import 'package:receipt_vault/features/receipts/data/repositories/drift_receipts_repository.dart';
import 'package:receipt_vault/features/receipts/domain/entities/receipt_card_data.dart';
import 'package:receipt_vault/features/receipts/domain/repositories/receipts_repository.dart';

/// Provides the [ReceiptsRepository] backed by the app's [AppDatabase].
final receiptsRepositoryProvider = Provider<ReceiptsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftReceiptsRepository(db);
});

/// Exposes receipts as a reactive stream mapped to [ReceiptCardData] presentation models.
final receiptsStreamProvider = StreamProvider<List<ReceiptCardData>>((ref) {
  final repository = ref.watch(receiptsRepositoryProvider);
  return repository.watchReceiptCards();
});

/// Exposes raw database [Receipt] records as a reactive stream.
final rawReceiptsStreamProvider = StreamProvider<List<Receipt>>((ref) {
  final repository = ref.watch(receiptsRepositoryProvider);
  return repository.watchReceipts();
});

/// Exposes a single receipt by [id] as a reactive stream from the database.
final receiptDetailStreamProvider = StreamProvider.autoDispose
    .family<Receipt?, int>((ref, id) {
      final repository = ref.watch(receiptsRepositoryProvider);
      return repository.watchReceiptById(id);
    });
