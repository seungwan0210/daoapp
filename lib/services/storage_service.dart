// lib/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';  // ← 이거 추가!!

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 파일 업로드 (이미지 등)
  Future<String> uploadFile(String filePath, String storagePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('파일이 존재하지 않습니다.');
    }

    final fileName = path.basename(file.path);
    final destination = '$storagePath/$fileName';

    try {
      final ref = _storage.ref(destination);
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      throw Exception('업로드 실패: ${e.message}');
    }
  }

  /// 파일 삭제 (필요하면 나중에)
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('삭제 실패: $e');  // 이제 정상 동작!!
    }
  }
}