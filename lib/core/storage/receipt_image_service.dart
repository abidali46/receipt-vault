// lib/core/storage/receipt_image_service.dart
//
// Service abstraction and default implementation for photo selection,
// copying to app-owned persistent storage, and safe unreferenced file deletion.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:receipt_vault/features/receipts/domain/repositories/receipts_repository.dart';

/// Contract for selecting, persisting, and managing local receipt images.
abstract class ReceiptImageService {
  /// Picks an image from the camera or photo gallery.
  Future<XFile?> pickImage({required ImageSource source});

  /// Copies an image file to the app-owned persistent directory and returns its local path.
  Future<String> copyToPersistentStorage(String sourcePath);

  /// Deletes a file only if it is not referenced by any saved receipt in storage.
  Future<void> deleteImageIfUnreferenced(
    String path, {
    ReceiptsRepository? repository,
  });

  /// Checks if a local image file exists on disk.
  bool fileExists(String path);
}

/// Default implementation of [ReceiptImageService] using [ImagePicker]
/// and [getApplicationDocumentsDirectory].
class DefaultReceiptImageService implements ReceiptImageService {
  const DefaultReceiptImageService({
    this.picker,
    this.documentsDirectoryProvider,
  });

  final ImagePicker? picker;
  final Future<Directory> Function()? documentsDirectoryProvider;

  ImagePicker get _effectivePicker => picker ?? ImagePicker();

  @override
  Future<XFile?> pickImage({required ImageSource source}) async {
    return _effectivePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2048,
      maxHeight: 2048,
    );
  }

  @override
  Future<String> copyToPersistentStorage(String sourcePath) async {
    final provider = documentsDirectoryProvider;
    final Directory baseDir = provider != null
        ? await provider()
        : await getApplicationDocumentsDirectory();

    final imagesDir = Directory(p.join(baseDir.path, 'receipt_images'));
    if (!imagesDir.existsSync()) {
      await imagesDir.create(recursive: true);
    }

    final ext = p.extension(sourcePath).toLowerCase();
    final safeExt = ext.isNotEmpty ? ext : '.jpg';
    final fileName = 'receipt_${DateTime.now().microsecondsSinceEpoch}$safeExt';
    final destinationPath = p.join(imagesDir.path, fileName);

    final sourceFile = File(sourcePath);
    await sourceFile.copy(destinationPath);
    return destinationPath;
  }

  @override
  Future<void> deleteImageIfUnreferenced(
    String path, {
    ReceiptsRepository? repository,
  }) async {
    try {
      // Safe cleanup requires a repository to verify that no other
      // saved receipt references this image path. If safe cleanup cannot
      // be guaranteed, leave the unused file rather than risk deleting an active image.
      if (repository == null) {
        return;
      }

      final all = await repository.getAllReceipts();
      final isReferenced = all.any((r) => r.imagePath == path);
      if (isReferenced) {
        // Do not delete files referenced by existing receipt records
        return;
      }
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore file deletion errors gracefully
    }
  }

  @override
  bool fileExists(String path) {
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }
}

/// Riverpod provider for [ReceiptImageService].
final receiptImageServiceProvider = Provider<ReceiptImageService>((ref) {
  return const DefaultReceiptImageService();
});
