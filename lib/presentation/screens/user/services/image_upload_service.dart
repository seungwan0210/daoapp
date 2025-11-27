// lib/user/services/image_upload_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class ImageUploadService {
  static final _picker = ImagePicker();

  static Future<XFile?> pickImage() => _picker.pickImage(source: ImageSource.gallery);

  /// 폴더 경로 + 파일명 자동 생성해서 업로드
  static Future<String?> upload(File file, String folderPath) async {
    if (!file.existsSync()) return null;

    // 파일명: avatar_1234567890.jpg (중복 방지)
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';

    // 폴더 경로 끝에 / 없으면 추가 + 파일명 붙이기
    final fullPath = folderPath.endsWith('/') ? '$folderPath$fileName' : '$folderPath/$fileName';

    final ref = FirebaseStorage.instance.ref().child(fullPath);

    try {
      await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'), // 이거 추가하면 더 안정적
      );
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('ImageUploadService 업로드 실패: ${e.code} - ${e.message}');
      return null;
    }
  }

  /// 폴더 안에 있는 모든 파일 삭제 (기존 사진 지울 때 사용)
  static Future<void> delete(String folderPath) async {
    try {
      final listResult = await FirebaseStorage.instance.ref(folderPath).listAll();
      for (var item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      debugPrint('ImageUploadService 삭제 실패: $e');
    }
  }
}