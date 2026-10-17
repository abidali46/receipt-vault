// test/features/receipts/receipt_detail_screen_test.dart

import 'dart:async';

import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/core/storage/database_provider.dart';
import 'package:receipt_vault/core/storage/receipt_image_service.dart';
import 'package:receipt_vault/features/receipts/data/repositories/drift_receipts_repository.dart';
import 'package:receipt_vault/features/receipts/domain/entities/receipt_card_data.dart';
import 'package:receipt_vault/features/receipts/domain/repositories/receipts_repository.dart';
import 'package:receipt_vault/features/receipts/domain/services/warranty_calculator.dart';
import 'package:receipt_vault/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:receipt_vault/features/receipts/presentation/receipt_detail_screen.dart';

final class _TestErrorObserver extends ProviderObserver {
  @override
  void providerDidFail(Object provider, Object error, StackTrace stackTrace) {
    // Absorbs error so it doesn't propagate as uncaught zone error in flutter_test
  }
}

class _TestReceiptImageService implements ReceiptImageService {
  int deleteCallCount = 0;
  String? lastDeletedPath;

  @override
  Future<XFile?> pickImage({required ImageSource source}) async => null;

  @override
  Future<String> copyToPersistentStorage(String sourcePath) async => sourcePath;

  @override
  Future<void> deleteImageIfUnreferenced(
    String path, {
    ReceiptsRepository? repository,
  }) async {
    deleteCallCount++;
    lastDeletedPath = path;
  }

  @override
  bool fileExists(String path) => true;
}

class _FailingDeleteRepository implements ReceiptsRepository {
  _FailingDeleteRepository(this._inner);
  final ReceiptsRepository _inner;

  @override
  Future<int> deleteReceipt(int id) async {
    throw Exception('Disk I/O error while deleting receipt');
  }

  @override
  Future<List<Receipt>> getAllReceipts() => _inner.getAllReceipts();

  @override
  Future<Receipt?> getReceiptById(int id) => _inner.getReceiptById(id);

  @override
  Future<int> insertReceipt(ReceiptsCompanion receipt) =>
      _inner.insertReceipt(receipt);

  @override
  Future<bool> updateReceipt(Receipt receipt) => _inner.updateReceipt(receipt);

  @override
  Stream<List<ReceiptCardData>> watchReceiptCards({DateTime? now}) =>
      _inner.watchReceiptCards(now: now);

  @override
  Stream<Receipt?> watchReceiptById(int id) => _inner.watchReceiptById(id);

  @override
  Stream<List<Receipt>> watchReceipts() => _inner.watchReceipts();
}

Widget _buildTestApp({
  required int? receiptId,
  Receipt? receipt,
  ThemeMode themeMode = ThemeMode.light,
  List<dynamic> overrides = const [],
  List<ProviderObserver>? observers,
  ReceiptsRepository? repository,
  ReceiptImageService? imageService,
  NavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    overrides: [
      if (repository != null)
        receiptsRepositoryProvider.overrideWithValue(repository),
      if (imageService != null)
        receiptImageServiceProvider.overrideWithValue(imageService),
      for (final o in overrides) o,
    ],
    observers: observers,
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      navigatorObservers: [?navigatorObserver],
      home: ReceiptDetailScreen(
        receiptId: receiptId,
        receipt: receipt,
        repository: repository,
        imageService: imageService,
      ),
    ),
  );
}

void main() {
  group('ReceiptDetailScreen', () {
    testWidgets('renders missing record state when receiptId is null', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(receiptId: null));

      expect(find.text('Receipt Details'), findsOneWidget);
      expect(find.text('Receipt Not Found'), findsOneWidget);
      expect(
        find.text('This receipt does not exist or has been removed.'),
        findsOneWidget,
      );
      expect(find.text('Back to Receipts'), findsOneWidget);
    });

    testWidgets('renders loading state on initial stream load', (tester) async {
      final completer = Completer<Receipt?>();

      await tester.pumpWidget(
        _buildTestApp(
          receiptId: 1,
          overrides: [
            receiptDetailStreamProvider(
              1,
            ).overrideWith((ref) => completer.future.asStream()),
          ],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('receipt_detail_info_card')), findsNothing);

      completer.complete(null);
      await tester.pumpAndSettle();
    });

    testWidgets('renders error state when provider emits an error', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          receiptId: 1,
          observers: [_TestErrorObserver()],
          overrides: [
            receiptDetailStreamProvider(1).overrideWith(
              (ref) => Stream.error(Exception('Database disk read failed')),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load receipt details'), findsOneWidget);
      expect(find.text('Exception: Database disk read failed'), findsOneWidget);
      expect(find.text('Back to Receipts'), findsOneWidget);
    });

    testWidgets(
      'renders missing record state when receipt does not exist in database',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            receiptId: 999,
            overrides: [
              receiptDetailStreamProvider(
                999,
              ).overrideWith((ref) => Stream.value(null)),
            ],
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Receipt Not Found'), findsOneWidget);
        expect(find.text('Back to Receipts'), findsOneWidget);
      },
    );

    testWidgets(
      'displays full receipt details with warranty progress and edit button',
      (tester) async {
        final sampleReceipt = Receipt(
          id: 42,
          productName: 'Samsung Galaxy S24',
          storeName: 'Best Buy Electronics',
          category: 'Electronics',
          purchaseDate: DateTime(2026, 1, 15),
          totalAmount: 899.99,
          warrantyDurationDays: 365,
          notes: 'Includes official protective case and screen protector',
          imagePath: null,
          createdAt: DateTime(2026, 1, 15, 10, 30),
        );

        await tester.pumpWidget(
          _buildTestApp(receiptId: 42, receipt: sampleReceipt),
        );

        // Header section
        expect(find.text('Samsung Galaxy S24'), findsOneWidget);
        expect(
          find.byKey(const Key('receipt_detail_warranty_badge')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('receipt_detail_category_chip')),
          findsOneWidget,
        );
        expect(find.text('Electronics'), findsWidgets);

        // Info card details
        expect(find.text('Best Buy Electronics'), findsOneWidget);
        expect(find.text('\$899.99'), findsOneWidget);
        expect(find.text('Jan 15, 2026'), findsOneWidget);
        expect(find.text('1 Year'), findsOneWidget);
        expect(find.text('Jan 15, 2027'), findsOneWidget);
        expect(
          find.text('Includes official protective case and screen protector'),
          findsOneWidget,
        );

        // Warranty progress bar
        final progressBarFinder = find.byKey(
          const Key('receipt_detail_warranty_progress_bar'),
        );
        expect(progressBarFinder, findsOneWidget);
        final progressBar = tester.widget<LinearProgressIndicator>(
          progressBarFinder,
        );
        final expectedProgress = WarrantyCalculator.calculate(
          purchaseDate: sampleReceipt.purchaseDate,
          warrantyDurationDays: sampleReceipt.warrantyDurationDays,
        ).progress;
        expect(progressBar.value, equals(expectedProgress));

        // Edit button
        expect(
          find.byKey(const Key('receipt_detail_edit_button')),
          findsOneWidget,
        );
        expect(find.text('Edit Details'), findsOneWidget);
      },
    );

    testWidgets(
      'renders progress bar with 0.0 for expired receipt matching WarrantyCalculator',
      (tester) async {
        final expiredReceipt = Receipt(
          id: 43,
          productName: 'Old Blender',
          storeName: 'Target',
          category: 'Home',
          purchaseDate: DateTime(2020, 1, 1),
          totalAmount: 49.99,
          warrantyDurationDays: 365,
          notes: null,
          imagePath: null,
          createdAt: DateTime(2020, 1, 1),
        );

        await tester.pumpWidget(
          _buildTestApp(receiptId: 43, receipt: expiredReceipt),
        );

        final progressBar = tester.widget<LinearProgressIndicator>(
          find.byKey(const Key('receipt_detail_warranty_progress_bar')),
        );
        expect(progressBar.value, equals(0.0));
      },
    );

    testWidgets('renders safe fallback when image file is missing', (
      tester,
    ) async {
      final sampleReceipt = Receipt(
        id: 10,
        productName: 'Office Chair',
        storeName: 'IKEA',
        category: 'Home',
        purchaseDate: DateTime(2026, 3, 1),
        totalAmount: 150.0,
        warrantyDurationDays: null,
        notes: null,
        imagePath: '/non/existent/path/missing_chair.jpg',
        createdAt: DateTime(2026, 3, 1),
      );

      await tester.pumpWidget(
        _buildTestApp(receiptId: 10, receipt: sampleReceipt),
      );

      expect(
        find.byKey(const Key('receipt_detail_photo_missing_fallback')),
        findsOneWidget,
      );
      expect(find.text('Photo not available on this device'), findsOneWidget);
      expect(find.text('No warranty'), findsOneWidget);
      // No warranty progress bar when warrantyDurationDays is null
      expect(
        find.byKey(const Key('receipt_detail_warranty_progress_bar')),
        findsNothing,
      );
    });

    testWidgets('renders properly in dark mode', (tester) async {
      final sampleReceipt = Receipt(
        id: 7,
        productName: 'Mechanical Keyboard',
        storeName: 'Micro Center',
        category: 'Electronics',
        purchaseDate: DateTime(2026, 5, 1),
        totalAmount: 120.0,
        warrantyDurationDays: 180,
        notes: 'Cherry MX Blue switches',
        imagePath: null,
        createdAt: DateTime(2026, 5, 1),
      );

      await tester.pumpWidget(
        _buildTestApp(
          receiptId: 7,
          receipt: sampleReceipt,
          themeMode: ThemeMode.dark,
        ),
      );

      expect(find.text('Mechanical Keyboard'), findsOneWidget);
      expect(find.text('Micro Center'), findsOneWidget);
      expect(find.text('\$120'), findsOneWidget);
      expect(find.text('6 Months'), findsOneWidget);
      expect(find.text('Edit Details'), findsOneWidget);
    });

    testWidgets(
      'reactively updates when receipt is modified in SQLite database',
      (tester) async {
        final database = AppDatabase(NativeDatabase.memory());

        final id = await database
            .into(database.receipts)
            .insert(
              ReceiptsCompanion.insert(
                productName: 'Initial Product',
                storeName: const drift.Value('Initial Store'),
                category: const drift.Value('Food'),
                purchaseDate: DateTime(2026, 2, 1),
                totalAmount: 45.0,
                warrantyDurationDays: const drift.Value(30),
              ),
            );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(database)],
            child: MaterialApp(
              theme: AppTheme.light,
              home: ReceiptDetailScreen(receiptId: id),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Initial Product'), findsOneWidget);
        expect(find.text('Initial Store'), findsOneWidget);
        expect(find.text('\$45'), findsOneWidget);

        // Update the receipt in SQLite
        final existing = await (database.select(
          database.receipts,
        )..where((tbl) => tbl.id.equals(id))).getSingle();

        await database
            .update(database.receipts)
            .replace(
              existing.copyWith(
                productName: 'Updated Product Name',
                storeName: const drift.Value('Updated Store Name'),
                totalAmount: 99.0,
              ),
            );

        // Pump event queue so Drift stream emits the mutation
        await tester.pumpAndSettle();

        expect(find.text('Updated Product Name'), findsOneWidget);
        expect(find.text('Updated Store Name'), findsOneWidget);
        expect(find.text('\$99'), findsOneWidget);

        // Dispose db and pump to clear Drift query stream timer
        await database.close();
        await tester.pump(const Duration(milliseconds: 50));
      },
    );

    testWidgets(
      'displays Delete Receipt action button and AppBar delete button',
      (tester) async {
        final sampleReceipt = Receipt(
          id: 42,
          productName: 'Sony Headphones',
          storeName: 'Amazon',
          category: 'Electronics',
          purchaseDate: DateTime(2026, 1, 15),
          totalAmount: 299.99,
          warrantyDurationDays: 365,
          notes: null,
          imagePath: null,
          createdAt: DateTime(2026, 1, 15),
        );

        await tester.pumpWidget(
          _buildTestApp(receiptId: 42, receipt: sampleReceipt),
        );

        expect(
          find.byKey(const Key('receipt_detail_delete_button')),
          findsOneWidget,
        );
        expect(find.text('Delete Receipt'), findsOneWidget);
        expect(
          find.byKey(const Key('receipt_detail_app_bar_delete_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'cancelling delete confirmation dialog leaves receipt in database and dismisses dialog',
      (tester) async {
        final database = AppDatabase(NativeDatabase.memory());
        final id = await database
            .into(database.receipts)
            .insert(
              ReceiptsCompanion.insert(
                productName: 'Noise Cancelling Headphones',
                purchaseDate: DateTime(2026, 2, 1),
                totalAmount: 199.0,
              ),
            );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(database)],
            child: MaterialApp(
              theme: AppTheme.light,
              home: ReceiptDetailScreen(receiptId: id),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap delete button
        final deleteBtn = find.byKey(const Key('receipt_detail_delete_button'));
        await tester.ensureVisible(deleteBtn);
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        // Dialog is displayed
        expect(
          find.byKey(const Key('receipt_detail_delete_dialog')),
          findsOneWidget,
        );
        expect(
          find.text(
            'Are you sure you want to delete "Noise Cancelling Headphones"?\n\nThis action will permanently remove the receipt and cannot be undone.',
          ),
          findsOneWidget,
        );

        // Tap cancel
        await tester.tap(
          find.byKey(const Key('receipt_detail_delete_cancel_button')),
        );
        await tester.pumpAndSettle();

        // Dialog dismissed
        expect(
          find.byKey(const Key('receipt_detail_delete_dialog')),
          findsNothing,
        );

        // Record still exists in database
        final record = await (database.select(
          database.receipts,
        )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
        expect(record, isNotNull);

        await database.close();
        await tester.pump(const Duration(milliseconds: 50));
      },
    );

    testWidgets(
      'confirming delete removes receipt from SQLite, invokes safe cleanup, and shows SnackBar',
      (tester) async {
        final database = AppDatabase(NativeDatabase.memory());
        final testImageService = _TestReceiptImageService();
        final id = await database
            .into(database.receipts)
            .insert(
              ReceiptsCompanion.insert(
                productName: 'Gaming Mouse',
                purchaseDate: DateTime(2026, 3, 1),
                totalAmount: 79.99,
                imagePath: const drift.Value('/path/to/mouse.jpg'),
              ),
            );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(database),
              receiptImageServiceProvider.overrideWithValue(testImageService),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: ReceiptDetailScreen(
                receiptId: id,
                imageService: testImageService,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap delete button
        final deleteBtn = find.byKey(const Key('receipt_detail_delete_button'));
        await tester.ensureVisible(deleteBtn);
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        // Tap confirm delete
        await tester.tap(
          find.byKey(const Key('receipt_detail_delete_confirm_button')),
        );
        await tester.pumpAndSettle();

        // SnackBar shown
        expect(find.text('Receipt deleted successfully.'), findsOneWidget);

        // Record deleted from SQLite
        final record = await (database.select(
          database.receipts,
        )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
        expect(record, isNull);

        // Image cleanup called
        expect(testImageService.deleteCallCount, 1);
        expect(testImageService.lastDeletedPath, '/path/to/mouse.jpg');

        await database.close();
        await tester.pump(const Duration(milliseconds: 50));
      },
    );

    testWidgets(
      'database failure during deletion displays error SnackBar and does NOT show success message',
      (tester) async {
        final database = AppDatabase(NativeDatabase.memory());
        final failingRepo = _FailingDeleteRepository(
          DriftReceiptsRepository(database),
        );
        final id = await database
            .into(database.receipts)
            .insert(
              ReceiptsCompanion.insert(
                productName: 'Tablet Stand',
                purchaseDate: DateTime(2026, 4, 1),
                totalAmount: 25.0,
              ),
            );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(database),
              receiptsRepositoryProvider.overrideWithValue(failingRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: ReceiptDetailScreen(receiptId: id, repository: failingRepo),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap delete button
        final deleteBtn = find.byKey(const Key('receipt_detail_delete_button'));
        await tester.ensureVisible(deleteBtn);
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        // Confirm delete
        await tester.tap(
          find.byKey(const Key('receipt_detail_delete_confirm_button')),
        );
        await tester.pumpAndSettle();

        // Error SnackBar displayed
        expect(find.textContaining('Failed to delete receipt'), findsOneWidget);
        expect(find.text('Receipt deleted successfully.'), findsNothing);

        // Record still intact in database
        final record = await (database.select(
          database.receipts,
        )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
        expect(record, isNotNull);

        await database.close();
        await tester.pump(const Duration(milliseconds: 50));
      },
    );

    test(
      'DefaultReceiptImageService safe cleanup preserves referenced image and skips when repository is null',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        final repository = DriftReceiptsRepository(database);
        const service = DefaultReceiptImageService();

        // Create a temp file on disk
        final tempDir = await Directory.systemTemp.createTemp('receipt_test_');
        final tempFile = File('${tempDir.path}/test_shared.jpg');
        await tempFile.writeAsString('image data');
        expect(tempFile.existsSync(), isTrue);

        // 1. With null repository: safe cleanup cannot be guaranteed, file MUST NOT be deleted
        await service.deleteImageIfUnreferenced(
          tempFile.path,
          repository: null,
        );
        expect(tempFile.existsSync(), isTrue);

        // 2. Insert receipt referencing this file
        await database
            .into(database.receipts)
            .insert(
              ReceiptsCompanion.insert(
                productName: 'Referencing Receipt',
                purchaseDate: DateTime(2026, 1, 1),
                totalAmount: 10.0,
                imagePath: drift.Value(tempFile.path),
              ),
            );

        // 3. With repository where file is referenced: MUST NOT be deleted
        await service.deleteImageIfUnreferenced(
          tempFile.path,
          repository: repository,
        );
        expect(tempFile.existsSync(), isTrue);

        // 4. Delete the receipt from database
        await (database.delete(database.receipts)).go();

        // 5. Now unreferenced: safely deleted!
        await service.deleteImageIfUnreferenced(
          tempFile.path,
          repository: repository,
        );
        expect(tempFile.existsSync(), isFalse);

        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
        await database.close();
      },
    );
  });
}
