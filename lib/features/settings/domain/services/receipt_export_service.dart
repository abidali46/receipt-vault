// lib/features/settings/domain/services/receipt_export_service.dart

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/features/receipts/domain/services/warranty_calculator.dart';

/// Available target locations for exporting backup files.
enum ExportDestination {
  /// User's system Downloads folder (desktop / supported mobile).
  downloads('Downloads Folder'),

  /// App's private documents directory.
  documents('Documents Folder');

  const ExportDestination(this.displayName);

  /// Human-readable label for UI selection.
  final String displayName;
}

/// Service responsible for generating human-readable, RFC 4180 compliant CSV exports
/// of receipt metadata and writing them safely to user-selected device storage.
///
/// Disclaimers & Privacy Guarantees:
/// - CSV files contain only text metadata (product, store, category, dates, amount, warranty, notes).
/// - Attached receipt photos are stored locally on the device and are NOT included in the CSV.
/// - Private local file paths (e.g. /data/user/0/... or C:\Users\...) are NEVER exposed;
///   a privacy-safe boolean indicator ('Yes'/'No') is exported instead.
/// - All export actions are 100% offline, local, and initiated only by the user.
class ReceiptExportService {
  const ReceiptExportService._();

  /// Standard column headers included in the exported CSV.
  static const List<String> csvHeaders = [
    'ID',
    'Product Name',
    'Store',
    'Category',
    'Purchase Date',
    'Total Amount',
    'Warranty Duration (Days)',
    'Warranty Status',
    'Notes',
    'Has Photo',
    'Created At',
  ];

  /// Prominent user-facing disclaimer regarding photo attachments.
  static const String photoExclusionDisclaimer =
      'CSV exports contain receipt text metadata and warranty details. '
      'Attached photos remain securely stored on your local device and are not included in CSV files.';

  /// Generates an RFC 4180 compliant CSV string from a list of [Receipt] records.
  ///
  /// Escapes fields containing commas, double quotes, and line breaks properly.
  /// Uses CRLF (\r\n) line terminators as mandated by RFC 4180.
  static String generateCsv(List<Receipt> receipts, {DateTime? now}) {
    final buffer = StringBuffer();

    // 1. Header row
    buffer.write(csvHeaders.map(escapeCsvField).join(','));
    buffer.write('\r\n');

    // 2. Data rows
    for (final receipt in receipts) {
      final warrantyInfo = WarrantyCalculator.calculate(
        purchaseDate: receipt.purchaseDate,
        warrantyDurationDays: receipt.warrantyDurationDays,
        now: now,
      );

      final hasPhoto =
          (receipt.imagePath != null && receipt.imagePath!.trim().isNotEmpty)
          ? 'Yes'
          : 'No';

      final row = [
        receipt.id.toString(),
        receipt.productName,
        receipt.storeName ?? '',
        receipt.category ?? '',
        formatDate(receipt.purchaseDate),
        receipt.totalAmount.toStringAsFixed(2),
        receipt.warrantyDurationDays != null &&
                receipt.warrantyDurationDays! > 0
            ? receipt.warrantyDurationDays.toString()
            : '',
        warrantyInfo.statusLabel,
        receipt.notes ?? '',
        hasPhoto,
        formatDateTime(receipt.createdAt),
      ];

      buffer.write(row.map(escapeCsvField).join(','));
      buffer.write('\r\n');
    }

    return buffer.toString();
  }

  /// Escapes a single string according to RFC 4180 CSV specifications:
  /// - If the field contains a comma, double quote, newline (\n), or carriage return (\r),
  ///   the entire field is wrapped in double quotes.
  /// - Any existing double quotes inside the field are doubled (`""`).
  /// - Null or empty values return an empty string.
  static String escapeCsvField(String? value) {
    if (value == null || value.isEmpty) return '';

    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }

    return value;
  }

  /// Formats a [DateTime] into an ISO-8601 date string (`YYYY-MM-DD`).
  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Formats a [DateTime] into a standard timestamp string (`YYYY-MM-DD HH:mm:ss`).
  static String formatDateTime(DateTime dateTime) {
    final date = formatDate(dateTime);
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    final ss = dateTime.second.toString().padLeft(2, '0');
    return '$date $hh:$mm:$ss';
  }

  /// Generates a standardized, timestamped export filename.
  /// E.g. `receipt_vault_export_20261016_230400.csv`
  static String defaultFileName({DateTime? now}) {
    final time = now ?? DateTime.now();
    final y = time.year.toString().padLeft(4, '0');
    final m = time.month.toString().padLeft(2, '0');
    final d = time.day.toString().padLeft(2, '0');
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final ss = time.second.toString().padLeft(2, '0');
    return 'receipt_vault_export_$y$m${d}_$hh$mm$ss.csv';
  }

  /// Resolves the file system [Directory] for the chosen [ExportDestination].
  ///
  /// Falls back safely to the application documents directory if the Downloads
  /// folder is unavailable on the current platform or fails to resolve.
  static Future<Directory> resolveDirectory(
    ExportDestination destination, {
    Future<Directory?> Function()? customDownloadsProvider,
    Future<Directory> Function()? customDocumentsProvider,
  }) async {
    if (destination == ExportDestination.downloads) {
      try {
        final downloadsProvider =
            customDownloadsProvider ?? getDownloadsDirectory;
        final dir = await downloadsProvider();
        if (dir != null && await dir.exists()) {
          return dir;
        }
      } catch (_) {
        // Fall back gracefully to documents directory
      }
    }

    final documentsProvider =
        customDocumentsProvider ?? getApplicationDocumentsDirectory;
    return await documentsProvider();
  }

  /// Writes [csvContent] to a CSV file named [fileName] inside [directory].
  ///
  /// Automatically appends `.csv` if missing, ensures the directory exists,
  /// and flushes bytes to persistent storage.
  static Future<File> saveToFile({
    required String csvContent,
    required Directory directory,
    required String fileName,
  }) async {
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final trimmedName = fileName.trim();
    final safeName = trimmedName.toLowerCase().endsWith('.csv')
        ? trimmedName
        : '$trimmedName.csv';

    final filePath = p.join(directory.path, safeName);
    final file = File(filePath);
    return await file.writeAsString(csvContent, flush: true);
  }
}
