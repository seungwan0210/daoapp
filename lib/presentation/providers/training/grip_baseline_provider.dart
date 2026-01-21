// lib/presentation/providers/training/grip_baseline_provider.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/data/models/grip_baseline_model.dart';
import 'package:daoapp/data/repositories/grip_baseline_repository.dart';

/// ------------------------------------------------------------
/// UI에서 쓰기 편한 상태 모델
/// ------------------------------------------------------------
class GripBaselineState {
  final bool isLoading;
  final GripBaselineModel? baseline;
  final String? errorMessage;

  const GripBaselineState({
    this.isLoading = false,
    this.baseline,
    this.errorMessage,
  });

  /// ✅ 기준 그립 존재 여부
  /// - GripBaselineModel.imageUrl은 non-null String이므로 ?. 불필요
  bool get hasBaseline => baseline != null && baseline!.imageUrl.isNotEmpty;

  GripBaselineState copyWith({
    bool? isLoading,
    GripBaselineModel? baseline,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GripBaselineState(
      isLoading: isLoading ?? this.isLoading,
      baseline: baseline ?? this.baseline,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// ------------------------------------------------------------
/// Provider
/// ------------------------------------------------------------
final gripBaselineProvider =
StateNotifierProvider<GripBaselineNotifier, GripBaselineState>((ref) {
  return GripBaselineNotifier(
    repo: sl<GripBaselineRepository>(),
  );
});

/// ------------------------------------------------------------
/// Notifier
/// ------------------------------------------------------------
class GripBaselineNotifier extends StateNotifier<GripBaselineState> {
  final GripBaselineRepository repo;

  GripBaselineNotifier({required this.repo}) : super(const GripBaselineState()) {
    fetchBaseline();
  }

  /// 기준 그립(1개) 불러오기
  Future<void> fetchBaseline() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final model = await repo.getBaseline();
      state = state.copyWith(isLoading: false, baseline: model);
    } catch (e) {
      debugPrint('❌ fetchBaseline error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '기준 그립을 불러오지 못했어요.\n$e',
      );
    }
  }

  /// 기준 그립 존재 여부
  Future<bool> hasBaseline() async {
    try {
      return await repo.hasBaseline();
    } catch (e) {
      debugPrint('❌ hasBaseline error: $e');
      return false;
    }
  }

  /// 기준 그립 저장/업데이트
  ///
  /// - [imageFile] : 저장할 기준 이미지(로컬 파일)
  /// - [model]     : Firestore에 저장할 분석/메타 데이터 포함 모델
  ///
  /// Repository에서:
  /// - (기존 이미지 삭제 또는 overwrite)
  /// - Storage 업로드
  /// - Firestore baseline 문서 덮어쓰기
  Future<bool> saveBaseline({
    required File imageFile,
    required GripBaselineModel model,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final saved = await repo.saveBaseline(
        imageFile: imageFile,
        model: model,
      );

      state = state.copyWith(isLoading: false, baseline: saved);
      return true;
    } catch (e) {
      debugPrint('❌ saveBaseline error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '기준 그립 저장에 실패했어요.\n$e',
      );
      return false;
    }
  }

  /// 기준 그립 삭제
  Future<bool> deleteBaseline() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await repo.deleteBaseline();
      state = state.copyWith(isLoading: false, baseline: null);
      return true;
    } catch (e) {
      debugPrint('❌ deleteBaseline error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '기준 그립 삭제에 실패했어요.\n$e',
      );
      return false;
    }
  }

  /// 에러 메시지 초기화 (SnackBar/Dialog 닫을 때)
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
