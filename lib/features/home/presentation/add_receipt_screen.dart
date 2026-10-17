// lib/features/home/presentation/add_receipt_screen.dart
//
// Add Receipt form UI for capturing product name, store name, category,
// purchase date, total amount, warranty duration, notes, and receipt photo placeholder.
// Connects to Drift SQLite persistence via ReceiptsRepository and Riverpod.

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receipt_vault/app/router/app_router.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/core/storage/receipt_image_service.dart';
import 'package:receipt_vault/features/receipts/domain/repositories/receipts_repository.dart';
import 'package:receipt_vault/features/receipts/domain/services/warranty_calculator.dart';
import 'package:receipt_vault/features/receipts/presentation/providers/receipts_providers.dart';

/// Form screen for capturing, validating, and persisting receipt and warranty details.
class AddReceiptScreen extends ConsumerStatefulWidget {
  const AddReceiptScreen({
    super.key,
    this.onSubmit,
    this.repository,
    this.initialDate,
    this.imageService,
    this.receiptToEdit,
    this.receiptId,
  });

  /// Optional receipt to edit. When supplied, form fields are pre-populated
  /// and saving updates the existing record instead of inserting a duplicate.
  final Receipt? receiptToEdit;

  /// Optional ID of an existing receipt to load and edit if [receiptToEdit] is null.
  final int? receiptId;

  /// Optional callback invoked with the validated form data when submitted.
  /// Useful for testing and inspection.
  final ValueChanged<Map<String, dynamic>>? onSubmit;

  /// Optional repository override. If not supplied, uses [receiptsRepositoryProvider].
  final ReceiptsRepository? repository;

  /// Optional initial purchase date (defaults to today).
  final DateTime? initialDate;

  /// Optional image service override for testing and custom storage handling.
  final ReceiptImageService? imageService;

  /// The standard categories supported by Receipt Vault.
  static const List<String> categories = [
    'Electronics',
    'Food',
    'Clothing',
    'Home',
    'Others',
  ];

  @override
  ConsumerState<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends ConsumerState<AddReceiptScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _productNameController;
  late final TextEditingController _storeNameController;
  late final TextEditingController _priceController;
  late final TextEditingController _notesController;
  late final TextEditingController _customWarrantyController;

  late DateTime _purchaseDate;
  late final DateTime _initialDateValue;
  String _selectedCategory = AddReceiptScreen.categories.first;
  int? _selectedWarrantyPreset;
  bool _isCustomWarranty = false;

  String? _selectedImagePath;
  bool _isProcessingImage = false;

  ReceiptImageService get _imageService =>
      widget.imageService ?? ref.read(receiptImageServiceProvider);

  bool _isSaving = false;
  bool _isSaved = false;

  bool _isLoadingInitial = false;
  Receipt? _loadedReceipt;
  bool _isNotFound = false;
  Object? _loadError;

  Receipt? get _activeReceiptToEdit => widget.receiptToEdit ?? _loadedReceipt;
  bool get _isEditing =>
      _activeReceiptToEdit != null || widget.receiptId != null;

  @override
  void initState() {
    super.initState();
    final r = widget.receiptToEdit;
    if (r != null) {
      _productNameController = TextEditingController(text: r.productName);
      _storeNameController = TextEditingController(text: r.storeName ?? '');
      _priceController = TextEditingController(
        text: r.totalAmount == r.totalAmount.roundToDouble()
            ? r.totalAmount.toInt().toString()
            : r.totalAmount.toStringAsFixed(2),
      );
      _notesController = TextEditingController(text: r.notes ?? '');
      _customWarrantyController = TextEditingController();
      _purchaseDate = r.purchaseDate;
      _initialDateValue = r.purchaseDate;
      _selectedCategory = r.category ?? AddReceiptScreen.categories.first;
      _selectedImagePath = r.imagePath;

      final days = r.warrantyDurationDays;
      if (days == null || days <= 0) {
        _selectedWarrantyPreset = null;
        _isCustomWarranty = false;
      } else if ([180, 365, 730, 1095].contains(days)) {
        _selectedWarrantyPreset = days;
        _isCustomWarranty = false;
      } else {
        _selectedWarrantyPreset = -1;
        _isCustomWarranty = true;
        _customWarrantyController.text = days.toString();
      }
    } else {
      _productNameController = TextEditingController();
      _storeNameController = TextEditingController();
      _priceController = TextEditingController();
      _notesController = TextEditingController();
      _customWarrantyController = TextEditingController();

      _initialDateValue = widget.initialDate ?? DateTime.now();
      _purchaseDate = _initialDateValue;

      if (widget.receiptId != null) {
        _isLoadingInitial = true;
        _isNotFound = false;
        _loadError = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadReceiptById(widget.receiptId!);
        });
      }
    }
  }

  Future<void> _loadReceiptById(int id) async {
    setState(() {
      _isLoadingInitial = true;
      _isNotFound = false;
      _loadError = null;
    });

    try {
      final ReceiptsRepository repository =
          widget.repository ?? ref.read(receiptsRepositoryProvider);
      final r = await repository.getReceiptById(id);
      if (!mounted) return;
      if (r != null) {
        setState(() {
          _loadedReceipt = r;
          _productNameController.text = r.productName;
          _storeNameController.text = r.storeName ?? '';
          _priceController.text = r.totalAmount == r.totalAmount.roundToDouble()
              ? r.totalAmount.toInt().toString()
              : r.totalAmount.toStringAsFixed(2);
          _notesController.text = r.notes ?? '';
          _purchaseDate = r.purchaseDate;
          _selectedCategory = r.category ?? AddReceiptScreen.categories.first;
          _selectedImagePath = r.imagePath;

          final days = r.warrantyDurationDays;
          if (days == null || days <= 0) {
            _selectedWarrantyPreset = null;
            _isCustomWarranty = false;
          } else if ([180, 365, 730, 1095].contains(days)) {
            _selectedWarrantyPreset = days;
            _isCustomWarranty = false;
          } else {
            _selectedWarrantyPreset = -1;
            _isCustomWarranty = true;
            _customWarrantyController.text = days.toString();
          }
          _isLoadingInitial = false;
          _isNotFound = false;
          _loadError = null;
        });
      } else {
        setState(() {
          _isLoadingInitial = false;
          _isNotFound = true;
          _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
          _isNotFound = false;
          _loadError = e;
        });
      }
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _storeNameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _customWarrantyController.dispose();
    super.dispose();
  }

  /// Whether the user has modified any form field from its initial state.
  bool get _isDirty {
    if (_isSaved) return false;
    // When editing by ID but record is loading, not found, or in error, form cannot be dirty.
    if (widget.receiptId != null && _activeReceiptToEdit == null) {
      return false;
    }
    final r = _activeReceiptToEdit;
    if (r != null) {
      final nameChanged = _productNameController.text.trim() != r.productName;
      final storeChanged =
          _storeNameController.text.trim() != (r.storeName ?? '');
      final priceChanged =
          double.tryParse(_priceController.text.trim().replaceAll(',', '')) !=
          r.totalAmount;
      final notesChanged = _notesController.text.trim() != (r.notes ?? '');
      final categoryChanged =
          _selectedCategory !=
          (r.category ?? AddReceiptScreen.categories.first);
      final dateChanged = !_isSameDay(_purchaseDate, r.purchaseDate);
      final warrantyChanged = _effectiveWarrantyDays != r.warrantyDurationDays;
      final imageChanged = _selectedImagePath != r.imagePath;

      return nameChanged ||
          storeChanged ||
          priceChanged ||
          notesChanged ||
          categoryChanged ||
          dateChanged ||
          warrantyChanged ||
          imageChanged;
    }

    return _selectedImagePath != null ||
        _productNameController.text.trim().isNotEmpty ||
        _storeNameController.text.trim().isNotEmpty ||
        _priceController.text.trim().isNotEmpty ||
        _notesController.text.trim().isNotEmpty ||
        _customWarrantyController.text.trim().isNotEmpty ||
        _selectedWarrantyPreset != null ||
        _selectedCategory != AddReceiptScreen.categories.first ||
        !_isSameDay(_purchaseDate, _initialDateValue);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// The effective warranty duration in days based on presets or custom input.
  int? get _effectiveWarrantyDays {
    if (_isCustomWarranty) {
      final parsed = int.tryParse(_customWarrantyController.text.trim());
      return (parsed != null && parsed >= 0) ? parsed : null;
    }
    return _selectedWarrantyPreset;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _pickPurchaseDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );

    if (picked != null) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppShapes.radiusMd),
          title: const Text('Discard changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them and leave?',
          ),
          actions: [
            TextButton(
              key: const Key('add_receipt_keep_editing_button'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep Editing'),
            ),
            TextButton(
              key: const Key('add_receipt_discard_confirm_button'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );

    if (result == true && _selectedImagePath != null) {
      final originalImage = _activeReceiptToEdit?.imagePath;
      if (_selectedImagePath != originalImage) {
        final repository =
            widget.repository ?? ref.read(receiptsRepositoryProvider);
        await _imageService.deleteImageIfUnreferenced(
          _selectedImagePath!,
          repository: repository,
        );
      }
    }

    return result ?? false;
  }

  Future<void> _handleBack(BuildContext context) async {
    if (_isSaving) return;

    if (!_isDirty) {
      _safePop(context);
      return;
    }

    final shouldDiscard = await _confirmDiscard(context);
    if (shouldDiscard && context.mounted) {
      _safePop(context);
    }
  }

  void _safePop(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    try {
      context.go(AppRoutes.receipts);
    } catch (_) {
      // Fallback if not inside a GoRouter (e.g. basic unit widget tests)
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSaving) return;

    if (_isEditing && _activeReceiptToEdit == null) {
      throw StateError('Cannot update receipt: receipt record is not loaded.');
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final productName = _productNameController.text.trim();
    final storeName = _storeNameController.text.trim();
    final effectiveStoreName = storeName.isEmpty ? null : storeName;
    final category = _selectedCategory;
    final totalAmount = double.parse(
      _priceController.text.trim().replaceAll(',', ''),
    );
    final effectiveWarrantyDays = _effectiveWarrantyDays;
    final notes = _notesController.text.trim();
    final effectiveNotes = notes.isEmpty ? null : notes;

    final formData = <String, dynamic>{
      'productName': productName,
      'storeName': effectiveStoreName,
      'category': category,
      'purchaseDate': _purchaseDate,
      'totalAmount': totalAmount,
      'warrantyDurationDays': effectiveWarrantyDays,
      'notes': effectiveNotes,
      'imagePath': _selectedImagePath,
    };

    setState(() {
      _isSaving = true;
    });

    try {
      final ReceiptsRepository repository =
          widget.repository ?? ref.read(receiptsRepositoryProvider);

      if (_isEditing) {
        final existing = _activeReceiptToEdit!;
        final receiptId = existing.id;
        final createdAt = existing.createdAt;

        final updated = Receipt(
          id: receiptId,
          productName: productName,
          storeName: effectiveStoreName,
          category: category,
          purchaseDate: _purchaseDate,
          totalAmount: totalAmount,
          warrantyDurationDays: effectiveWarrantyDays,
          notes: effectiveNotes,
          imagePath: _selectedImagePath,
          createdAt: createdAt,
        );

        final success = await repository.updateReceipt(updated);
        if (!success) {
          throw Exception('Failed to update receipt record.');
        }

        formData['id'] = receiptId;

        if (!mounted) return;

        _isSaved = true;
        _isSaving = false;

        widget.onSubmit?.call(formData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt updated successfully!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        _safePop(context);
        return;
      }

      final companion = ReceiptsCompanion.insert(
        productName: productName,
        storeName: effectiveStoreName != null
            ? Value(effectiveStoreName)
            : const Value.absent(),
        category: Value(category),
        purchaseDate: _purchaseDate,
        totalAmount: totalAmount,
        warrantyDurationDays: effectiveWarrantyDays != null
            ? Value(effectiveWarrantyDays)
            : const Value.absent(),
        notes: effectiveNotes != null
            ? Value(effectiveNotes)
            : const Value.absent(),
        imagePath: _selectedImagePath != null
            ? Value(_selectedImagePath)
            : const Value.absent(),
      );

      final insertedId = await repository.insertReceipt(companion);
      formData['id'] = insertedId;

      if (!mounted) return;

      _isSaved = true;
      _isSaving = false;

      widget.onSubmit?.call(formData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt saved successfully!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );

      _safePop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save receipt: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Widget bodyContent;
    if (_isLoadingInitial) {
      bodyContent = _buildLoadingState();
    } else if (_loadError != null) {
      bodyContent = _buildErrorState(context, _loadError!);
    } else if (widget.receiptId != null &&
        (_isNotFound || _activeReceiptToEdit == null)) {
      bodyContent = _buildNotFoundState(context);
    } else {
      bodyContent = SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo Selection and Preview Section
                    _buildPhotoSection(isDark, colorScheme, theme),
                    const SizedBox(height: 20),

                    // Form Details Card
                    _buildFormCard(isDark, colorScheme, theme),
                    const SizedBox(height: 24),

                    // Save Receipt Button
                    _buildSaveButton(colorScheme),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_isSaving && !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isSaving) return;
        final shouldDiscard = await _confirmDiscard(context);
        if (shouldDiscard && context.mounted) {
          _safePop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Receipt' : 'Add Receipt'),
          leading: BackButton(
            key: const Key('add_receipt_back_button'),
            onPressed: () => _handleBack(context),
          ),
        ),
        body: bodyContent,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        key: Key('add_receipt_loading_indicator'),
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              key: const Key('add_receipt_not_found_icon'),
              size: 64,
              color: isDark
                  ? AppColors.textDisabledDark
                  : AppColors.textDisabledLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Receipt Not Found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This receipt does not exist or may have been deleted.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('add_receipt_not_found_back_button'),
              onPressed: () => _safePop(context),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to Receipts'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimary,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppShapes.radiusFull,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              key: const Key('add_receipt_error_icon'),
              size: 56,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load receipt',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  key: const Key('add_receipt_error_back_button'),
                  onPressed: () => _safePop(context),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back to Receipts'),
                ),
                if (widget.receiptId != null)
                  FilledButton.icon(
                    key: const Key('add_receipt_error_retry_button'),
                    onPressed: () => _loadReceiptById(widget.receiptId!),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoSourceSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Attach Receipt Photo',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  key: const Key('add_receipt_photo_source_camera'),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(
                        isDark ? 50 : 25,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: colorScheme.primaryContainer,
                    ),
                  ),
                  title: const Text('Take Photo'),
                  subtitle: const Text('Capture receipt using device camera'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  key: const Key('add_receipt_photo_source_gallery'),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(
                        isDark ? 50 : 25,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: colorScheme.primaryContainer,
                    ),
                  ),
                  title: const Text('Choose from Gallery'),
                  subtitle: const Text(
                    'Select receipt image from photo library',
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isSaving || _isProcessingImage) return;

    setState(() {
      _isProcessingImage = true;
    });

    try {
      final picked = await _imageService.pickImage(source: source);

      if (picked == null) {
        // User cancelled photo selection gracefully
        if (mounted) {
          setState(() {
            _isProcessingImage = false;
          });
        }
        return;
      }

      // Copy into app-owned persistent directory
      final persistentPath = await _imageService.copyToPersistentStorage(
        picked.path,
      );

      // Clean up previous uncommitted image if present
      final previousPath = _selectedImagePath;
      if (previousPath != null && previousPath != persistentPath) {
        final repository =
            widget.repository ?? ref.read(receiptsRepositoryProvider);
        await _imageService.deleteImageIfUnreferenced(
          previousPath,
          repository: repository,
        );
      }

      if (mounted) {
        setState(() {
          _selectedImagePath = persistentPath;
          _isProcessingImage = false;
        });
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingImage = false;
      });
      final message = _resolvePlatformErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to attach photo: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String _resolvePlatformErrorMessage(PlatformException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    if (code.contains('camera_access_denied') ||
        code.contains('photo_access_denied') ||
        code.contains('permission') ||
        message.contains('permission') ||
        message.contains('access denied')) {
      return 'Camera or photo library permission was denied. Please allow access in Settings.';
    }
    if (code.contains('camera_not_available') ||
        code.contains('unsupported') ||
        message.contains('not supported') ||
        message.contains('no camera')) {
      return 'Camera or photo selection is not supported on this device.';
    }
    return 'Could not access photo: ${e.message ?? e.code}';
  }

  Future<void> _handleRemovePhoto() async {
    if (_selectedImagePath == null || _isSaving || _isProcessingImage) return;
    final pathToRemove = _selectedImagePath!;
    setState(() {
      _selectedImagePath = null;
    });

    final repository =
        widget.repository ?? ref.read(receiptsRepositoryProvider);
    await _imageService.deleteImageIfUnreferenced(
      pathToRemove,
      repository: repository,
    );
  }

  Widget _buildPhotoSection(
    bool isDark,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    if (_selectedImagePath == null) {
      return _buildPhotoUploadPlaceholder(isDark, colorScheme);
    }
    return _buildPhotoPreview(isDark, colorScheme, theme);
  }

  Widget _buildPhotoUploadPlaceholder(bool isDark, ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('add_receipt_photo_button'),
        borderRadius: AppShapes.radiusMd,
        onTap: _isSaving || _isProcessingImage
            ? null
            : () => _showPhotoSourceSheet(context),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: isDark ? AppColors.borderDark : const Color(0xFFC3C6D7),
            strokeWidth: 1.5,
            dashLength: 6,
            gapLength: 4,
            borderRadius: 12,
          ),
          child: Container(
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: AppShapes.radiusMd,
            ),
            child: _isProcessingImage
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceVariantDark
                              : const Color(0xFFEDEEEF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF505F76),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Add Photo',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to scan or upload a receipt',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(
    bool isDark,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final fileExists = _imageService.fileExists(_selectedImagePath!);
    final file = File(_selectedImagePath!);

    return Container(
      key: const Key('add_receipt_photo_preview_container'),
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: AppShapes.radiusMd,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image or Safe Missing Image Fallback
          if (fileExists)
            Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) =>
                  _buildMissingImageFallback(isDark, colorScheme, theme),
            )
          else
            _buildMissingImageFallback(isDark, colorScheme, theme),

          // Loading overlay during replacement
          if (_isProcessingImage)
            Container(
              color: Colors.black45,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),

          // Bottom action overlay bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black.withAlpha(170)),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Photo attached',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('add_receipt_replace_photo_button'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: _isSaving || _isProcessingImage
                        ? null
                        : () => _showPhotoSourceSheet(context),
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Replace'),
                  ),
                  TextButton.icon(
                    key: const Key('add_receipt_remove_photo_button'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFFB4AB),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: _isSaving || _isProcessingImage
                        ? null
                        : _handleRemovePhoto,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingImageFallback(
    bool isDark,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      key: const Key('add_receipt_photo_missing_fallback'),
      color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, size: 40, color: colorScheme.error),
          const SizedBox(height: 8),
          Text(
            'Image file not found or could not be loaded',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isDark, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: AppShapes.radiusMd,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name (required)
          _buildFieldLabel('PRODUCT NAME', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('add_receipt_product_name_field'),
            controller: _productNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'e.g. MacBook Pro M3'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a product name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Store Name (optional)
          _buildFieldLabel('STORE NAME'),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('add_receipt_store_name_field'),
            controller: _storeNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'e.g. Apple Store'),
          ),
          const SizedBox(height: 16),

          // Category (Choice Chips)
          _buildFieldLabel('CATEGORY'),
          const SizedBox(height: 8),
          _buildCategorySelector(isDark, colorScheme, theme),
          const SizedBox(height: 16),

          // Total Amount / Price (required, non-negative)
          _buildFieldLabel('TOTAL AMOUNT', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('add_receipt_price_field'),
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              hintText: '0.00',
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 14, right: 8),
                child: Center(
                  widthFactor: 0.0,
                  child: Text(
                    r'$',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the total amount';
              }
              final sanitized = value.trim().replaceAll(',', '');
              final parsed = double.tryParse(sanitized);
              if (parsed == null || parsed < 0) {
                return 'Please enter a valid non-negative amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Purchase Date (required)
          _buildFieldLabel('PURCHASE DATE', isRequired: true),
          const SizedBox(height: 6),
          _buildDatePickerField(theme),
          const SizedBox(height: 16),

          // Warranty Duration (optional)
          _buildFieldLabel('WARRANTY DURATION'),
          const SizedBox(height: 6),
          _buildWarrantyDropdown(),

          if (_isCustomWarranty) ...[
            const SizedBox(height: 12),
            _buildFieldLabel('CUSTOM DURATION (DAYS)', isRequired: true),
            const SizedBox(height: 6),
            TextFormField(
              key: const Key('add_receipt_custom_warranty_field'),
              controller: _customWarrantyController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: 'e.g. 90'),
              validator: (value) {
                if (_isCustomWarranty) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter warranty duration in days';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Please enter a valid non-negative number of days';
                  }
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),

          // Notes (optional)
          _buildFieldLabel('NOTES'),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('add_receipt_notes_field'),
            controller: _notesController,
            minLines: 3,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText:
                  'Add any extra details, serial number, or return policy...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategorySelector(
    bool isDark,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AddReceiptScreen.categories.map((cat) {
        final isSelected = _selectedCategory == cat;
        final icon = WarrantyCalculator.iconForCategory(cat);

        return ChoiceChip(
          key: Key('add_receipt_category_$cat'),
          avatar: Icon(
            icon,
            size: 16,
            color: isSelected
                ? colorScheme.onPrimary
                : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
          ),
          label: Text(cat),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedCategory = cat;
              });
            }
          },
          selectedColor: colorScheme.primaryContainer,
          backgroundColor: isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceLight,
          labelStyle: TextStyle(
            color: isSelected
                ? colorScheme.onPrimary
                : (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppShapes.radiusFull,
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildDatePickerField(ThemeData theme) {
    return InkWell(
      key: const Key('add_receipt_date_picker_button'),
      borderRadius: AppShapes.radiusMd,
      onTap: () => _pickPurchaseDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
        ),
        child: Text(
          _formatDate(_purchaseDate),
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildWarrantyDropdown() {
    return DropdownButtonFormField<int?>(
      key: const Key('add_receipt_warranty_dropdown'),
      initialValue: _selectedWarrantyPreset,
      decoration: const InputDecoration(hintText: 'Select duration'),
      items: const [
        DropdownMenuItem<int?>(value: null, child: Text('No warranty')),
        DropdownMenuItem<int?>(value: 180, child: Text('6 months')),
        DropdownMenuItem<int?>(value: 365, child: Text('12 months (1 year)')),
        DropdownMenuItem<int?>(value: 730, child: Text('24 months (2 years)')),
        DropdownMenuItem<int?>(value: 1095, child: Text('36 months (3 years)')),
        DropdownMenuItem<int?>(value: -1, child: Text('Custom duration...')),
      ],
      onChanged: (val) {
        setState(() {
          _selectedWarrantyPreset = val;
          _isCustomWarranty = val == -1;
        });
      },
    );
  }

  Widget _buildSaveButton(ColorScheme colorScheme) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        key: const Key('add_receipt_save_button'),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimary,
          shape: const RoundedRectangleBorder(
            borderRadius: AppShapes.radiusFull,
          ),
          elevation: 1,
        ),
        onPressed: _isSaving ? null : _handleSubmit,
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isEditing ? 'Save Changes' : 'Save Receipt',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Custom painter for the dashed outline around the receipt photo placeholder.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashLength = 6.0,
    this.gapLength = 4.0,
    this.borderRadius = 12.0,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashLength < metric.length)
            ? dashLength
            : metric.length - distance;
        canvas.drawPath(metric.extractPath(distance, distance + length), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}
