// lib/core/utils/dao_training_xp_utils.dart

import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/data/models/training_session_model.dart';

/// XP 계산에 사용할 메트릭 타입
enum TrainingXpMetricType {
  hitRate, // 더블/싱글, 명중률 계열
  score,   // CountUp, 501, 스코어 게임
  mpr,     // 크리켓 MPR
}

/// 티어 + 메트릭에 따른 기대 구간 (min ~ max)을 정규화하는 헬퍼
double _normalize({
  required double value,
  required double min,
  required double max,
}) {
  if (max <= min) return 0.0;
  if (value <= min) return 0.0;
  if (value >= max) return 1.0;
  return (value - min) / (max - min);
}

/// 티어별 기본 XP (대략적인 값, 나중에 튜닝 가능)
int _baseXpForTier(DaoTrainingTier tier) {
  switch (tier) {
    case DaoTrainingTier.beginner:
      return 5;
    case DaoTrainingTier.learner:
      return 6;
    case DaoTrainingTier.competitor:
      return 7;
    case DaoTrainingTier.challenger:
      return 8;
    case DaoTrainingTier.elite:
      return 9;
    case DaoTrainingTier.pro:
      return 10;
    case DaoTrainingTier.master:
      return 11;
  }
}

/// 카테고리/드릴 타입에 따라 약간 가중치를 줄 수 있음
double _categoryWeight(TrainingDrillCategory category) {
  switch (category) {
    case TrainingDrillCategory.finish:
    case TrainingDrillCategory.doublePractice:
      return 1.2; // 더블/체크아웃은 조금 더 무겁게
    case TrainingDrillCategory.scoring:
      return 1.0;
    case TrainingDrillCategory.boardMapping:
      return 0.9;
    case TrainingDrillCategory.bull:
      return 1.0;
    case TrainingDrillCategory.other:
      return 1.0;
  }
}

/// 드릴 정의 + inputMode 기반으로 어떤 메트릭으로 볼지 결정
TrainingXpMetricType _resolveMetricType(
    TrainingDrillDefinition drill,
    ) {
  final raw = drill.extraConfig?['xpMetric'] as String?;

  if (raw != null) {
    switch (raw) {
      case 'hitRate':
        return TrainingXpMetricType.hitRate;
      case 'score':
        return TrainingXpMetricType.score;
      case 'mpr':
        return TrainingXpMetricType.mpr;
    }
  }

  // extraConfig에 없다면 inputMode / category 기준 기본값
  switch (drill.inputMode) {
    case TrainingDrillInputMode.hitCount:
      return TrainingXpMetricType.hitRate;
    case TrainingDrillInputMode.scoreOnly:
      return TrainingXpMetricType.score;
    case TrainingDrillInputMode.cricketMarks:
      return TrainingXpMetricType.mpr;
  }
}

/// === 티어별 기대 구간 테이블 (예시 값, 나중에 튜닝 가능) ===

/// Count-Up(8R, 최대 1440) 기준 점수 기대 구간
/// - 비기너는 300~450, 마스터는 950~1200 이런 식으로 조정
({int min, int max}) _countUpBand(DaoTrainingTier tier) {
  switch (tier) {
    case DaoTrainingTier.beginner:
      return (min: 300, max: 450);
    case DaoTrainingTier.learner:
      return (min: 400, max: 600);
    case DaoTrainingTier.competitor:
      return (min: 550, max: 700);
    case DaoTrainingTier.challenger:
      return (min: 650, max: 800);
    case DaoTrainingTier.elite:
      return (min: 750, max: 900);
    case DaoTrainingTier.pro:
      return (min: 850, max: 1000);
    case DaoTrainingTier.master:
      return (min: 950, max: 1200);
  }
}

/// 크리켓 MPR 기대 구간 (15R 기준 대략 값)
({double min, double max}) _cricketMprBand(DaoTrainingTier tier) {
  switch (tier) {
    case DaoTrainingTier.beginner:
      return (min: 0.8, max: 1.6);
    case DaoTrainingTier.learner:
      return (min: 1.2, max: 2.0);
    case DaoTrainingTier.competitor:
      return (min: 1.8, max: 2.4);
    case DaoTrainingTier.challenger:
      return (min: 2.2, max: 2.8);
    case DaoTrainingTier.elite:
      return (min: 2.6, max: 3.2);
    case DaoTrainingTier.pro:
      return (min: 3.0, max: 3.6);
    case DaoTrainingTier.master:
      return (min: 3.4, max: 4.0);
  }
}

/// 명중률 기반 드릴 기대 구간
({double min, double max}) _hitRateBand(DaoTrainingTier tier) {
  switch (tier) {
    case DaoTrainingTier.beginner:
      return (min: 0.25, max: 0.45); // 25~45%
    case DaoTrainingTier.learner:
      return (min: 0.30, max: 0.50);
    case DaoTrainingTier.competitor:
      return (min: 0.35, max: 0.55);
    case DaoTrainingTier.challenger:
      return (min: 0.40, max: 0.60);
    case DaoTrainingTier.elite:
      return (min: 0.45, max: 0.65);
    case DaoTrainingTier.pro:
      return (min: 0.50, max: 0.70);
    case DaoTrainingTier.master:
      return (min: 0.55, max: 0.75);
  }
}

class DaoTrainingXpUtils {
  /// 한 세션에 대해 최종 XP 계산
  static int computeXp({
    required TrainingSessionModel session,
    required TrainingDrillDefinition drill,
  }) {
    final tier = session.tierAtThatTime;
    final metricType = _resolveMetricType(drill);

    // 1) 티어별 기본 XP
    final int baseXp = _baseXpForTier(tier);

    // 2) 카테고리 가중치
    final double catWeight = _categoryWeight(drill.category);

    // 3) 성과 정규화 (0 ~ 1)
    double performance = 0.0;

    switch (metricType) {
      case TrainingXpMetricType.hitRate:
        final double hr = session.hitRate ??
            ((session.totalAttempts > 0)
                ? session.successCount / session.totalAttempts
                : 0.0);

        final band = _hitRateBand(tier);
        performance = _normalize(
          value: hr,
          min: band.min,
          max: band.max,
        );
        break;

      case TrainingXpMetricType.score:
      // Count-Up 계열인 경우: totalScore 기준
        final String? gameType = drill.extraConfig?['gameType'] as String?;
        final bool isCountup =
            gameType != null && gameType.startsWith('countup');

        if (isCountup) {
          final int score = session.totalScoreExtra ?? 0; // extra.totalScore
          final band = _countUpBand(tier);
          performance = _normalize(
            value: score.toDouble(),
            min: band.min.toDouble(),
            max: band.max.toDouble(),
          );
        } else {
          // 501 등은 threeDartAvg / ppd 등으로 확장 가능
          final double ppd = session.ppd ?? 0.0; // 없으면 0
          // 예시: 501 기준 PPD 기대 구간 (단순 예시)
          final band = switch (tier) {
            DaoTrainingTier.beginner => (min: 10.0, max: 16.0),
            DaoTrainingTier.learner => (min: 12.0, max: 18.0),
            DaoTrainingTier.competitor => (min: 14.0, max: 20.0),
            DaoTrainingTier.challenger => (min: 16.0, max: 22.0),
            DaoTrainingTier.elite => (min: 18.0, max: 24.0),
            DaoTrainingTier.pro => (min: 20.0, max: 26.0),
            DaoTrainingTier.master => (min: 22.0, max: 28.0),
          };
          performance = _normalize(
            value: ppd,
            min: band.min,
            max: band.max,
          );
        }
        break;

      case TrainingXpMetricType.mpr:
        final double mpr = session.mpr ?? 0.0;
        final band = _cricketMprBand(tier);
        performance = _normalize(
          value: mpr,
          min: band.min,
          max: band.max,
        );
        break;
    }

    // 4) 보너스 계수 (0.5 ~ 1.2 정도에서 움직이게)
    final double bonusFactor = 0.6 + 0.6 * performance; // 0.6 ~ 1.2

    final double rawXp = baseXp * catWeight * bonusFactor;

    // 5) 최소/최대 캡
    final int xp = rawXp.clamp(3.0, 40.0).round();

    return xp;
  }

  /// 🔹 티어별로 "게이지 1바퀴에 필요한 XP(cycleSize)" 추천값
  ///
  /// - Beginner는 좀 더 자주 100%를 느끼게 (조금 낮게)
  /// - Master는 더 오래/깊게 연습해야 한 번 채우는 느낌 (조금 높게)
  ///
  /// 이 값은:
  /// - 새 유저 Progress 초기화할 때
  /// - 레이팅 재평가 후 다음 사이클 목표 XP를 조정할 때
  /// 사용하면 됨.
  static int xpCycleSizeForTier(DaoTrainingTier tier) {
    switch (tier) {
      case DaoTrainingTier.beginner:
        return 80;  // 입문자는 자주 "게이지 찼다!" 경험
      case DaoTrainingTier.learner:
        return 90;
      case DaoTrainingTier.competitor:
        return 100;
      case DaoTrainingTier.challenger:
        return 110;
      case DaoTrainingTier.elite:
        return 120;
      case DaoTrainingTier.pro:
        return 130;
      case DaoTrainingTier.master:
        return 140; // 최상위는 한 바퀴가 조금 더 무겁게
    }
  }
}
