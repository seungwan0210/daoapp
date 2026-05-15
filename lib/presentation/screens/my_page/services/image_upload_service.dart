// lib/presentation/screens/my_page/services/image_upload_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class ImageUploadService {
  static final _picker = ImagePicker();

  /// ✅ Pick a single image (Optimized for speed)
  static Future<XFile?> pickImage() => _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 60,      // Recommended compression: 60-70
    maxWidth: 1080,       // Max width 1080px
    maxHeight: 1080,      // Max height 1080px
  );

  /// ✅ Pick multiple images (Max 7)
  static Future<List<XFile>> pickMultiImage() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 60,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (images.length > 7) {
        return images.sublist(0, 7);
      }
      return images;
    } catch (e) {
      debugPrint('Image pick failed: $e');
      return [];
    }
  }

  /// ✅ Upload single file (with timestamp and index to prevent duplicates)
  static Future<String?> upload(File file, String folderPath, {int? index}) async {
    if (!file.existsSync()) return null;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final suffix = index != null ? '_$index' : '';
    final fileName = 'img_$timestamp$suffix${path.extension(file.path)}';

    final fullPath = folderPath.endsWith('/') ? '$folderPath$fileName' : '$folderPath/$fileName';
    final ref = FirebaseStorage.instance.ref().child(fullPath);

    try {
      await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('Upload failed: ${e.code} - ${e.message}');
      return null;
    }
  }

  /// ✅ Sequential multiple upload (To prevent App Check token issues)
  static Future<List<String>> uploadMultiple(List<File> files, String folderPath) async {
    if (files.isEmpty) return [];

    final List<String> uploadedUrls = [];
    try {
      for (int i = 0; i < files.length; i++) {
        final url = await upload(files[i], folderPath, index: i);
        if (url != null) {
          uploadedUrls.add(url);
        }
      }
      return uploadedUrls;
    } catch (e) {
      debugPrint('Multi-upload error: $e');
      return uploadedUrls;
    }
  }

  /// ✅ Delete single file by URL
  static Future<void> deleteByUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
      debugPrint('Storage file deleted: $url');
    } catch (e) {
      debugPrint('Storage deletion failed (can be ignored): $e');
    }
  }

  /// ✅ Delete multiple files by URLs
  static Future<void> deleteMultiple(List<String> urls) async {
    if (urls.isEmpty) return;
    try {
      await Future.wait(urls.map((url) => deleteByUrl(url)));
    } catch (e) {
      debugPrint('Multi-deletion error: $e');
    }
  }

  /// ✅ Delete all files in a folder
  static Future<void> deleteFolder(String folderPath) async {
    try {
      final listResult = await FirebaseStorage.instance.ref(folderPath).listAll();
      final deleteTasks = listResult.items.map((item) => item.delete());
      await Future.wait(deleteTasks);
    } catch (e) {
      debugPrint('Folder deletion failed: $e');
    }
  }
}