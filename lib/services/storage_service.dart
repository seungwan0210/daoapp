// lib/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path; // ← 이거 꼭 추가!!
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 일반 파일 업로드 (게시글 등에 쓰는 거)
  Future<String> uploadFile(String filePath, String storagePath) async {
    final file = File(filePath);
    if (!file.existsSync()) throw Exception('파일이 존재하지 않습니다.');

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
    final destination = '$storagePath/$fileName';

    final ref = _storage.ref(destination);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // 마이로그 전용 사진 업로드 ← 이거 추가!!
  Future<String?> uploadMyLogImage(File? image) async {
    if (image == null || !image.existsSync()) return null;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('로그인되지 않음');

    // 파일명: userId_시간.jpg
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage
        .ref()
        .child('my_log_images')
        .child(userId)
        .child(fileName);

    try {
      final uploadTask = await ref.putFile(image);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('마이로그 사진 업로드 실패: ${e.message}');
      return null;
    }
  }

  // 파일 삭제
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('삭제 실패: $e');
    }
  }
}