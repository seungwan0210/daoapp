// lib/data/repositories/grip_baseline_repository.dart
import 'dart:io';

import 'package:daoapp/data/models/grip_baseline_model.dart';

/// ✅ 그립 연구소 - 기준 그립(1인 1개) 관리 Repository
///
/// Firestore:
/// users/{uid}/grip/baseline  (문서 1개)
///
/// Storage:
/// grip_baseline/{uid}/baseline.jpg  (파일 1개, 덮어쓰기)
abstract class GripBaselineRepository {
  /// 기준 그립 불러오기 (없으면 null)
  Future<GripBaselineModel?> getBaseline();

  /// 기준 그립 존재 여부
  Future<bool> hasBaseline();

  /// 기준 그립 저장/업데이트
  /// - 기존 baseline이 있으면: Storage 이미지 삭제(or overwrite) + Firestore 덮어쓰기
  /// - file은 로컬 파일(촬영 결과 or 캡처)
  Future<GripBaselineModel> saveBaseline({
    required File imageFile,
    required GripBaselineModel model,
  });

  /// 기준 그립 삭제
  /// - Storage 파일 삭제
  /// - Firestore 문서 삭제
  Future<void> deleteBaseline();
}
