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

  /// 세션 시작
  Future<void> startSession({
    required String userId,
    required TrainingDrillDefinition drill,
    required DaoTrainingTier tierAtThatTime,
  }) async {
    try {
      state = state.copyWith(isSaving: true, errorMessage: null);

      final now = DateTime.now();

      // 🔹 기본 계획값: extraConfig 기반 + 안전한 기본값
      final extra = drill.extraConfig;

      // plannedRounds / rounds 우선 사용, 없으면 8라운드 기본
      int plannedRounds;
      final roundsFromExtra = extra?['plannedRounds'] ?? extra?['rounds'];
      if (roundsFromExtra is int && roundsFromExtra > 0) {
        plannedRounds = roundsFromExtra;
      } else {
        plannedRounds = 8;
      }

      // dartsPerRound 없으면 3다트 기본
      int plannedDartsPerRound;
      final dartsFromExtra = extra?['dartsPerRound'];
      if (dartsFromExtra is int && dartsFromExtra > 0) {
        plannedDartsPerRound = dartsFromExtra;
      } else {
        plannedDartsPerRound = 3;
      }

      final newSession = TrainingSessionModel(
        id: null,
        userId: userId,
        drillId: drill.id,
        drillTitle: drill.titleKo,
        tierAtThatTime: tierAtThatTime,
        startedAt: now,
        endedAt: now, // 실제 종료는 finishSession에서 덮어씀
        totalRounds: plannedRounds,
        totalAttempts: 0,
        successCount: 0,
        failCount: 0,
        extra: {
          'rounds': plannedRounds,
          'dartsPerRound': plannedDartsPerRound,
          'targetLabel': drill.targetLabel,
          'guideKo': drill.guideKo,
          'guideEn': drill.guideEn,
          'category': drill.category.name,
          'shortDescriptionKo': drill.shortDescriptionKo,
          'inputMode': drill.inputMode.name,
          if (drill.extraConfig != null) ...drill.extraConfig!,
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
  ///
  /// - hitCount 모드: `hitCount` / `totalDarts`로 명중률 계산
  /// - scoreOnly 모드: `totalScore` / `totalDarts`로 PPD, 3다트 평균 계산
  /// - cricketMarks 모드: `totalMarks` / `totalRounds`로 MPR 계산
  Future<void> finishSession({
    required TrainingDrillInputMode inputMode,
    required int totalRounds,
    required int totalDarts,
    int hitCount = 0,
    int totalMarks = 0,
    int totalScore = 0,
    Map<String, dynamic>? additionalExtra,
  }) async {
    final current = state.activeSession;
    if (current == null) return;

    try {
      state = state.copyWith(isSaving: true, errorMessage: null);

      final now = DateTime.now();

      final bool isHit = inputMode == TrainingDrillInputMode.hitCount;
      final bool isScore = inputMode == TrainingDrillInputMode.scoreOnly;
      final bool isCricket = inputMode == TrainingDrillInputMode.cricketMarks;

      final int successCount = isHit ? hitCount : 0;
      final int failCount =
      isHit ? (totalDarts - hitCount).clamp(0, totalDarts) : 0;

      final double hitRate =
      (isHit && totalDarts > 0) ? hitCount / totalDarts : 0.0;

      double? ppd;
      double? threeDartAvg;
      if (isScore && totalDarts > 0) {
        ppd = totalScore / totalDarts;
        threeDartAvg = ppd * 3;
      }

      double? mpr;
      if (isCricket && totalRounds > 0) {
        // 일반 크리켓 MPR = (총마크 / 라운드 수)
        mpr = totalMarks / totalRounds;
      }

      final updated = current.copyWith(
        endedAt: now,
        totalRounds: totalRounds,
        totalAttempts: totalDarts,
        successCount: successCount,
        failCount: failCount,
        extra: {
          ...?current.extra,
          if (additionalExtra != null) ...additionalExtra,
          'inputMode': inputMode.name,
          'totalMarks': totalMarks,
          'totalScore': totalScore,
          'hitRate': hitRate,
          if (ppd != null) 'ppd': ppd,
          if (threeDartAvg != null) 'threeDartAvg': threeDartAvg,
          if (mpr != null) 'mpr': mpr,
          'completedAt': now.toIso8601String(),
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
