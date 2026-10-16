// test/core/storage/database_provider_test.dart
//
// Tests verifying the databaseProvider can be read and overridden.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/core/storage/database_provider.dart';

void main() {
  group('databaseProvider', () {
    test(
      'can be read and overridden with an in-memory database in ProviderContainer',
      () async {
        final inMemoryDb = AppDatabase(NativeDatabase.memory());

        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(inMemoryDb)],
        );

        final db = container.read(databaseProvider);
        expect(db, equals(inMemoryDb));

        final rows = await db.select(db.receipts).get();
        expect(rows, isEmpty);

        container.dispose();
        await inMemoryDb.close();
      },
    );
  });
}
