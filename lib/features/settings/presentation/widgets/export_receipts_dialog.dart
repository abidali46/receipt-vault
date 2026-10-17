// lib/features/settings/presentation/widgets/export_receipts_dialog.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/features/receipts/domain/repositories/receipts_repository.dart';
import 'package:receipt_vault/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:receipt_vault/features/settings/domain/services/receipt_export_service.dart';

/// Modal dialog that guides users through exporting their receipt database to a CSV file.
///
/// Provides options to:
/// - Choose between Downloads and Documents folder
/// - Edit or accept the generated timestamped filename
/// - Copy CSV content directly to clipboard
/// - Review the photo exclusion privacy disclaimer
/// - View clear progress and completion feedback
class ExportReceiptsDialog extends ConsumerStatefulWidget {
  const ExportReceiptsDialog({
    super.key,
    this.repository,
    this.customDownloadsProvider,
    this.customDocumentsProvider,
  });

  /// Optional repository override for testing.
  final ReceiptsRepository? repository;

  /// Optional custom provider for the downloads directory (useful in tests).
  final Future<Directory?> Function()? customDownloadsProvider;

  /// Optional custom provider for the documents directory (useful in tests).
  final Future<Directory> Function()? customDocumentsProvider;

  @override
  ConsumerState<ExportReceiptsDialog> createState() =>
      _ExportReceiptsDialogState();
}

class _ExportReceiptsDialogState extends ConsumerState<ExportReceiptsDialog> {
  late final TextEditingController _fileNameController;
  ExportDestination _selectedDestination = ExportDestination.downloads;

  bool _isLoadingReceipts = true;
  bool _isExporting = false;
  String? _errorMessage;
  File? _exportedFile;
  List<Receipt> _receipts = [];

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(
      text: ReceiptExportService.defaultFileName(),
    );
    _loadReceipts();
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _loadReceipts() async {
    try {
      final ReceiptsRepository repo =
          widget.repository ?? ref.read(receiptsRepositoryProvider);
      final receipts = await repo.getAllReceipts();
      if (mounted) {
        setState(() {
          _receipts = receipts;
          _isLoadingReceipts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load receipts: $e';
          _isLoadingReceipts = false;
        });
      }
    }
  }

  Future<void> _exportToFile() async {
    final fileName = _fileNameController.text.trim();
    if (fileName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid file name.';
      });
      return;
    }

    setState(() {
      _isExporting = true;
      _errorMessage = null;
    });

    try {
      final dir = await ReceiptExportService.resolveDirectory(
        _selectedDestination,
        customDownloadsProvider: widget.customDownloadsProvider,
        customDocumentsProvider: widget.customDocumentsProvider,
      );

      final csv = ReceiptExportService.generateCsv(_receipts);
      final file = await ReceiptExportService.saveToFile(
        csvContent: csv,
        directory: dir,
        fileName: fileName,
      );

      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportedFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _errorMessage = 'Failed to export file: $e';
        });
      }
    }
  }

  Future<void> _copyCsvToClipboard() async {
    final csv = ReceiptExportService.generateCsv(_receipts);
    await Clipboard.setData(ClipboardData(text: csv));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV data copied to clipboard!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _copyFilePathToClipboard(String path) async {
    await Clipboard.setData(ClipboardData(text: path));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File path copied to clipboard!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppShapes.radiusLg),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoadingReceipts
              ? _buildLoadingState(primaryTextColor, secondaryTextColor)
              : _exportedFile != null
              ? _buildSuccessState(primaryTextColor, secondaryTextColor)
              : _receipts.isEmpty
              ? _buildEmptyState(primaryTextColor, secondaryTextColor)
              : _buildExportForm(primaryTextColor, secondaryTextColor, isDark),
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color primaryTextColor, Color secondaryTextColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text(
          'Preparing Receipt Vault Data...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Reading receipts from local database',
          style: TextStyle(fontSize: 13, color: secondaryTextColor),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEmptyState(Color primaryTextColor, Color secondaryTextColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryContainer.withAlpha(20),
          ),
          child: const Icon(
            Icons.receipt_long_outlined,
            size: 28,
            color: AppColors.primaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Receipt Vault is Empty',
          key: const Key('export_empty_title'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'There are no receipts in your database to export. Add some receipts first.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: secondaryTextColor,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const Key('export_empty_close_button'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }

  Widget _buildExportForm(
    Color primaryTextColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer.withAlpha(isDark ? 40 : 20),
                ),
                child: const Icon(
                  Icons.file_download_outlined,
                  size: 22,
                  color: AppColors.primaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Receipts (CSV)',
                      key: const Key('export_dialog_title'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_receipts.length} ${_receipts.length == 1 ? 'receipt' : 'receipts'} ready for export',
                      key: const Key('export_dialog_subtitle'),
                      style: TextStyle(fontSize: 13, color: secondaryTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Photo disclaimer note box
          Container(
            key: const Key('export_dialog_disclaimer'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: AppShapes.radiusSm,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ReceiptExportService.photoExclusionDisclaimer,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Destination Selection
          Text(
            'Save Destination',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ExportDestination>(
            key: const Key('export_destination_segmented_button'),
            segments: const [
              ButtonSegment<ExportDestination>(
                value: ExportDestination.downloads,
                label: Text('Downloads'),
                icon: Icon(Icons.download_rounded, size: 18),
              ),
              ButtonSegment<ExportDestination>(
                value: ExportDestination.documents,
                label: Text('Documents'),
                icon: Icon(Icons.folder_outlined, size: 18),
              ),
            ],
            selected: {_selectedDestination},
            onSelectionChanged: (newSelection) {
              setState(() {
                _selectedDestination = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 18),

          // File Name Input
          Text(
            'File Name',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('export_filename_field'),
            controller: _fileNameController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.description_outlined, size: 20),
              hintText: 'Enter export file name',
              helperText: 'Standard CSV spreadsheet format',
              helperStyle: TextStyle(fontSize: 11, color: secondaryTextColor),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                borderRadius: AppShapes.radiusSm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 18,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                key: const Key('export_cancel_button'),
                onPressed: _isExporting
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              OutlinedButton.icon(
                key: const Key('export_copy_clipboard_button'),
                onPressed: _isExporting ? null : _copyCsvToClipboard,
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Copy CSV'),
              ),
              FilledButton.icon(
                key: const Key('export_save_file_button'),
                onPressed: _isExporting ? null : _exportToFile,
                icon: _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_alt_rounded, size: 18),
                label: Text(_isExporting ? 'Saving...' : 'Save File'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(Color primaryTextColor, Color secondaryTextColor) {
    final filePath = _exportedFile!.path;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withAlpha(30),
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 32,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Export Complete',
          key: const Key('export_success_title'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Successfully exported ${_receipts.length} ${_receipts.length == 1 ? 'receipt' : 'receipts'}.',
          style: TextStyle(fontSize: 14, color: secondaryTextColor),
        ),
        const SizedBox(height: 16),

        // File path box
        Container(
          key: const Key('export_success_path_box'),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF8FAFC),
            borderRadius: AppShapes.radiusSm,
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File Location:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                filePath,
                key: const Key('export_success_file_path'),
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              key: const Key('export_copy_path_button'),
              onPressed: () => _copyFilePathToClipboard(filePath),
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text('Copy Path'),
            ),
            OutlinedButton.icon(
              key: const Key('export_copy_csv_done_button'),
              onPressed: _copyCsvToClipboard,
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('Copy CSV'),
            ),
            FilledButton(
              key: const Key('export_done_button'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ],
    );
  }
}
