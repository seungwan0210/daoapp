// lib/data/repositories/grip_baseline_repository_impl.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:daoapp/data/models/grip_baseline_model.dart';
import 'package:daoapp/data/repositories/grip_baseline_repository.dart';

class GripBaselineRepositoryImpl implements GripBaselineRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  GripBaselineRepositoryImpl({
    required this.auth,
    required this.firestore,
    required this.storage,
  });

  // -----------------------------
  // Path helpers
  // -----------------------------

  String _uidOrThrow() {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw Exception('로그인 정보가 없습니다.');
    return uid;
  }

  /// Firestore: users/{uid}/grip/baseline
  DocumentReference<Map<String, dynamic>> _baselineDocRef(String uid) {
    return firestore.collection('users').doc(uid).collection('grip').doc('baseline');
  }

  /// Storage: grip_baseline/{uid}/baseline.jpg (항상 1개로 덮어쓰기)
  Reference _baselineImageRef(String uid) {
    return storage.ref().child('grip_baseline').child(uid).child('baseline.jpg');
  }

  // -----------------------------
  // Repository APIs
  // -----------------------------

  @override
  Future<GripBaselineModel?> getBaseline() async {
    final uid = _uidOrThrow();
    final doc = await _baselineDocRef(uid).get();

    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;

    try {
      return GripBaselineModel.fromMap(data);
    } catch (e) {
      debugPrint('❌ GripBaselineModel parse error: $e');
      return null;
    }
  }

  @override
  Future<bool> hasBaseline() async {
    final uid = _uidOrThrow();
    final doc = await _baselineDocRef(uid).get();
    return doc.exists;
  }

  @override
  Future<GripBaselineModel> saveBaseline({
    required File imageFile,
    required GripBaselineModel model,
  }) async {
    final uid = _uidOrThrow();

    if (!imageFile.existsSync()) {
      throw Exception('업로드할 이미지 파일이 존재하지 않습니다.');
    }

    final ref = _baselineImageRef(uid);

    try {
      // 1) Storage 업로드 (같은 경로 덮어쓰기)
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putFile(imageFile, metadata);

      final downloadUrl = await ref.getDownloadURL();

      // 2) Firestore 저장 (업로드된 URL로 덮어쓰기 + createdAt 갱신)
      final saved = model.copyWith(
        imageUrl: downloadUrl,
        createdAt: DateTime.now(),
      );

      await _baselineDocRef(uid).set(saved.toMap(), SetOptions(merge: false));

      return saved;
    } catch (e) {
      debugPrint('❌ saveBaseline failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteBaseline() async {
    final uid = _uidOrThrow();

    // (1) Firestore 문서 삭제
    try {
      await _baselineDocRef(uid).delete();
    } catch (e) {
      debugPrint('⚠️ baseline doc delete failed (ignore): $e');
    }

    // (2) Storage 파일 삭제
    try {
      await _baselineImageRef(uid).delete();
    } catch (e) {
      debugPrint('⚠️ baseline image delete failed (ignore): $e');
    }
  }
}
