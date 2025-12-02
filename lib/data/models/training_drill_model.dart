// lib/data/models/training_drill_model.dart

import 'package:daoapp/core/utils/dao_training_rating_utils.dart';

/// 드릴 카테고리 (UI 필터, 통계 분류용)
///
/// - boardMapping   : 보드 전체/영역 익히기 (4구역, 상/하/좌/우 등)
/// - finish         : 체크아웃 / 피니시 루트
/// - doublePractice : 더블 집중 연습
/// - scoring        : 점수 쌓기 / 스코어링 (20/19, Count-Up 등)
/// - bull           : SBULL / DBULL / 센터 연습
/// - other          : 그 외 매치 시뮬레이션, 멘탈 훈련 등
enum TrainingDrillCategory {
  boardMapping,
  finish,
  doublePractice,
  scoring,
  bull,
  other,
}

/// 드릴 기록 입력 방식
///
/// v1에서는 최대한 단순하게 3가지:
/// - hitCount     : 전체 다트 수 + 명중 수 (명중률 계산용)
/// - cricketMarks : 총 마크 수 + 총 라운드 수 (MPR 계산용)
/// - scoreOnly    : 점수만 입력 (Count-Up 등)
enum TrainingDrillInputMode {
  hitCount,
  cricketMarks,
  scoreOnly,
}

/// 난이도 (UI에서 표시용)
enum DrillDifficulty {
  veryEasy,
  easy,
  normal,
  hard,
  veryHard,
}

/// 이 드릴이 어떤 티어 구간을 대상으로 하는지
class DrillTierRange {
  final DaoTrainingTier minTier;
  final DaoTrainingTier maxTier;

  const DrillTierRange({
    required this.minTier,
    required this.maxTier,
  });

  bool contains(DaoTrainingTier tier) {
    return tier.index >= minTier.index && tier.index <= maxTier.index;
  }
}

/// "설정용" 드릴 정의 (하드코딩 상수 테이블)
///
/// Firestore에 저장되는 건 이 드릴의 결과(TrainingSessionModel)이고,
/// 이 정의는 앱 코드에서만 사용하는 메타데이터야.
class TrainingDrillDefinition {
  /// 고유 ID (예: "beginner_quadrant_basic")
  final String id;

  /// UI 표시용 제목
  final String titleKo; // 한글 제목
  final String titleEn; // 영문 제목

  /// 카드/리스트에 들어갈 짧은 설명
  final String shortDescriptionKo;
  final String shortDescriptionEn;

  /// 카테고리 (보드맵핑/피니시/더블/스코어링/불/기타)
  final TrainingDrillCategory category;

  /// 대상 티어 구간 (예: Beginner~Learner, Elite~Pro 등)
  final DrillTierRange tierRange;

  /// 입력 방식 (명중 수, 크리켓 마크, 점수만 등)
  final TrainingDrillInputMode inputMode;

  /// 대략적인 예상 소요 시간 (분)
  final int? estimatedMinutes;

  /// 추천 총 다트 수 (예: 30발, 60발 등)
  final int? recommendedDarts;

  /// 목표 구간 설명 (예: "4구역 중 지정 구역", "T20 섹터", "BULL 전체")
  final String targetLabel;

  /// 상세 가이드 (실제 어떻게 던질지 설명)
  final String guideKo;
  final String guideEn;

  /// 난이도
  final DrillDifficulty difficulty;

  /// 추가 설정 (라운드 제한, 목표 성공률 등 커스텀 설정용)
  final Map<String, dynamic>? extraConfig;

  const TrainingDrillDefinition({
    required this.id,
    required this.titleKo,
    required this.titleEn,
    required this.shortDescriptionKo,
    required this.shortDescriptionEn,
    required this.category,
    required this.tierRange,
    required this.inputMode,
    this.estimatedMinutes,
    this.recommendedDarts,
    required this.targetLabel,
    required this.guideKo,
    required this.guideEn,
    this.difficulty = DrillDifficulty.normal,
    this.extraConfig,
  });

  /// 현재 DAO 티어가 이 드릴 추천 범위 안에 들어가는지 체크
  bool isTierInRange(DaoTrainingTier tier) {
    return tierRange.contains(tier);
  }
}
