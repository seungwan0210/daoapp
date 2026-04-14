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
  bool get hasBaseline => baseline != null && baseline!.imageUrl.isNotEmpty;

  // ✅ [수정됨] null 할당이 가능하도록 clearBaseline 플래그 추가
  GripBaselineState copyWith({
    bool? isLoading,
    GripBaselineModel? baseline,
    String? errorMessage,
    bool clearError = false,
    bool clearBaseline = false, // ✨ 데이터를 강제로 지울 때 사용
  }) {
    return GripBaselineState(
      isLoading: isLoading ?? this.isLoading,
      // clearBaseline이 true면 null, 아니면 (새 값이 있으면 새 값, 없으면 기존 값)
      baseline: clearBaseline ? null : (baseline ?? this.baseline),
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

  GripBaselineNotifier({required this.repo})
      : super(const GripBaselineState()) {
    fetchBaseline();
  }

  /// 기준 그립(1개) 불러오기
  Future<void> fetchBaseline() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final model = await repo.getBaseline();

      // 모델이 null이면 clearBaseline: true로 확실하게 비워줌
      if (model == null) {
        state = state.copyWith(isLoading: false, clearBaseline: true);
      } else {
        state = state.copyWith(isLoading: false, baseline: model);
      }
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

      // ✅ [핵심 수정] clearBaseline: true를 사용하여 상태를 null로 만듦
      state = state.copyWith(isLoading: false, clearBaseline: true);

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

  /// 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}