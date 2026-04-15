// lib/my_page/services/image_upload_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class ImageUploadService {
  static final _picker = ImagePicker();

  /// ✅ 사진 한 장 선택 (속도 최적화 버전)
  static Future<XFile?> pickImage() => _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 60,      // 압축률을 살짝 더 높임 (60~70 권장)
    maxWidth: 1080,       // 가로 최대 1080px로 제한
    maxHeight: 1080,      // 세로 최대 1080px로 제한
  );

  /// ✅ 사진 여러 장 선택 (속도 및 용량 최적화 버전)
  static Future<List<XFile>> pickMultiImage() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 60,
        maxWidth: 1080,    // 다중 선택 시에도 동일하게 크기 제한
        maxHeight: 1080,
      );

      if (images.length > 7) {
        return images.sublist(0, 7);
      }
      return images;
    } catch (e) {
      debugPrint('사진 선택 실패: $e');
      return [];
    }
  }

  /// ✅ 단일 파일 업로드 (중복 방지를 위해 index 파라미터 추가)
  static Future<String?> upload(File file, String folderPath, {int? index}) async {
    if (!file.existsSync()) return null;

    // 밀리초 단위 시간 + 인덱스를 조합하여 파일명 중복을 원천 차단
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
      debugPrint('업로드 실패: ${e.code} - ${e.message}');
      return null;
    }
  }

  /// ✅ 다중 파일 업로드 (안정성을 위해 순차 업로드 방식으로 변경)
  static Future<List<String>> uploadMultiple(List<File> files, String folderPath) async {
    if (files.isEmpty) return [];

    final List<String> uploadedUrls = [];
    try {
      // Future.wait 대신 for 루프를 사용하여 순차적으로 업로드합니다.
      // 이는 App Check 토큰 과다 요청 에러를 방지하고 파일 꼬임을 막아줍니다.
      for (int i = 0; i < files.length; i++) {
        final url = await upload(files[i], folderPath, index: i);
        if (url != null) {
          uploadedUrls.add(url);
        }
      }
      return uploadedUrls;
    } catch (e) {
      debugPrint('다중 업로드 중 오류 발생: $e');
      return uploadedUrls; // 실패 전까지 성공한 리스트라도 반환
    }
  }

  /// ✅ 특정 URL의 파일 하나만 스토리지에서 삭제 (서버비 절감 핵심)
  /// 수정 화면에서 특정 사진을 X 눌러 지울 때 사용합니다.
  static Future<void> deleteByUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
      debugPrint('스토리지 파일 삭제 성공: $url');
    } catch (e) {
      // 파일이 이미 없거나 권한 문제일 경우
      debugPrint('스토리지 파일 삭제 실패(무시가능): $e');
    }
  }

  /// ✅ 리스트에 담긴 모든 URL의 파일들을 삭제
  /// 게시물을 삭제할 때 호출합니다.
  static Future<void> deleteMultiple(List<String> urls) async {
    if (urls.isEmpty) return;
    try {
      await Future.wait(urls.map((url) => deleteByUrl(url)));
    } catch (e) {
      debugPrint('다중 파일 삭제 중 오류: $e');
    }
  }

  /// ✅ 특정 폴더 안의 모든 파일 삭제 (기존 유지)
  static Future<void> deleteFolder(String folderPath) async {
    try {
      final listResult = await FirebaseStorage.instance.ref(folderPath).listAll();
      final deleteTasks = listResult.items.map((item) => item.delete());
      await Future.wait(deleteTasks);
    } catch (e) {
      debugPrint('폴더 삭제 실패: $e');
    }
  }
}