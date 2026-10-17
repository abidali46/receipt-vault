// test/features/settings/receipt_export_service_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/features/settings/domain/services/receipt_export_service.dart';

void main() {
  group('ReceiptExportService Unit Tests', () {
    final fixedNow = DateTime(2026, 10, 16, 15, 30, 45);

    Receipt createSampleReceipt({
      int id = 1,
      String productName = 'Sony Headphones',
      String? storeName = 'Best Buy',
      String? category = 'Electronics',
      DateTime? purchaseDate,
      double totalAmount = 299.99,
      int? warrantyDurationDays = 365,
      String? notes = 'Bought with extended store warranty',
      String? imagePath = '/private/app/data/images/receipt_1.jpg',
      DateTime? createdAt,
    }) {
      return Receipt(
        id: id,
        productName: productName,
        storeName: storeName,
        category: category,
        purchaseDate: purchaseDate ?? DateTime(2026, 1, 15),
        totalAmount: totalAmount,
        warrantyDurationDays: warrantyDurationDays,
        notes: notes,
        imagePath: imagePath,
        createdAt: createdAt ?? DateTime(2026, 1, 15, 10, 0, 0),
      );
    }

    test('generateCsv outputs standard headers on first line', () {
      final csv = ReceiptExportService.generateCsv([], now: fixedNow);
      final lines = csv.split('\r\n');

      expect(
        lines.first,
        'ID,Product Name,Store,Category,Purchase Date,Total Amount,Warranty Duration (Days),Warranty Status,Notes,Has Photo,Created At',
      );
      expect(lines.length, 2); // header + empty trailing after CRLF
    });

    test('generateCsv formats fields and dates cleanly', () {
      final receipt = createSampleReceipt();
      final csv = ReceiptExportService.generateCsv([receipt], now: fixedNow);
      final lines = csv.split('\r\n');

      expect(lines.length, 3);
      final dataRow = lines[1];
      expect(
        dataRow,
        contains(
          '1,Sony Headphones,Best Buy,Electronics,2026-01-15,299.99,365,',
        ),
      );
      expect(dataRow, contains('Bought with extended store warranty'));
      expect(dataRow, contains('Yes')); // Has Photo
      expect(dataRow, contains('2026-01-15 10:00:00'));
    });

    test(
      'generateCsv strictly protects privacy by not exposing private image paths',
      () {
        final privatePath = 'C:\\Users\\Secret\\AppData\\Local\\receipt_99.png';
        final receiptWithPhoto = createSampleReceipt(imagePath: privatePath);
        final receiptWithoutPhoto = createSampleReceipt(
          id: 2,
          productName: 'Coffee',
          imagePath: null,
        );

        final csv = ReceiptExportService.generateCsv([
          receiptWithPhoto,
          receiptWithoutPhoto,
        ], now: fixedNow);

        // Private local file path must NEVER be leaked in exported data
        expect(csv.contains(privatePath), isFalse);
        expect(csv.contains('Secret'), isFalse);
        expect(csv.contains('AppData'), isFalse);

        final lines = csv.split('\r\n');
        expect(lines[1], contains(',Yes,'));
        expect(lines[2], contains(',No,'));
      },
    );

    test(
      'escapeCsvField correctly handles commas, quotes, newlines, and nulls',
      () {
        // Null and empty
        expect(ReceiptExportService.escapeCsvField(null), '');
        expect(ReceiptExportService.escapeCsvField(''), '');

        // Plain string
        expect(
          ReceiptExportService.escapeCsvField('Electronics'),
          'Electronics',
        );

        // String with comma
        expect(
          ReceiptExportService.escapeCsvField('Apples, Oranges, Bananas'),
          '"Apples, Oranges, Bananas"',
        );

        // String with double quotes
        expect(
          ReceiptExportService.escapeCsvField('Dell XPS 15" OLED'),
          '"Dell XPS 15"" OLED"',
        );

        // String with newline
        expect(
          ReceiptExportService.escapeCsvField('Line 1\nLine 2'),
          '"Line 1\nLine 2"',
        );

        // String with carriage return
        expect(
          ReceiptExportService.escapeCsvField('Line 1\rLine 2'),
          '"Line 1\rLine 2"',
        );

        // String with comma, quotes, and newlines combined
        expect(
          ReceiptExportService.escapeCsvField(
            'Note: "Hello, World!"\nSecond line',
          ),
          '"Note: ""Hello, World!""\nSecond line"',
        );
      },
    );

    test(
      'generateCsv properly escapes special characters in receipt fields',
      () {
        final receipt = createSampleReceipt(
          productName: 'MacBook Pro 16", M3 Max',
          storeName: 'Apple Store, Fifth Ave',
          notes: 'Serial #12345\nCare plan included: "AppleCare+"',
        );

        final csv = ReceiptExportService.generateCsv([receipt], now: fixedNow);

        expect(csv, contains('"MacBook Pro 16"", M3 Max"'));
        expect(csv, contains('"Apple Store, Fifth Ave"'));
        expect(
          csv,
          contains('"Serial #12345\nCare plan included: ""AppleCare+"""'),
        );
      },
    );

    test('defaultFileName formats current date and time deterministically', () {
      final fileName = ReceiptExportService.defaultFileName(now: fixedNow);
      expect(fileName, 'receipt_vault_export_20261016_153045.csv');
    });

    test(
      'resolveDirectory respects downloads and documents destinations',
      () async {
        final tempDownloads = await Directory.systemTemp.createTemp('dl_');
        final tempDocs = await Directory.systemTemp.createTemp('docs_');
        addTearDown(() async {
          if (await tempDownloads.exists()) {
            await tempDownloads.delete(recursive: true);
          }
          if (await tempDocs.exists()) {
            await tempDocs.delete(recursive: true);
          }
        });

        // Target downloads
        final resolvedDl = await ReceiptExportService.resolveDirectory(
          ExportDestination.downloads,
          customDownloadsProvider: () async => tempDownloads,
          customDocumentsProvider: () async => tempDocs,
        );
        expect(resolvedDl.path, tempDownloads.path);

        // Target documents
        final resolvedDocs = await ReceiptExportService.resolveDirectory(
          ExportDestination.documents,
          customDownloadsProvider: () async => tempDownloads,
          customDocumentsProvider: () async => tempDocs,
        );
        expect(resolvedDocs.path, tempDocs.path);

        // Target downloads when downloads provider returns null (fallback to docs)
        final fallbackDocs = await ReceiptExportService.resolveDirectory(
          ExportDestination.downloads,
          customDownloadsProvider: () async => null,
          customDocumentsProvider: () async => tempDocs,
        );
        expect(fallbackDocs.path, tempDocs.path);
      },
    );

    test(
      'saveToFile writes CSV content to disk and appends .csv if missing',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('export_test_');
        addTearDown(() async {
          if (await tempDir.exists()) await tempDir.delete(recursive: true);
        });

        const testContent = 'Header1,Header2\r\nVal1,Val2\r\n';

        // Without .csv extension in filename
        final file1 = await ReceiptExportService.saveToFile(
          csvContent: testContent,
          directory: tempDir,
          fileName: 'my_backup',
        );
        expect(file1.path.endsWith('.csv'), isTrue);
        expect(await file1.exists(), isTrue);
        expect(await file1.readAsString(), testContent);

        // With .csv already in filename
        final file2 = await ReceiptExportService.saveToFile(
          csvContent: testContent,
          directory: tempDir,
          fileName: 'my_second_backup.csv',
        );
        expect(file2.path.endsWith('my_second_backup.csv'), isTrue);
        expect(await file2.exists(), isTrue);
        expect(await file2.readAsString(), testContent);
      },
    );
  });
}
