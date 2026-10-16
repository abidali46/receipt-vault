// lib/core/storage/database_provider.dart
//
// Riverpod provider for the Drift AppDatabase instance.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt_vault/core/storage/app_database.dart';

/// Provides the singleton [AppDatabase] instance for the application.
///
/// Can be overridden in widget/integration tests using:
/// ```dart
/// ProviderScope(
///   overrides: [
///     databaseProvider.overrideWithValue(inMemoryDb),
///   ],
///   child: const ReceiptVaultApp(),
/// )
/// ```
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => database.close());
  return database;
});
