// test/features/settings/data_export_card_test.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/features/receipts/domain/entities/receipt_card_data.dart';
import 'package:receipt_vault/features/receipts/domain/repositories/receipts_repository.dart';
import 'package:receipt_vault/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:receipt_vault/features/settings/presentation/widgets/data_export_card.dart';
import 'package:receipt_vault/features/settings/presentation/widgets/export_receipts_dialog.dart';

class FakeReceiptsRepository implements ReceiptsRepository {
  FakeReceiptsRepository([List<Receipt>? initialReceipts])
    : _receipts = List.of(initialReceipts ?? []);

  final List<Receipt> _receipts;

  @override
  Future<List<Receipt>> getAllReceipts() async => _receipts;

  @override
  Stream<List<Receipt>> watchReceipts() => Stream.value(_receipts);

  @override
  Stream<List<ReceiptCardData>> watchReceiptCards({DateTime? now}) =>
      Stream.value(
        _receipts.map((r) => ReceiptCardData.fromReceipt(r, now: now)).toList(),
      );

  @override
  Stream<Receipt?> watchReceiptById(int id) =>
      Stream.value(_receipts.where((r) => r.id == id).firstOrNull);

  @override
  Future<Receipt?> getReceiptById(int id) async =>
      _receipts.where((r) => r.id == id).firstOrNull;

  @override
  Future<int> insertReceipt(ReceiptsCompanion receipt) async => 1;

  @override
  Future<bool> updateReceipt(Receipt receipt) async => true;

  @override
  Future<int> deleteReceipt(int id) async => 1;
}

Receipt _createSampleReceipt({
  int id = 1,
  String productName = 'MacBook Pro',
  String? storeName = 'Apple Store',
  String? category = 'Electronics',
  DateTime? purchaseDate,
  double totalAmount = 1999.00,
  int? warrantyDurationDays = 365,
  String? notes = 'Space Black, M3 Pro',
  String? imagePath = '/data/images/receipt_1.png',
  DateTime? createdAt,
}) {
  return Receipt(
    id: id,
    productName: productName,
    storeName: storeName,
    category: category,
    purchaseDate: purchaseDate ?? DateTime(2026, 2, 1),
    totalAmount: totalAmount,
    warrantyDurationDays: warrantyDurationDays,
    notes: notes,
    imagePath: imagePath,
    createdAt: createdAt ?? DateTime(2026, 2, 1, 12, 0, 0),
  );
}

Widget _buildTestWidget({
  required ReceiptsRepository repository,
  Future<Directory?> Function()? customDownloadsProvider,
  Future<Directory> Function()? customDocumentsProvider,
}) {
  return ProviderScope(
    overrides: [receiptsRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: DataExportCard(
            repository: repository,
            customDownloadsProvider: customDownloadsProvider,
            customDocumentsProvider: customDocumentsProvider,
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DataExportCard Widget Tests', () {
    testWidgets(
      'renders tile, title, subtitle, export button, and disclaimer',
      (tester) async {
        final repository = FakeReceiptsRepository();

        await tester.pumpWidget(_buildTestWidget(repository: repository));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('settings_export_tile')), findsOneWidget);
        expect(find.text('Export Receipts (CSV)'), findsOneWidget);
        expect(
          find.text('Save receipt records to a human-readable CSV file'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('settings_export_button')), findsOneWidget);
        expect(
          find.byKey(const Key('settings_export_disclaimer_note')),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'Attached photos remain securely stored on your local device',
            findRichText: true,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping tile shows empty state dialog when repository has 0 receipts',
      (tester) async {
        final repository = FakeReceiptsRepository([]);

        await tester.pumpWidget(_buildTestWidget(repository: repository));
        await tester.pumpAndSettle();

        // Tap export button
        await tester.tap(find.byKey(const Key('settings_export_button')));
        await tester.pumpAndSettle();

        expect(find.byType(ExportReceiptsDialog), findsOneWidget);
        expect(find.byKey(const Key('export_empty_title')), findsOneWidget);
        expect(find.text('Receipt Vault is Empty'), findsOneWidget);
        expect(
          find.text(
            'There are no receipts in your database to export. Add some receipts first.',
          ),
          findsOneWidget,
        );

        // Tap close button
        await tester.tap(find.byKey(const Key('export_empty_close_button')));
        await tester.pumpAndSettle();

        expect(find.byType(ExportReceiptsDialog), findsNothing);
      },
    );

    testWidgets(
      'shows export dialog with receipt count, destination, and disclaimer when receipts exist',
      (tester) async {
        final receipts = [
          _createSampleReceipt(id: 1, productName: 'Laptop'),
          _createSampleReceipt(id: 2, productName: 'Keyboard'),
        ];
        final repository = FakeReceiptsRepository(receipts);

        await tester.pumpWidget(_buildTestWidget(repository: repository));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('settings_export_tile')));
        await tester.pumpAndSettle();

        expect(find.byType(ExportReceiptsDialog), findsOneWidget);
        expect(find.byKey(const Key('export_dialog_title')), findsOneWidget);
        expect(find.text('2 receipts ready for export'), findsOneWidget);
        expect(
          find.byKey(const Key('export_dialog_disclaimer')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('export_destination_segmented_button')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('export_filename_field')), findsOneWidget);
        expect(
          find.byKey(const Key('export_copy_clipboard_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('export_save_file_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping Copy CSV copies content to clipboard and shows SnackBar',
      (tester) async {
        final receipts = [
          _createSampleReceipt(id: 1, productName: 'Coffee Maker'),
        ];
        final repository = FakeReceiptsRepository(receipts);

        await tester.pumpWidget(_buildTestWidget(repository: repository));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('settings_export_tile')));
        await tester.pumpAndSettle();

        // Intercept clipboard
        String? copiedString;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'Clipboard.setData') {
              copiedString = (methodCall.arguments as Map)['text'] as String?;
              return null;
            }
            return null;
          },
        );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          );
        });

        await tester.ensureVisible(
          find.byKey(const Key('export_copy_clipboard_button')),
        );
        await tester.tap(find.byKey(const Key('export_copy_clipboard_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(copiedString, isNotNull);
        expect(copiedString, contains('Coffee Maker'));
        expect(copiedString, contains('ID,Product Name,Store,Category'));
        expect(find.text('CSV data copied to clipboard!'), findsOneWidget);
      },
    );

    testWidgets(
      'saving file writes CSV and transitions to success state with copy actions',
      (tester) async {
        final tempDir = Directory.systemTemp.createTempSync('export_ui_test_');
        addTearDown(() {
          try {
            if (tempDir.existsSync()) {
              tempDir.deleteSync(recursive: true);
            }
          } catch (_) {
            // Ignore Windows file lock race during teardown
          }
        });

        final receipts = [
          _createSampleReceipt(
            id: 1,
            productName: 'Smart TV',
            totalAmount: 799.99,
          ),
        ];
        final repository = FakeReceiptsRepository(receipts);

        await tester.pumpWidget(
          _buildTestWidget(
            repository: repository,
            customDownloadsProvider: () async => tempDir,
            customDocumentsProvider: () async => tempDir,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('settings_export_tile')));
        await tester.pumpAndSettle();

        // Ensure button is visible in scroll view and tap
        await tester.ensureVisible(
          find.byKey(const Key('export_save_file_button')),
        );
        await tester.tap(find.byKey(const Key('export_save_file_button')));

        // Allow real dart:io disk I/O to execute in runAsync while pumping frames
        await tester.runAsync(() async {
          for (var i = 0; i < 40; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            await tester.pump(const Duration(milliseconds: 50));
            if (find
                .byKey(const Key('export_success_title'))
                .evaluate()
                .isNotEmpty) {
              break;
            }
          }
        });

        // Verify success state
        expect(find.byKey(const Key('export_success_title')), findsOneWidget);
        expect(find.text('Export Complete'), findsOneWidget);
        expect(find.text('Successfully exported 1 receipt.'), findsOneWidget);
        expect(
          find.byKey(const Key('export_success_file_path')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('export_copy_path_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('export_copy_csv_done_button')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('export_done_button')), findsOneWidget);

        // Verify written file
        final files = tempDir.listSync().whereType<File>().toList();
        expect(files.length, 1);
        final content = files.first.readAsStringSync();
        expect(content, contains('Smart TV'));
        expect(content, contains('799.99'));

        // Dismiss dialog
        await tester.tap(find.byKey(const Key('export_done_button')));
        await tester.pumpAndSettle();

        expect(find.byType(ExportReceiptsDialog), findsNothing);
      },
    );
  });
}
