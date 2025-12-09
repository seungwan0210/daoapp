// lib/presentation/providers/training/training_drill_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/data/repositories/training_repository.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/di/service_locator.dart';

// ✅ Progress Repository import
import 'package:daoapp/data/repositories/training_progress_repository.dart';

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

  /// ✅ XP 계산용 내부 헬퍼
  ///
  /// - 모드/티어/성과(명중률·MPR·점수)에 따라 XP를 꽤 세밀하게 조정
  /// - 공통 정책:
  ///   - 드릴을 끝까지 할수록 XP 보너스
  ///   - 티어가 높을수록 "같은 기록"이라도 약간 더 많은 XP (고티어 유지 난이도 보정)
  ///   - 너무 못 쳐도 최소 XP는 보장 (노가다 허무 방지)
  int _calculateXpForSession({
    required TrainingDrillInputMode inputMode,
    required int totalRounds,
    required int totalDarts,
    required int hitCount,
    required int totalMarks,
    required int totalScore,
    required DaoTrainingTier tier,
    Map<String, dynamic>? baseExtra,
    Map<String, dynamic>? additionalExtra,
  }) {
    if (totalDarts <= 0 && totalRounds <= 0) {
      return 0;
    }

    // extra 합치기 (드릴 설정/모드/게임 타입 등)
    final mergedExtra = <String, dynamic>{
      ...?baseExtra,
      ...?additionalExtra,
    };

    final String? mode = mergedExtra['mode'] as String?;
    final String? gameType = mergedExtra['gameType'] as String?;
    final String? category = mergedExtra['category'] as String?;
    final bool finishedEarly = mergedExtra['finishedEarly'] == true;
    final int plannedTotal =
        (mergedExtra['totalPlannedDarts'] as num?)?.toInt() ?? totalDarts;

    // ----------------------------
    // 티어별 기본 XP / 가중치 설정
    // ----------------------------
    const baseXpByTier = {
      DaoTrainingTier.beginner: 12,
      DaoTrainingTier.learner: 11,
      DaoTrainingTier.competitor: 10,
      DaoTrainingTier.challenger: 10,
      DaoTrainingTier.elite: 9,
      DaoTrainingTier.pro: 9,
      DaoTrainingTier.master: 8,
    };

    const tierWeightByTier = {
      DaoTrainingTier.beginner: 0.95,
      DaoTrainingTier.learner: 1.0,
      DaoTrainingTier.competitor: 1.05,
      DaoTrainingTier.challenger: 1.08,
      DaoTrainingTier.elite: 1.1,
      DaoTrainingTier.pro: 1.12,
      DaoTrainingTier.master: 1.15,
    };

    // hitCount 모드에서 "이 정도 맞으면 잘한 것" 기준 (라운드형 세그먼트 연습)
    const hitRateTargetByTier = {
      DaoTrainingTier.beginner: 0.30,
      DaoTrainingTier.learner: 0.40,
      DaoTrainingTier.competitor: 0.50,
      DaoTrainingTier.challenger: 0.60,
      DaoTrainingTier.elite: 0.70,
      DaoTrainingTier.pro: 0.80,
      DaoTrainingTier.master: 0.85,
    };

    // 크리켓 MPR에서 티어별 "목표 MPR" 기준
    const mprTargetByTier = {
      DaoTrainingTier.beginner: 1.2,
      DaoTrainingTier.learner: 1.6,
      DaoTrainingTier.competitor: 2.0,
      DaoTrainingTier.challenger: 2.3,
      DaoTrainingTier.elite: 2.6,
      DaoTrainingTier.pro: 3.0,
      DaoTrainingTier.master: 3.5,
    };

    // Count-Up (8R / 1440 기준) 티어별 "잘했다" 기준 점수
    const countupTargetByTier = {
      DaoTrainingTier.beginner: 350,
      DaoTrainingTier.learner: 550,
      DaoTrainingTier.competitor: 650,
      DaoTrainingTier.challenger: 750,
      DaoTrainingTier.elite: 900,
      DaoTrainingTier.pro: 1000,
      DaoTrainingTier.master: 1100,
    };

    // 501 / 501_multi: 티어별 "1레그 평균 사용 다트 수" 목표
    const expDarts501ByTier = {
      DaoTrainingTier.beginner: 30,
      DaoTrainingTier.learner: 27,
      DaoTrainingTier.competitor: 24,
      DaoTrainingTier.challenger: 21,
      DaoTrainingTier.elite: 18,
      DaoTrainingTier.pro: 16,
      DaoTrainingTier.master: 14,
    };

    final int baseXpTier = baseXpByTier[tier] ?? 10;
    final double tierWeight = tierWeightByTier[tier] ?? 1.0;

    int baseXp = baseXpTier;
    double perfScore = 0.0; // 0~1.5 정도까지 사용

    // ----------------------------
    // 1) hitCount 기반 드릴 (명중률 위주)
    // ----------------------------
    if (inputMode == TrainingDrillInputMode.hitCount && totalDarts > 0) {
      final double successRate = hitCount / totalDarts;
      final double targetHit = hitRateTargetByTier[tier] ?? 0.5;

      if (targetHit > 0) {
        // 목표 명중률에 딱 맞으면 perfScore ~1.0
        // 목표보다 훨씬 잘 치면 1.3~1.4까지 보너스
        perfScore = (successRate / targetHit).clamp(0.15, 1.4);
      } else {
        perfScore = successRate.clamp(0.0, 1.0);
      }
    }

    // ----------------------------
    // 2) cricketMarks 기반 (MPR 중심)
    // ----------------------------
    else if (inputMode == TrainingDrillInputMode.cricketMarks &&
        totalRounds > 0) {
      final double mpr = totalMarks / totalRounds; // 일반적인 MPR
      final double targetMpr = mprTargetByTier[tier] ?? 2.0;

      if (targetMpr > 0) {
        perfScore = (mpr / targetMpr).clamp(0.2, 1.4);
      } else {
        perfScore = (mpr / 6.0).clamp(0.0, 1.2);
      }

      baseXp += 1; // 크리켓은 게임 영향도가 크니까 약간 +1
    }

    // ----------------------------
    // 3) scoreOnly 기반 (501 / Count-Up / 기타 점수)
    // ----------------------------
    else if (inputMode == TrainingDrillInputMode.scoreOnly) {
      // 3-1) 501 멀티 세트 모드
      if (gameType != null && gameType.startsWith('501_multi')) {
        final int totalDartsUsed =
            (mergedExtra['totalDarts'] as num?)?.toInt() ??
                totalDarts;
        final int totalSets =
            (mergedExtra['totalSets'] as num?)?.toInt() ?? 1;

        final double avgDartsPerLeg = totalSets > 0
            ? totalDartsUsed / totalSets
            : totalDartsUsed.toDouble();

        final int expectedDarts = expDarts501ByTier[tier] ?? 21;

        if (avgDartsPerLeg > 0) {
          final double ratio = expectedDarts / avgDartsPerLeg;
          perfScore = ratio.clamp(0.2, 1.4);
        } else {
          perfScore = 0.3;
        }

        baseXp += 3;
      }

      // 3-2) 단일 501
      else if (gameType != null && gameType.startsWith('501')) {
        final int dartsUsed = totalDarts.clamp(9, 40);
        final int expectedDarts = expDarts501ByTier[tier] ?? 21;
        final double ratio = expectedDarts / dartsUsed;
        perfScore = ratio.clamp(0.2, 1.4);
        baseXp += 2;
      }

      // 3-3) Count-Up 계열
      else if (gameType != null && gameType.startsWith('countup')) {
        final int maxScore =
            (mergedExtra['maxScore'] as num?)?.toInt() ?? 1440;
        final int score = totalScore.clamp(0, maxScore);
        final int tierTarget = countupTargetByTier[tier] ?? 700;

        if (maxScore > 0 && tierTarget > 0) {
          final double ratioToTier = score / tierTarget;
          final double ratioToMax = score / maxScore;
          perfScore =
              ((ratioToTier * 0.7) + (ratioToMax * 0.3)).clamp(0.2, 1.4);
        } else {
          perfScore =
              (totalScore / (maxScore > 0 ? maxScore : 1000)).clamp(0.0, 1.0);
        }

        baseXp += 1;
      }

      // 3-4) 기타 scoreOnly
      else {
        final int maxScore =
            (mergedExtra['maxScore'] as num?)?.toInt() ?? 1500;
        if (maxScore > 0) {
          perfScore = (totalScore / maxScore).clamp(0.1, 1.0);
        } else {
          perfScore = 0.3;
        }
      }
    }

    // ----------------------------
    // 카테고리 보정
    // ----------------------------
    if (category == 'finish') {
      baseXp += 3;
    } else if (category == 'doublePractice') {
      baseXp += 2;
    } else if (category == 'scoring') {
      baseXp += 1;
    } else if (category == 'boardMapping') {
      baseXp += 1;
    }

    // ----------------------------
    // 진행도/조기 종료 보정
    // ----------------------------
    final double completionRatio = plannedTotal > 0
        ? (totalDarts / plannedTotal).clamp(0.0, 1.2)
        : 1.0;

    double rawXp = (baseXp + perfScore * 35.0) * tierWeight;

    if (completionRatio < 0.4) {
      rawXp *= 0.4;
    } else if (completionRatio < 0.7) {
      rawXp *= 0.7;
    }

    if (finishedEarly && completionRatio < 0.9) {
      rawXp *= 0.85;
    }

    // 최소 5, 최대 120
    final int xp = rawXp.round().clamp(5, 120);
    return xp;
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
        mpr = totalMarks / totalRounds;
      }

      // ✅ 여기서 XP 계산
      final int xp = _calculateXpForSession(
        inputMode: inputMode,
        totalRounds: totalRounds,
        totalDarts: totalDarts,
        hitCount: hitCount,
        totalMarks: totalMarks,
        totalScore: totalScore,
        tier: current.tierAtThatTime,
        baseExtra: current.extra,
        additionalExtra: additionalExtra,
      );

      final updated = current.copyWith(
        endedAt: now,
        totalRounds: totalRounds,
        totalAttempts: totalDarts,
        successCount: successCount,
        failCount: failCount,
        xpEarned: xp,
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
          'xpEarned': xp,
        },
      );

      // 🔹 1) 세션 기록 저장
      await _repo.updateSession(updated);

      // 🔹 2) 누적 Progress에 XP 반영 (🔥 이게 게이지를 움직이는 핵심)
      if (xp > 0) {
        final progressRepo = sl<TrainingProgressRepository>();
        await progressRepo.addXp(
          userId: updated.userId,
          xpToAdd: xp,
        );
      }

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
