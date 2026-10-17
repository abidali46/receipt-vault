import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/core/services/warranty_notification_service.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/core/storage/database_provider.dart';
import 'package:receipt_vault/core/storage/receipt_image_service.dart';
import 'package:receipt_vault/features/home/presentation/add_receipt_screen.dart';
import 'package:receipt_vault/features/receipts/data/repositories/drift_receipts_repository.dart';
import 'package:receipt_vault/features/receipts/domain/entities/receipt_card_data.dart';
import 'package:receipt_vault/features/receipts/domain/repositories/receipts_repository.dart';
import 'package:receipt_vault/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:receipt_vault/features/receipts/presentation/receipts_screen.dart';
import 'package:receipt_vault/features/settings/presentation/providers/settings_providers.dart';

/// Test mock that fails on insert to test error handling.
class _FailingReceiptsRepository implements ReceiptsRepository {
  @override
  Future<int> insertReceipt(ReceiptsCompanion receipt) async {
    throw Exception('Database disk write failure');
  }

  @override
  Future<int> deleteReceipt(int id) async => 0;

  @override
  Future<List<Receipt>> getAllReceipts() async => [];

  @override
  Future<Receipt?> getReceiptById(int id) async => null;

  @override
  Future<bool> updateReceipt(Receipt receipt) async => false;

  @override
  Stream<List<ReceiptCardData>> watchReceiptCards({DateTime? now}) =>
      const Stream.empty();

  @override
  Stream<Receipt?> watchReceiptById(int id) => const Stream.empty();

  @override
  Stream<List<Receipt>> watchReceipts() => const Stream.empty();
}

/// Flexible test repository allowing custom get/update behavior for testing edit states.
class _CustomMockReceiptsRepository implements ReceiptsRepository {
  _CustomMockReceiptsRepository({this.onGetReceiptById});

  final Future<Receipt?> Function(int id)? onGetReceiptById;

  @override
  Future<Receipt?> getReceiptById(int id) async {
    if (onGetReceiptById != null) return onGetReceiptById!(id);
    return null;
  }

  @override
  Future<bool> updateReceipt(Receipt receipt) async => true;

  @override
  Future<int> insertReceipt(ReceiptsCompanion receipt) async => 1;

  @override
  Future<int> deleteReceipt(int id) async => 1;

  @override
  Future<List<Receipt>> getAllReceipts() async => [];

  @override
  Stream<List<ReceiptCardData>> watchReceiptCards({DateTime? now}) =>
      const Stream.empty();

  @override
  Stream<Receipt?> watchReceiptById(int id) => const Stream.empty();

  @override
  Stream<List<Receipt>> watchReceipts() => const Stream.empty();
}

/// Test fake image service for verifying photo picking and storage handling.
class _TestReceiptImageService implements ReceiptImageService {
  _TestReceiptImageService({
    this.pickedFile,
    this.persistentPath = '/test/receipt_images/receipt_12345.jpg',
    this.fileExistsReturn = true,
    this.pickException,
    this.copyException,
  });

  XFile? pickedFile;
  String persistentPath;
  bool fileExistsReturn;
  Exception? pickException;
  Exception? copyException;

  int pickImageCallCount = 0;
  ImageSource? lastPickSource;
  int copyCallCount = 0;
  int deleteCallCount = 0;
  String? lastDeletedPath;

  @override
  Future<XFile?> pickImage({required ImageSource source}) async {
    pickImageCallCount++;
    lastPickSource = source;
    if (pickException != null) throw pickException!;
    return pickedFile;
  }

  @override
  Future<String> copyToPersistentStorage(String sourcePath) async {
    copyCallCount++;
    if (copyException != null) throw copyException!;
    return persistentPath;
  }

  @override
  Future<void> deleteImageIfUnreferenced(
    String path, {
    ReceiptsRepository? repository,
  }) async {
    deleteCallCount++;
    lastDeletedPath = path;
  }

  @override
  bool fileExists(String path) => fileExistsReturn;
}

Widget _buildTestApp({
  required AppDatabase db,
  ValueChanged<Map<String, dynamic>>? onSubmit,
  DateTime? initialDate,
  ThemeMode themeMode = ThemeMode.light,
  NavigatorObserver? navigatorObserver,
  ReceiptsRepository? repository,
  ReceiptImageService? imageService,
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      if (repository != null)
        receiptsRepositoryProvider.overrideWithValue(repository),
      if (imageService != null)
        receiptImageServiceProvider.overrideWithValue(imageService),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      navigatorObservers: [?navigatorObserver],
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AddReceiptScreen(
                        onSubmit: onSubmit,
                        repository: repository,
                        initialDate: initialDate,
                        imageService: imageService,
                      ),
                    ),
                  );
                },
                child: const Text('Open Add Receipt'),
              ),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  group('AddReceiptScreen UI & Form Validation', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders all form fields, labels, placeholders, and buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(db: db, initialDate: DateTime(2026, 10, 16)),
      );
      await tester.tap(find.text('Open Add Receipt'));
      await tester.pumpAndSettle();

      // AppBar
      expect(find.text('Add Receipt'), findsOneWidget);
      expect(find.byKey(const Key('add_receipt_back_button')), findsOneWidget);

      // Photo upload placeholder
      expect(find.byKey(const Key('add_receipt_photo_button')), findsOneWidget);
      expect(find.text('Add Photo'), findsOneWidget);
      expect(find.text('Tap to scan or upload a receipt'), findsOneWidget);

      // Product Name
      expect(find.text('PRODUCT NAME'), findsOneWidget);
      expect(
        find.byKey(const Key('add_receipt_product_name_field')),
        findsOneWidget,
      );
      expect(find.text('e.g. MacBook Pro M3'), findsOneWidget);

      // Store Name
      expect(find.text('STORE NAME'), findsOneWidget);
      expect(
        find.byKey(const Key('add_receipt_store_name_field')),
        findsOneWidget,
      );
      expect(find.text('e.g. Apple Store'), findsOneWidget);

      // Category chips
      expect(find.text('CATEGORY'), findsOneWidget);
      for (final cat in AddReceiptScreen.categories) {
        expect(
          find.byKey(Key('add_receipt_category_$cat')),
          findsOneWidget,
          reason: 'Expected category chip for $cat',
        );
      }

      // Total Amount (Price)
      expect(find.text('TOTAL AMOUNT'), findsOneWidget);
      expect(find.byKey(const Key('add_receipt_price_field')), findsOneWidget);
      expect(find.text(r'$'), findsOneWidget);

      // Purchase Date
      expect(find.text('PURCHASE DATE'), findsOneWidget);
      expect(
        find.byKey(const Key('add_receipt_date_picker_button')),
        findsOneWidget,
      );
      expect(find.text('Oct 16, 2026'), findsOneWidget);

      // Warranty Dropdown
      expect(find.text('WARRANTY DURATION'), findsOneWidget);
      expect(
        find.byKey(const Key('add_receipt_warranty_dropdown')),
        findsOneWidget,
      );

      // Notes
      expect(find.text('NOTES'), findsOneWidget);
      expect(find.byKey(const Key('add_receipt_notes_field')), findsOneWidget);

      // Save Receipt button
      expect(find.byKey(const Key('add_receipt_save_button')), findsOneWidget);
      expect(find.text('Save Receipt'), findsOneWidget);
    });

    testWidgets(
      'validates required fields on submission and shows error messages',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(db: db, initialDate: DateTime(2026, 10, 16)),
        );
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        // Tap Save Receipt with empty inputs
        final saveButtonFinder = find.byKey(
          const Key('add_receipt_save_button'),
        );
        await tester.ensureVisible(saveButtonFinder);
        await tester.tap(saveButtonFinder);
        await tester.pumpAndSettle();

        // Errors should be displayed for missing required fields
        expect(find.text('Please enter a product name'), findsOneWidget);
        expect(find.text('Please enter the total amount'), findsOneWidget);
      },
    );

    testWidgets('validates invalid price amounts', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(db: db, initialDate: DateTime(2026, 10, 16)),
      );
      await tester.tap(find.text('Open Add Receipt'));
      await tester.pumpAndSettle();

      final productNameField = find.byKey(
        const Key('add_receipt_product_name_field'),
      );
      final priceField = find.byKey(const Key('add_receipt_price_field'));
      final saveButton = find.byKey(const Key('add_receipt_save_button'));

      await tester.enterText(productNameField, 'Sony Headphones');
      await tester.enterText(priceField, '.');

      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter a valid non-negative amount'),
        findsOneWidget,
      );
    });

    testWidgets('reveals custom warranty input and validates custom days', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(db: db, initialDate: DateTime(2026, 10, 16)),
      );
      await tester.tap(find.text('Open Add Receipt'));
      await tester.pumpAndSettle();

      final warrantyDropdown = find.byKey(
        const Key('add_receipt_warranty_dropdown'),
      );
      await tester.ensureVisible(warrantyDropdown);
      await tester.tap(warrantyDropdown);
      await tester.pumpAndSettle();

      // Select 'Custom duration...'
      await tester.tap(find.text('Custom duration...').last);
      await tester.pumpAndSettle();

      // Custom warranty field should now appear
      expect(find.text('CUSTOM DURATION (DAYS)'), findsOneWidget);
      final customField = find.byKey(
        const Key('add_receipt_custom_warranty_field'),
      );
      expect(customField, findsOneWidget);

      // Try submitting without entering custom days
      final saveButton = find.byKey(const Key('add_receipt_save_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter warranty duration in days'),
        findsOneWidget,
      );
    });

    testWidgets(
      'submits valid form data, persists to SQLite, and returns to previous screen',
      (tester) async {
        Map<String, dynamic>? submittedData;

        await tester.pumpWidget(
          _buildTestApp(
            db: db,
            initialDate: DateTime(2026, 10, 16),
            onSubmit: (data) => submittedData = data,
          ),
        );
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        // 1. Product Name
        await tester.enterText(
          find.byKey(const Key('add_receipt_product_name_field')),
          'MacBook Pro M3',
        );

        // 2. Store Name
        await tester.enterText(
          find.byKey(const Key('add_receipt_store_name_field')),
          'Apple Store Regent St',
        );

        // 3. Category Chip: Clothing
        await tester.tap(
          find.byKey(const Key('add_receipt_category_Clothing')),
        );
        await tester.pumpAndSettle();

        // 4. Price
        await tester.enterText(
          find.byKey(const Key('add_receipt_price_field')),
          '1999.50',
        );

        // 5. Warranty: 12 months (1 year)
        final dropdownFinder = find.byKey(
          const Key('add_receipt_warranty_dropdown'),
        );
        await tester.ensureVisible(dropdownFinder);
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();
        await tester.tap(find.text('12 months (1 year)').last);
        await tester.pumpAndSettle();

        // 6. Notes
        final notesFinder = find.byKey(const Key('add_receipt_notes_field'));
        await tester.ensureVisible(notesFinder);
        await tester.enterText(
          notesFinder,
          'Serial: C02X12345. Includes AppleCare.',
        );

        // 7. Submit
        final saveButton = find.byKey(const Key('add_receipt_save_button'));
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Verify callback payload
        expect(submittedData, isNotNull);
        expect(submittedData!['id'], isA<int>());
        expect(submittedData!['productName'], 'MacBook Pro M3');
        expect(submittedData!['storeName'], 'Apple Store Regent St');
        expect(submittedData!['category'], 'Clothing');
        expect(submittedData!['totalAmount'], 1999.50);
        expect(submittedData!['warrantyDurationDays'], 365);
        expect(
          submittedData!['notes'],
          'Serial: C02X12345. Includes AppleCare.',
        );
        expect(submittedData!['purchaseDate'], DateTime(2026, 10, 16));

        // SnackBar indicates successful save
        expect(find.text('Receipt saved successfully!'), findsOneWidget);

        // Screen popped, returned to root screen
        expect(find.text('Add Receipt'), findsNothing);
        expect(find.text('Open Add Receipt'), findsOneWidget);

        // Verify record in SQLite database
        final records = await db.select(db.receipts).get();
        expect(records.length, 1);
        expect(records.first.productName, 'MacBook Pro M3');
        expect(records.first.storeName, 'Apple Store Regent St');
        expect(records.first.totalAmount, 1999.50);
        expect(records.first.warrantyDurationDays, 365);
        expect(records.first.notes, 'Serial: C02X12345. Includes AppleCare.');
        expect(records.first.category, 'Clothing');
      },
    );

    testWidgets(
      'preserves entered values and displays error snackbar when save fails',
      (tester) async {
        final mockRepo = _FailingReceiptsRepository();

        await tester.pumpWidget(
          _buildTestApp(
            db: db,
            repository: mockRepo,
            initialDate: DateTime(2026, 10, 16),
          ),
        );
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('add_receipt_product_name_field')),
          'Failing Item',
        );
        await tester.enterText(
          find.byKey(const Key('add_receipt_price_field')),
          '99.99',
        );

        final saveButton = find.byKey(const Key('add_receipt_save_button'));
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Error message displayed
        expect(find.textContaining('Failed to save receipt'), findsOneWidget);

        // Screen remains open
        expect(find.text('Add Receipt'), findsOneWidget);

        // Inputs are preserved
        expect(find.text('Failing Item'), findsOneWidget);
        expect(find.text('99.99'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping photo upload placeholder opens photo source modal bottom sheet',
      (tester) async {
        await tester.pumpWidget(_buildTestApp(db: db));
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        final photoButton = find.byKey(const Key('add_receipt_photo_button'));
        await tester.tap(photoButton);
        await tester.pumpAndSettle();

        expect(find.text('Attach Receipt Photo'), findsOneWidget);
        expect(
          find.byKey(const Key('add_receipt_photo_source_camera')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('add_receipt_photo_source_gallery')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'cancelling photo selection leaves form intact without error snackbar',
      (tester) async {
        final imageService = _TestReceiptImageService(pickedFile: null);

        await tester.pumpWidget(
          _buildTestApp(db: db, imageService: imageService),
        );
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        // Enter some text first to verify preservation
        await tester.enterText(
          find.byKey(const Key('add_receipt_product_name_field')),
          'Coffee Beans',
        );

        final photoButton = find.byKey(const Key('add_receipt_photo_button'));
        await tester.tap(photoButton);
        await tester.pumpAndSettle();

        // Tap gallery option
        await tester.tap(
          find.byKey(const Key('add_receipt_photo_source_gallery')),
        );
        await tester.pumpAndSettle();

        expect(imageService.pickImageCallCount, 1);
        expect(imageService.lastPickSource, ImageSource.gallery);
        expect(imageService.copyCallCount, 0);

        // Still on pristine photo button
        expect(
          find.byKey(const Key('add_receipt_photo_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('add_receipt_photo_preview_container')),
          findsNothing,
        );

        // Form field is preserved
        expect(find.text('Coffee Beans'), findsOneWidget);
        // No snackbar
        expect(find.byType(SnackBar), findsNothing);
      },
    );

    testWidgets(
      'selecting photo from gallery copies to persistent storage and shows preview',
      (tester) async {
        final tempDir = Directory.systemTemp.createTempSync('receipt_test_');
        final tempImage = File('${tempDir.path}/photo.png')
          ..writeAsBytesSync([
            0x89,
            0x50,
            0x4E,
            0x47,
            0x0D,
            0x0A,
            0x1A,
            0x0A,
            0x00,
            0x00,
            0x00,
            0x0D,
            0x49,
            0x48,
            0x44,
            0x52,
            0x00,
            0x00,
            0x00,
            0x01,
            0x00,
            0x00,
            0x00,
            0x01,
            0x08,
            0x06,
            0x00,
            0x00,
            0x00,
            0x1F,
            0x15,
            0xC4,
            0x89,
            0x00,
            0x00,
            0x00,
            0x0A,
            0x49,
            0x44,
            0x41,
            0x54,
            0x78,
            0x9C,
            0x63,
            0x00,
            0x01,
            0x00,
            0x00,
            0x05,
            0x00,
            0x01,
            0x0D,
            0x0A,
            0x2D,
            0xB4,
            0x00,
            0x00,
            0x00,
            0x00,
            0x49,
            0x45,
            0x4E,
            0x44,
            0xAE,
            0x42,
            0x60,
            0x82,
          ]);

        final imageService = _TestReceiptImageService(
          pickedFile: XFile(tempImage.path),
          persistentPath: tempImage.path,
          fileExistsReturn: true,
        );

        await tester.pumpWidget(
          _buildTestApp(db: db, imageService: imageService),
        );
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('add_receipt_product_name_field')),
          'Office Chair',
        );

        // Tap Add Photo -> Choose from Gallery
        await tester.tap(find.byKey(const Key('add_receipt_photo_button')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('add_receipt_photo_source_gallery')),
        );
        await tester.pumpAndSettle();

        expect(imageService.pickImageCallCount, 1);
        expect(imageService.copyCallCount, 1);

        // Photo preview is now shown
        expect(
          find.byKey(const Key('add_receipt_photo_preview_container')),
          findsOneWidget,
        );
        expect(find.text('Photo attached'), findsOneWidget);
        expect(
          find.byKey(const Key('add_receipt_replace_photo_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('add_receipt_remove_photo_button')),
          findsOneWidget,
        );

        // Existing form values preserved
        expect(find.text('Office Chair'), findsOneWidget);

        tempDir.deleteSync(recursive: true);
      },
    );

    testWidgets(
      'capturing photo from camera copies to persistent storage and shows preview',
      (tester) async {
        final tempDir = Directory.systemTemp.createTempSync('receipt_test_');
        final tempImage = File('${tempDir.path}/camera.png')
          ..writeAsBytesSync([
            0x89,
            0x50,
            0x4E,
            0x47,
            0x0D,
            0x0A,
            0x1A,
            0x0A,
            0x00,
            0x00,
            0x00,
            0x0D,
            0x49,
            0x48,
            0x44,
            0x52,
            0x00,
            0x00,
            0x00,
            0x01,
            0x00,
            0x00,
            0x00,
            0x01,
            0x08,
            0x06,
            0x00,
            0x00,
            0x00,
            0x1F,
            0x15,
            0xC4,
            0x89,
            0x00,
            0x00,
            0x00,
            0x0A,
            0x49,
            0x44,
            0x41,
            0x54,
            0x78,
            0x9C,
            0x63,
            0x00,
            0x01,
            0x00,
            0x00,
            0x05,
            0x00,
            0x01,
            0x0D,
            0x0A,
            0x2D,
            0xB4,
            0x00,
            0x00,
            0x00,
            0x00,
            0x49,
            0x45,
            0x4E,
            0x44,
            0xAE,
            0x42,
            0x60,
            0x82,
          ]);

        final imageService = _TestReceiptImageService(
          pickedFile: XFile(tempImage.path),
          persistentPath: tempImage.path,
          fileExistsReturn: true,
        );

        await tester.pumpWidget(
          _buildTestApp(db: db, imageService: imageService),
        );
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        // Tap Add Photo -> Take Photo
        await tester.tap(find.byKey(const Key('add_receipt_photo_button')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('add_receipt_photo_source_camera')),
        );
        await tester.pumpAndSettle();

        expect(imageService.pickImageCallCount, 1);
        expect(imageService.lastPickSource, ImageSource.camera);
        expect(imageService.copyCallCount, 1);

        expect(
          find.byKey(const Key('add_receipt_photo_preview_container')),
          findsOneWidget,
        );
        expect(find.text('Photo attached'), findsOneWidget);

        tempDir.deleteSync(recursive: true);
      },
    );

    testWidgets(
      'replacing photo opens bottom sheet, updates preview, and cleans uncommitted file',
      (tester) async {
        final tempDir = Directory.systemTemp.createTempSync('receipt_test_');
        final file1 = File('${tempDir.path}/img1.png')
          ..writeAsBytesSync([
            0x89,
            0x50,
            0x4E,
            0x47,
            0x0D,
            0x0A,
            0x1A,
            0x0A,
            0x00,
            0x00,
            0x00,
            0x0D,
            0x49,
            0x48,
            0x44,
            0x52,
            0x00,
            0x00,
            0x00,
            0x01,
            0x00,
            0x00,
            0x00,
            0x01,
            0x08,
            0x06,
            0x00,
            0x00,
            0x00,
            0x1F,
            0x15,
            0xC4,
            0x89,
            0x00,
            0x00,
            0x00,
            0x0A,
            0x49,
            0x44,
            0x41,
            0x54,
            0x78,
            0x9C,
            0x63,
            0x00,
            0x01,
            0x00,
            0x00,
            0x05,
            0x00,
            0x01,
            0x0D,
            0x0A,
            0x2D,
            0xB4,
            0x00,
            0x00,
            0x00,
            0x00,
            0x49,
            0x45,
            0x4E,
            0x44,
            0xAE,
            0x42,
            0x60,
            0x82,
          ]);
        final file2 = File('${tempDir.path}/img2.png')
          ..writeAsBytesSync([
            0x89,
            0x50,
            0x4E,
            0x47,
            0x0D,
            0x0A,
            0x1A,
            0x0A,
            0x00,
            0x00,
            0x00,
            0x0D,
            0x49,
            0x48,
            0x44,
            0x52,
            0x00,
            0x00,
            0x00,
            0x01,
            0x00,
            0x00,
            0x00,
            0x01,
            0x08,
            0x06,
            0x00,
            0x00,
            0x00,
            0x1F,
            0x15,
            0xC4,
            0x89,
            0x00,
            0x00,
            0x00,
            0x0A,
            0x49,
            0x44,
            0x41,
            0x54,
            0x78,
            0x9C,
            0x63,
            0x00,
            0x01,
            0x00,
            0x00,
            0x05,
            0x00,
            0x01,
            0x0D,
            0x0A,
            0x2D,
            0xB4,
            0x00,
            0x00,
            0x00,
            0x00,
            0x49,
            0x45,
            0x4E,
            0x44,
            0xAE,
            0x42,
            0x60,
            0x82,
          ]);

        final imageService = _TestReceiptImageService(
          pickedFile: XFile(file1.path),
          persistentPath: file1.path,
        );

        await tester.pumpWidget(
          _buildTestApp(db: db, imageService: imageService),
        );
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        // Attach first photo
        await tester.tap(find.byKey(const Key('add_receipt_photo_button')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('add_receipt_photo_source_gallery')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('add_receipt_photo_preview_container')),
          findsOneWidget,
        );

        // Now replace with second photo
        imageService.pickedFile = XFile(file2.path);
        imageService.persistentPath = file2.path;

        await tester.tap(
          find.byKey(const Key('add_receipt_replace_photo_button')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Attach Receipt Photo'), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('add_receipt_photo_source_camera')),
        );
        await tester.pumpAndSettle();

        expect(imageService.pickImageCallCount, 2);
        expect(imageService.copyCallCount, 2);
        // Previous uncommitted file was cleaned up
        expect(imageService.deleteCallCount, 1);
        expect(imageService.lastDeletedPath, file1.path);

        tempDir.deleteSync(recursive: true);
      },
    );

    testWidgets(
      'removing photo removes preview, restores Add Photo, and cleans uncommitted file',
      (tester) async {
        final tempDir = Directory.systemTemp.createTempSync('receipt_test_');
        final file = File('${tempDir.path}/img.png')
          ..writeAsBytesSync([
            0x89,
            0x50,
            0x4E,
            0x47,
            0x0D,
            0x0A,
            0x1A,
            0x0A,
            0x00,
            0x00,
            0x00,
            0x0D,
            0x49,
            0x48,
            0x44,
            0x52,
            0x00,
            0x00,
            0x00,
            0x01,
            0x00,
            0x00,
            0x00,
            0x01,
            0x08,
            0x06,
            0x00,
            0x00,
            0x00,
            0x1F,
            0x15,
            0xC4,
            0x89,
            0x00,
            0x00,
            0x00,
            0x0A,
            0x49,
            0x44,
            0x41,
            0x54,
            0x78,
            0x9C,
            0x63,
            0x00,
            0x01,
            0x00,
            0x00,
            0x05,
            0x00,
            0x01,
            0x0D,
            0x0A,
            0x2D,
            0xB4,
            0x00,
            0x00,
            0x00,
            0x00,
            0x49,
            0x45,
            0x4E,
            0x44,
            0xAE,
            0x42,
            0x60,
            0x82,
          ]);

        final imageService = _TestReceiptImageService(
          pickedFile: XFile(file.path),
          persistentPath: file.path,
        );

        await tester.pumpWidget(
          _buildTestApp(db: db, imageService: imageService),
        );
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('add_receipt_product_name_field')),
          'Mechanical Keyboard',
        );

        // Attach photo
        await tester.tap(find.byKey(const Key('add_receipt_photo_button')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('add_receipt_photo_source_gallery')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('add_receipt_photo_preview_container')),
          findsOneWidget,
        );

        // Remove photo
        await tester.tap(
          find.byKey(const Key('add_receipt_remove_photo_button')),
        );
        await tester.pumpAndSettle();

        expect(imageService.deleteCallCount, 1);
        expect(imageService.lastDeletedPath, file.path);

        // Preview is gone, placeholder is back
        expect(
          find.byKey(const Key('add_receipt_photo_preview_container')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('add_receipt_photo_button')),
          findsOneWidget,
        );

        // Form field is still intact
        expect(find.text('Mechanical Keyboard'), findsOneWidget);

        tempDir.deleteSync(recursive: true);
      },
    );

    testWidgets(
      'saving receipt with attached photo persists persistent imagePath into SQLite',
      (tester) async {
        final tempDir = Directory.systemTemp.createTempSync('receipt_test_');
        final file = File('${tempDir.path}/persisted_receipt.png')
          ..writeAsBytesSync([
            0x89,
            0x50,
            0x4E,
            0x47,
            0x0D,
            0x0A,
            0x1A,
            0x0A,
            0x00,
            0x00,
            0x00,
            0x0D,
            0x49,
            0x48,
            0x44,
            0x52,
            0x00,
            0x00,
            0x00,
            0x01,
            0x00,
            0x00,
            0x00,
            0x01,
            0x08,
            0x06,
            0x00,
            0x00,
            0x00,
            0x1F,
            0x15,
            0xC4,
            0x89,
            0x00,
            0x00,
            0x00,
            0x0A,
            0x49,
            0x44,
            0x41,
            0x54,
            0x78,
            0x9C,
            0x63,
            0x00,
            0x01,
            0x00,
            0x00,
            0x05,
            0x00,
            0x01,
            0x0D,
            0x0A,
            0x2D,
            0xB4,
            0x00,
            0x00,
            0x00,
            0x00,
            0x49,
            0x45,
            0x4E,
            0x44,
            0xAE,
            0x42,
            0x60,
            0x82,
          ]);

        final imageService = _TestReceiptImageService(
          pickedFile: XFile(file.path),
          persistentPath: file.path,
        );

        Map<String, dynamic>? submittedData;

        await tester.pumpWidget(
          _buildTestApp(
            db: db,
            imageService: imageService,
            onSubmit: (data) => submittedData = data,
          ),
        );
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        // Fill form
        await tester.enterText(
          find.byKey(const Key('add_receipt_product_name_field')),
          'Sony WH-1000XM5',
        );
        await tester.enterText(
          find.byKey(const Key('add_receipt_price_field')),
          '398.00',
        );

        // Attach photo
        final photoButton = find.byKey(const Key('add_receipt_photo_button'));
        await tester.ensureVisible(photoButton);
        await tester.tap(photoButton);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('add_receipt_photo_source_gallery')),
        );
        await tester.pumpAndSettle();

        // Submit form
        final saveButton = find.byKey(const Key('add_receipt_save_button'));
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Verify onSubmit received imagePath
        expect(submittedData, isNotNull);
        expect(submittedData!['imagePath'], file.path);

        // Verify SQLite database record
        final allReceipts = await db.select(db.receipts).get();
        expect(allReceipts.length, 1);
        expect(allReceipts.first.productName, 'Sony WH-1000XM5');
        expect(allReceipts.first.imagePath, file.path);

        tempDir.deleteSync(recursive: true);
      },
    );

    testWidgets(
      'saving receipt without photo persists null/absent imagePath into SQLite',
      (tester) async {
        Map<String, dynamic>? submittedData;

        await tester.pumpWidget(
          _buildTestApp(db: db, onSubmit: (data) => submittedData = data),
        );
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('add_receipt_product_name_field')),
          'Wireless Mouse',
        );
        await tester.enterText(
          find.byKey(const Key('add_receipt_price_field')),
          '29.99',
        );

        final saveButton = find.byKey(const Key('add_receipt_save_button'));
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(submittedData!['imagePath'], isNull);

        final allReceipts = await db.select(db.receipts).get();
        expect(allReceipts.length, 1);
        expect(allReceipts.first.imagePath, isNull);
      },
    );

    testWidgets(
      'permission denial displays error snackbar and preserves entered values',
      (tester) async {
        final imageService = _TestReceiptImageService(
          pickException: PlatformException(
            code: 'camera_access_denied',
            message: 'Camera permission denied',
          ),
        );

        await tester.pumpWidget(
          _buildTestApp(db: db, imageService: imageService),
        );
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('add_receipt_product_name_field')),
          'Preserved Monitor',
        );
        await tester.enterText(
          find.byKey(const Key('add_receipt_price_field')),
          '299.99',
        );

        final photoButton = find.byKey(const Key('add_receipt_photo_button'));
        await tester.ensureVisible(photoButton);
        await tester.tap(photoButton);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('add_receipt_photo_source_camera')),
        );
        await tester.pumpAndSettle();

        // Error snackbar shown
        expect(
          find.text(
            'Camera or photo library permission was denied. Please allow access in Settings.',
          ),
          findsOneWidget,
        );

        // Other form values are preserved!
        expect(find.text('Preserved Monitor'), findsOneWidget);
        expect(find.text('299.99'), findsOneWidget);
      },
    );

    testWidgets(
      'unsupported platform error displays error snackbar and preserves entered values',
      (tester) async {
        final imageService = _TestReceiptImageService(
          pickException: PlatformException(
            code: 'camera_not_available',
            message: 'No camera hardware found',
          ),
        );

        await tester.pumpWidget(
          _buildTestApp(db: db, imageService: imageService),
        );
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('add_receipt_product_name_field')),
          'USB Cable',
        );

        await tester.tap(find.byKey(const Key('add_receipt_photo_button')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('add_receipt_photo_source_camera')),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Camera or photo selection is not supported on this device.',
          ),
          findsOneWidget,
        );
        expect(find.text('USB Cable'), findsOneWidget);
      },
    );

    testWidgets(
      'file copy error displays error snackbar and preserves entered values',
      (tester) async {
        final imageService = _TestReceiptImageService(
          pickedFile: XFile('/temp/dummy.jpg'),
          copyException: const FileSystemException('Disk full'),
        );

        await tester.pumpWidget(
          _buildTestApp(db: db, imageService: imageService),
        );
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('add_receipt_product_name_field')),
          'Tablet Stand',
        );

        await tester.tap(find.byKey(const Key('add_receipt_photo_button')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('add_receipt_photo_source_gallery')),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'Failed to attach photo: FileSystemException: Disk full',
          ),
          findsOneWidget,
        );
        expect(find.text('Tablet Stand'), findsOneWidget);
      },
    );

    testWidgets(
      'missing image file displays safe error fallback and preserves replace/remove controls',
      (tester) async {
        final imageService = _TestReceiptImageService(
          pickedFile: XFile('/non_existent/path.png'),
          persistentPath: '/non_existent/path.png',
          fileExistsReturn: false, // File is missing!
        );

        await tester.pumpWidget(
          _buildTestApp(db: db, imageService: imageService),
        );
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('add_receipt_photo_button')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('add_receipt_photo_source_gallery')),
        );
        await tester.pumpAndSettle();

        // Safe fallback is rendered
        expect(
          find.byKey(const Key('add_receipt_photo_missing_fallback')),
          findsOneWidget,
        );
        expect(
          find.text('Image file not found or could not be loaded'),
          findsOneWidget,
        );

        // Replace and Remove buttons are still fully accessible
        expect(
          find.byKey(const Key('add_receipt_replace_photo_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('add_receipt_remove_photo_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'unsaved edits confirmation triggers when only photo is attached and cleans up on discard',
      (tester) async {
        final imageService = _TestReceiptImageService(
          pickedFile: XFile('/temp/discard_test.jpg'),
          persistentPath: '/test/receipt_images/discard_test.jpg',
        );

        await tester.pumpWidget(
          _buildTestApp(
            db: db,
            imageService: imageService,
            initialDate: DateTime(2026, 10, 16),
          ),
        );
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        // Attach photo only (no text entered)
        await tester.tap(find.byKey(const Key('add_receipt_photo_button')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('add_receipt_photo_source_gallery')),
        );
        await tester.pumpAndSettle();

        // Tap back button
        await tester.tap(find.byKey(const Key('add_receipt_back_button')));
        await tester.pumpAndSettle();

        // Discard dialog is displayed because photo made form dirty!
        expect(find.text('Discard changes?'), findsOneWidget);

        // Confirm discard
        await tester.tap(
          find.byKey(const Key('add_receipt_discard_confirm_button')),
        );
        await tester.pumpAndSettle();

        // Cleaned up the unreferenced file!
        expect(imageService.deleteCallCount, 1);
        expect(
          imageService.lastDeletedPath,
          '/test/receipt_images/discard_test.jpg',
        );

        // Navigated back
        expect(find.text('Add Receipt'), findsNothing);
      },
    );

    testWidgets(
      'pops immediately when back button is tapped on pristine form',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(db: db, initialDate: DateTime(2026, 10, 16)),
        );
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        expect(find.text('Add Receipt'), findsOneWidget);

        // Back button tapped without changes
        await tester.tap(find.byKey(const Key('add_receipt_back_button')));
        await tester.pumpAndSettle();

        // Should have returned to parent screen immediately without dialog
        expect(find.text('Add Receipt'), findsNothing);
        expect(find.text('Open Add Receipt'), findsOneWidget);
      },
    );

    testWidgets(
      'warns with confirmation dialog on back when form has unsaved edits',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(db: db, initialDate: DateTime(2026, 10, 16)),
        );
        await tester.tap(find.text('Open Add Receipt'));
        await tester.pumpAndSettle();

        // Enter some text into product name (dirty state)
        await tester.enterText(
          find.byKey(const Key('add_receipt_product_name_field')),
          'iPad Air',
        );

        // Tap back button
        await tester.tap(find.byKey(const Key('add_receipt_back_button')));
        await tester.pumpAndSettle();

        // Dialog should appear
        expect(find.text('Discard changes?'), findsOneWidget);
        expect(
          find.text(
            'You have unsaved changes. Are you sure you want to discard them and leave?',
          ),
          findsOneWidget,
        );

        // 1. Tap Keep Editing
        await tester.tap(
          find.byKey(const Key('add_receipt_keep_editing_button')),
        );
        await tester.pumpAndSettle();

        // Remains on Add Receipt screen
        expect(find.text('Add Receipt'), findsOneWidget);
        expect(find.text('iPad Air'), findsOneWidget);

        // 2. Tap back again and confirm Discard
        await tester.tap(find.byKey(const Key('add_receipt_back_button')));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('add_receipt_discard_confirm_button')),
        );
        await tester.pumpAndSettle();

        // Screen popped, back to root
        expect(find.text('Add Receipt'), findsNothing);
        expect(find.text('Open Add Receipt'), findsOneWidget);
      },
    );

    testWidgets('renders cleanly in dark mode without errors or overflows', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          db: db,
          initialDate: DateTime(2026, 10, 16),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.tap(find.text('Open Add Receipt'));
      await tester.pumpAndSettle();

      expect(find.text('Add Receipt'), findsOneWidget);
      expect(find.text('PRODUCT NAME'), findsOneWidget);
      expect(find.text('Save Receipt'), findsOneWidget);
    });

    testWidgets(
      'saved receipt reactively updates ReceiptsScreen stream and appears in list',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: AppTheme.light,
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: const ReceiptsScreen(),
                    floatingActionButton: FloatingActionButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AddReceiptScreen(),
                          ),
                        );
                      },
                      child: const Icon(Icons.add),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially empty state
        expect(find.text('No receipts yet'), findsOneWidget);

        // Tap Add
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Enter receipt details
        await tester.enterText(
          find.byKey(const Key('add_receipt_product_name_field')),
          'PlayStation 5',
        );
        await tester.enterText(
          find.byKey(const Key('add_receipt_price_field')),
          '499.00',
        );

        // Submit
        final saveButton = find.byKey(const Key('add_receipt_save_button'));
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Returned to ReceiptsScreen
        expect(find.text('Add Receipt'), findsNothing);

        // Reactive stream updated: PlayStation 5 card is visible!
        expect(find.text('PlayStation 5'), findsOneWidget);
        expect(find.text(r'$499'), findsOneWidget);
        expect(find.text('No receipts yet'), findsNothing);

        // Clean up Drift query stream debounce timer
        await db.close();
        await tester.pump(const Duration(milliseconds: 50));
      },
    );

    testWidgets('prefills all fields when opened with receiptToEdit', (
      tester,
    ) async {
      final receiptToEdit = Receipt(
        id: 5,
        productName: 'Sony WH-1000XM5',
        storeName: 'Sony Direct',
        category: 'Electronics',
        purchaseDate: DateTime(2026, 4, 10),
        totalAmount: 399.99,
        warrantyDurationDays: 730,
        notes: 'Silver color with carrying pouch',
        imagePath: '/test/receipt_images/receipt_12345.jpg',
        createdAt: DateTime(2026, 4, 10),
      );

      final imageService = _TestReceiptImageService(fileExistsReturn: true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AddReceiptScreen(
            receiptToEdit: receiptToEdit,
            imageService: imageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // App bar title and Save button label
      expect(find.text('Edit Receipt'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Form fields prefilled
      expect(find.text('Sony WH-1000XM5'), findsOneWidget);
      expect(find.text('Sony Direct'), findsOneWidget);
      expect(find.text('399.99'), findsOneWidget);
      expect(find.text('Silver color with carrying pouch'), findsOneWidget);
      expect(find.text('Apr 10, 2026'), findsOneWidget);
      expect(find.text('24 months (2 years)'), findsOneWidget);

      // Image preview attached
      expect(find.text('Photo attached'), findsOneWidget);
      expect(find.text('Replace'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);

      // Pristine edit form pops immediately without discard confirmation
      await tester.tap(find.byKey(const Key('add_receipt_back_button')));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
    });

    testWidgets(
      'editing updates existing receipt record in SQLite without creating duplicate',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        final repository = DriftReceiptsRepository(db);

        // Insert initial receipt
        final initialId = await repository.insertReceipt(
          ReceiptsCompanion.insert(
            productName: 'Original Headphones',
            storeName: const drift.Value('Best Buy'),
            category: const drift.Value('Electronics'),
            purchaseDate: DateTime(2026, 1, 1),
            totalAmount: 199.99,
            warrantyDurationDays: const drift.Value(365),
            notes: const drift.Value('Original note'),
          ),
        );

        final initialReceipt = (await repository.getReceiptById(initialId))!;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              receiptsRepositoryProvider.overrideWithValue(repository),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: AddReceiptScreen(
                receiptToEdit: initialReceipt,
                repository: repository,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Modify product name and price
        final nameField = find.byKey(
          const Key('add_receipt_product_name_field'),
        );
        await tester.enterText(nameField, 'Updated Sony Headphones');

        final priceField = find.byKey(const Key('add_receipt_price_field'));
        await tester.enterText(priceField, '149.50');

        // Submit changes
        final saveButton = find.byKey(const Key('add_receipt_save_button'));
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Verify SQLite database: exactly 1 record, updated fields, same ID
        final allReceipts = await repository.getAllReceipts();
        expect(allReceipts.length, 1);

        final updated = allReceipts.first;
        expect(updated.id, initialId);
        expect(updated.productName, 'Updated Sony Headphones');
        expect(updated.totalAmount, 149.50);
        expect(updated.storeName, 'Best Buy'); // Preserved

        await db.close();
        await tester.pump(const Duration(milliseconds: 50));
      },
    );

    testWidgets(
      'editing preserves existing imagePath when image is not modified',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        final repository = DriftReceiptsRepository(db);

        final initialId = await repository.insertReceipt(
          ReceiptsCompanion.insert(
            productName: 'DSLR Camera',
            purchaseDate: DateTime(2026, 2, 1),
            totalAmount: 1200.0,
            imagePath: const drift.Value('/persistent/camera_receipt.jpg'),
          ),
        );

        final initialReceipt = (await repository.getReceiptById(initialId))!;

        final imageService = _TestReceiptImageService(fileExistsReturn: true);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: AddReceiptScreen(
              receiptToEdit: initialReceipt,
              repository: repository,
              imageService: imageService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Modify only product name
        final nameField = find.byKey(
          const Key('add_receipt_product_name_field'),
        );
        await tester.enterText(nameField, 'Canon DSLR Camera');

        // Save
        final saveButton = find.byKey(const Key('add_receipt_save_button'));
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        final all = await repository.getAllReceipts();
        expect(all.length, 1);
        expect(all.first.productName, 'Canon DSLR Camera');
        expect(all.first.imagePath, '/persistent/camera_receipt.jpg');

        await db.close();
        await tester.pump(const Duration(milliseconds: 50));
      },
    );

    testWidgets('dirty checking in edit mode triggers discard dialog', (
      tester,
    ) async {
      final receiptToEdit = Receipt(
        id: 1,
        productName: 'Monitor',
        purchaseDate: DateTime(2026, 1, 1),
        totalAmount: 300.0,
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AddReceiptScreen(receiptToEdit: receiptToEdit),
        ),
      );
      await tester.pumpAndSettle();

      // Change product name
      final nameField = find.byKey(const Key('add_receipt_product_name_field'));
      await tester.enterText(nameField, 'Gaming Monitor 4K');

      // Tap back button
      await tester.tap(find.byKey(const Key('add_receipt_back_button')));
      await tester.pumpAndSettle();

      // Discard dialog is displayed
      expect(find.text('Discard changes?'), findsOneWidget);

      // Tap Keep Editing
      await tester.tap(
        find.byKey(const Key('add_receipt_keep_editing_button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Gaming Monitor 4K'), findsOneWidget);
    });

    group('Missing-receipt and loading edit flow (Task 2)', () {
      testWidgets(
        'shows loading indicator while fetching receipt by ID and hides form',
        (tester) async {
          final completer = Completer<Receipt?>();
          final repo = _CustomMockReceiptsRepository(
            onGetReceiptById: (id) => completer.future,
          );

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: AddReceiptScreen(receiptId: 10, repository: repo),
            ),
          );

          // Process microtask/frame callback to trigger loading
          await tester.pump();

          // Loading indicator is shown
          expect(
            find.byKey(const Key('add_receipt_loading_indicator')),
            findsOneWidget,
          );
          // Editable form card and fields are NOT rendered
          expect(
            find.byKey(const Key('add_receipt_product_name_field')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('add_receipt_save_button')),
            findsNothing,
          );

          // Complete with a receipt
          completer.complete(
            Receipt(
              id: 10,
              productName: 'Loaded Laptop',
              purchaseDate: DateTime(2026, 1, 1),
              totalAmount: 1200.0,
              createdAt: DateTime(2026, 1, 1),
            ),
          );
          await tester.pumpAndSettle();

          // Loading indicator disappears and form is rendered with data
          expect(
            find.byKey(const Key('add_receipt_loading_indicator')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('add_receipt_product_name_field')),
            findsOneWidget,
          );
          expect(find.text('Loaded Laptop'), findsOneWidget);
        },
      );

      testWidgets(
        'shows Receipt Not Found state when receipt ID does not exist in repository',
        (tester) async {
          final repo = _CustomMockReceiptsRepository(
            onGetReceiptById: (id) async => null,
          );

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: AddReceiptScreen(receiptId: 999, repository: repo),
            ),
          );
          await tester.pumpAndSettle();

          // Confirms not-found UI
          expect(find.text('Receipt Not Found'), findsOneWidget);
          expect(
            find.text('This receipt does not exist or may have been deleted.'),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('add_receipt_not_found_icon')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('add_receipt_not_found_back_button')),
            findsOneWidget,
          );

          // Blank editable form and save button are strictly NOT shown
          expect(
            find.byKey(const Key('add_receipt_product_name_field')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('add_receipt_save_button')),
            findsNothing,
          );

          // Back button does not show discard dialog
          await tester.tap(find.byKey(const Key('add_receipt_back_button')));
          await tester.pumpAndSettle();
          expect(find.text('Discard changes?'), findsNothing);
        },
      );

      testWidgets(
        'shows error state with retry button when repository retrieval throws',
        (tester) async {
          int callCount = 0;
          final repo = _CustomMockReceiptsRepository(
            onGetReceiptById: (id) async {
              callCount++;
              if (callCount == 1) {
                throw Exception('SQLite disk read I/O error');
              }
              return Receipt(
                id: id,
                productName: 'Retried Item',
                purchaseDate: DateTime(2026, 2, 2),
                totalAmount: 50.0,
                createdAt: DateTime(2026, 2, 2),
              );
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: AddReceiptScreen(receiptId: 42, repository: repo),
            ),
          );
          await tester.pumpAndSettle();

          // Confirms error UI
          expect(find.text('Failed to load receipt'), findsOneWidget);
          expect(
            find.textContaining('SQLite disk read I/O error'),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('add_receipt_error_icon')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('add_receipt_error_retry_button')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('add_receipt_error_back_button')),
            findsOneWidget,
          );

          // Blank editable form and save button are NOT displayed
          expect(
            find.byKey(const Key('add_receipt_product_name_field')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('add_receipt_save_button')),
            findsNothing,
          );

          // Tap Retry button
          await tester.tap(
            find.byKey(const Key('add_receipt_error_retry_button')),
          );
          await tester.pumpAndSettle();

          // Now loaded successfully
          expect(callCount, 2);
          expect(find.text('Failed to load receipt'), findsNothing);
          expect(find.text('Retried Item'), findsOneWidget);
          expect(
            find.byKey(const Key('add_receipt_save_button')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'successful load by receiptId populates all fields and updates existing record',
        (tester) async {
          final db = AppDatabase(NativeDatabase.memory());
          final repository = DriftReceiptsRepository(db);

          final id = await repository.insertReceipt(
            ReceiptsCompanion.insert(
              productName: 'Sony Headphones',
              storeName: const drift.Value('BestBuy'),
              category: const drift.Value('Electronics'),
              purchaseDate: DateTime(2026, 3, 10),
              totalAmount: 199.99,
              warrantyDurationDays: const drift.Value(365),
              notes: const drift.Value('Includes protection plan'),
            ),
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                databaseProvider.overrideWithValue(db),
                receiptsRepositoryProvider.overrideWithValue(repository),
              ],
              child: MaterialApp(
                theme: AppTheme.light,
                home: AddReceiptScreen(receiptId: id, repository: repository),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Verified all fields populated
          expect(find.text('Sony Headphones'), findsOneWidget);
          expect(find.text('BestBuy'), findsOneWidget);
          expect(find.text('199.99'), findsOneWidget);
          expect(find.text('Includes protection plan'), findsOneWidget);

          // Update product name
          final nameField = find.byKey(
            const Key('add_receipt_product_name_field'),
          );
          await tester.enterText(nameField, 'Sony WH-1000XM5');

          // Save update
          final saveButton = find.byKey(const Key('add_receipt_save_button'));
          await tester.ensureVisible(saveButton);
          await tester.tap(saveButton);
          await tester.pumpAndSettle();

          // Check DB record
          final updated = await repository.getReceiptById(id);
          expect(updated, isNotNull);
          expect(updated!.productName, 'Sony WH-1000XM5');
          expect(updated.storeName, 'BestBuy');
          expect(updated.totalAmount, 199.99);

          // Ensure no duplicate record was created
          final all = await repository.getAllReceipts();
          expect(all.length, 1);

          await db.close();
          await tester.pump(const Duration(milliseconds: 50));
        },
      );
    });

    group('Warranty Notifications Integration', () {
      testWidgets(
        'creating a receipt with valid warranty schedules notifications when enabled',
        (tester) async {
          final db = AppDatabase(NativeDatabase.memory());
          final repository = DriftReceiptsRepository(db);
          final fakeNotificationService = FakeWarrantyNotificationService();

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                databaseProvider.overrideWithValue(db),
                receiptsRepositoryProvider.overrideWithValue(repository),
                initialWarrantyNotificationsEnabledProvider.overrideWithValue(
                  true,
                ),
                warrantyNotificationServiceProvider.overrideWithValue(
                  fakeNotificationService,
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.light,
                home: AddReceiptScreen(
                  repository: repository,
                  notificationService: fakeNotificationService,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Enter product name and price
          await tester.enterText(
            find.byKey(const Key('add_receipt_product_name_field')),
            'MacBook Air',
          );
          await tester.enterText(
            find.byKey(const Key('add_receipt_price_field')),
            '999.00',
          );

          // Select 12 months warranty
          final dropdown = find.byKey(
            const Key('add_receipt_warranty_dropdown'),
          );
          await tester.ensureVisible(dropdown);
          await tester.tap(dropdown);
          await tester.pumpAndSettle();

          await tester.tap(find.text('12 months (1 year)').last);
          await tester.pumpAndSettle();

          // Save receipt
          final saveButton = find.byKey(const Key('add_receipt_save_button'));
          await tester.ensureVisible(saveButton);
          await tester.tap(saveButton);
          await tester.pumpAndSettle();

          // Check that reminders were scheduled
          expect(
            fakeNotificationService.callLog,
            anyElement(contains('MacBook Air')),
          );
          expect(
            (await fakeNotificationService.getScheduledReminders()).length,
            2,
          );

          await db.close();
          await tester.pump(const Duration(milliseconds: 50));
        },
      );

      testWidgets(
        'editing a receipt cancels old reminders and schedules updated reminders',
        (tester) async {
          final db = AppDatabase(NativeDatabase.memory());
          final repository = DriftReceiptsRepository(db);
          final fakeNotificationService = FakeWarrantyNotificationService();

          final id = await repository.insertReceipt(
            ReceiptsCompanion.insert(
              productName: 'Gaming Mouse',
              purchaseDate: DateTime.now(),
              totalAmount: 50.0,
              warrantyDurationDays: const drift.Value(180),
            ),
          );

          // Pre-populate scheduled reminders
          final initialReceipt = (await repository.getReceiptById(id))!;
          await fakeNotificationService.scheduleWarrantyReminders(
            initialReceipt,
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                databaseProvider.overrideWithValue(db),
                receiptsRepositoryProvider.overrideWithValue(repository),
                initialWarrantyNotificationsEnabledProvider.overrideWithValue(
                  true,
                ),
                warrantyNotificationServiceProvider.overrideWithValue(
                  fakeNotificationService,
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.light,
                home: AddReceiptScreen(
                  receiptId: id,
                  repository: repository,
                  notificationService: fakeNotificationService,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Update product name
          final nameField = find.byKey(
            const Key('add_receipt_product_name_field'),
          );
          await tester.enterText(nameField, 'Gaming Mouse Pro');

          // Save
          final saveButton = find.byKey(const Key('add_receipt_save_button'));
          await tester.ensureVisible(saveButton);
          await tester.tap(saveButton);
          await tester.pumpAndSettle();

          expect(
            fakeNotificationService.callLog,
            contains('cancelWarrantyReminders:$id'),
          );
          expect(
            fakeNotificationService.callLog,
            anyElement(contains('Gaming Mouse Pro')),
          );

          await db.close();
          await tester.pump(const Duration(milliseconds: 50));
        },
      );

      testWidgets(
        'creating a receipt with no warranty does not schedule reminders',
        (tester) async {
          final db = AppDatabase(NativeDatabase.memory());
          final repository = DriftReceiptsRepository(db);
          final fakeNotificationService = FakeWarrantyNotificationService();

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                databaseProvider.overrideWithValue(db),
                receiptsRepositoryProvider.overrideWithValue(repository),
                initialWarrantyNotificationsEnabledProvider.overrideWithValue(
                  true,
                ),
                warrantyNotificationServiceProvider.overrideWithValue(
                  fakeNotificationService,
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.light,
                home: AddReceiptScreen(
                  repository: repository,
                  notificationService: fakeNotificationService,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Enter product name and price, leave warranty as No warranty
          await tester.enterText(
            find.byKey(const Key('add_receipt_product_name_field')),
            'Groceries',
          );
          await tester.enterText(
            find.byKey(const Key('add_receipt_price_field')),
            '25.00',
          );

          final saveButton = find.byKey(const Key('add_receipt_save_button'));
          await tester.ensureVisible(saveButton);
          await tester.tap(saveButton);
          await tester.pumpAndSettle();

          expect(
            await fakeNotificationService.getScheduledReminders(),
            isEmpty,
          );

          await db.close();
          await tester.pump(const Duration(milliseconds: 50));
        },
      );
    });
  });
}
