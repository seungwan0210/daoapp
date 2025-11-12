// lib/user/services/image_upload_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageUploadService {
  static final _picker = ImagePicker();

  static Future<XFile?> pickImage() => _picker.pickImage(source: ImageSource.gallery);

  static Future<String?> upload(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  static Future<void> delete(String path) async {
    try {
      await FirebaseStorage.instance.ref().child(path).delete();
    } catch (_) {}
  }
}