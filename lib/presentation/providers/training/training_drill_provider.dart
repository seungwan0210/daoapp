// lib/presentation/providers/training/training_drill_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/data/repositories/training_repository.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/di/service_locator.dart';

class TrainingDrillState {
  final TrainingSessionModel? activeSession;
  final bool isSaving;
  final String? errorMessage;

  const TrainingDrillState({
    this.activeSession,
    this.isSaving = false,
    this.errorMessage,
  });

  TrainingDrillState copyWith({
    TrainingSessionModel? activeSession,
    bool? isSaving,
    String? errorMessage,
  }) {
    return TrainingDrillState(
      activeSession: activeSession ?? this.activeSession,
      isSaving: isSaving ?? this.isSaving,
      // errorMessage는 호출 시 전달된 값으로 교체(없으면 null)
      errorMessage: errorMessage,
    );
  }
}

class TrainingDrillNotifier extends StateNotifier<TrainingDrillState> {
  final TrainingRepository _repo;

  TrainingDrillNotifier({TrainingRepository? repo})
      : _repo = repo ?? sl<TrainingRepository>(),
        super(const TrainingDrillState());

  /// 드릴 세션 시작
  Future<void> startSession({
    required String userId,
    required TrainingDrillDefinition drill,
    required DaoTrainingTier tierAtThatTime,
  }) async {
    try {
      state = state.copyWith(isSaving: true, errorMessage: null);

      final now = DateTime.now();

      final newSession = TrainingSessionModel(
        id: null,
        userId: userId,
        drillId: drill.id,
        drillTitle: drill.titleKo,
        tierAtThatTime: tierAtThatTime,
        startedAt: now,
        endedAt: now, // 임시값 (실제 종료는 finishSession에서)
        totalRounds: drill.rounds,
        totalAttempts: 0,
        successCount: 0,
        failCount: 0,
        extra: {
          'rounds': drill.rounds,
          'dartsPerRound': drill.dartsPerRound,
          'targetLabel': drill.targetLabel,
          'guideKo': drill.guideKo,
          'guideEn': drill.guideEn,
          'category': drill.category.name,
          'shortDescriptionKo': drill.shortDescriptionKo,
        },
      );

      final String sessionId = await _repo.createSession(newSession);

      state = state.copyWith(
        isSaving: false,
        activeSession: newSession.copyWith(id: sessionId),
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '세션 시작 실패: $e',
      );
    }
  }

  /// 드릴 완료
  Future<void> finishSession({
    required int totalAttempts,
    required int successCount,
    required int failCount,
    Map<String, dynamic>? additionalExtra,
  }) async {
    final current = state.activeSession;
    if (current == null) return;

    try {
      state = state.copyWith(isSaving: true, errorMessage: null);

      final updated = current.copyWith(
        endedAt: DateTime.now(), // 여기서 진짜 종료 시간 기록
        totalAttempts: totalAttempts,
        successCount: successCount,
        failCount: failCount,
        extra: {
          ...?current.extra,
          if (additionalExtra != null) ...additionalExtra,
          'hitRate': totalAttempts > 0 ? successCount / totalAttempts : 0.0,
          'completedAt': DateTime.now().toIso8601String(),
        },
      );

      await _repo.updateSession(updated);

      state = state.copyWith(
        isSaving: false,
        activeSession: updated,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '세션 저장 실패: $e',
      );
    }
  }

  void clearSession() {
    state = const TrainingDrillState();
  }
}

final trainingDrillProvider =
StateNotifierProvider<TrainingDrillNotifier, TrainingDrillState>((ref) {
  return TrainingDrillNotifier();
});
