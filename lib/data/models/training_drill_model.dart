// lib/data/models/training_drill_model.dart

import 'package:daoapp/core/utils/dao_training_rating_utils.dart';

/// 드릴 카테고리 (UI 필터, 통계 분류용)
enum TrainingDrillCategory {
  boardMapping,   // 보드 숫자/위치 익히기
  finish,         // 체크아웃 / 피니시 루트
  doublePractice, // 더블 집중 연습
  scoring,        // 점수 쌓기 / 스코어링
  bull,           // 불/센터 연습
  other,          // 기타
}

/// 카테고리 다국어 라벨 확장
extension TrainingDrillCategoryX on TrainingDrillCategory {
  String get labelKo {
    switch (this) {
      case TrainingDrillCategory.boardMapping: return '보드 맵핑';
      case TrainingDrillCategory.finish: return '체크아웃/피니시';
      case TrainingDrillCategory.doublePractice: return '더블 연습';
      case TrainingDrillCategory.scoring: return '스코어링';
      case TrainingDrillCategory.bull: return '불 연습';
      case TrainingDrillCategory.other: default: return '기타';
    }
  }

  String get labelEn {
    switch (this) {
      case TrainingDrillCategory.boardMapping: return 'Board Mapping';
      case TrainingDrillCategory.finish: return 'Finish';
      case TrainingDrillCategory.doublePractice: return 'Double Practice';
      case TrainingDrillCategory.scoring: return 'Scoring';
      case TrainingDrillCategory.bull: return 'Bull Practice';
      case TrainingDrillCategory.other: default: return 'Other';
    }
  }

  String get labelJa {
    switch (this) {
      case TrainingDrillCategory.boardMapping: return 'ボードマッピング';
      case TrainingDrillCategory.finish: return 'フィニッシュ';
      case TrainingDrillCategory.doublePractice: return 'ダブル練習';
      case TrainingDrillCategory.scoring: return 'スコアリング';
      case TrainingDrillCategory.bull: return 'ブル練習';
      case TrainingDrillCategory.other: default: return 'その他';
    }
  }

  String get labelZh {
    switch (this) {
      case TrainingDrillCategory.boardMapping: return '标靶映射';
      case TrainingDrillCategory.finish: return '结镖训练';
      case TrainingDrillCategory.doublePractice: return '双倍训练';
      case TrainingDrillCategory.scoring: return '得分训练';
      case TrainingDrillCategory.bull: return '红心训练';
      case TrainingDrillCategory.other: default: return '其他';
    }
  }
}

/// 입력 방식: 런 모드에서 어떤 UI/로직을 쓸지 결정
enum TrainingDrillInputMode {
  hitCount,     // 성공/실패 개수 입력 (싱글, 더블, T20 등)
  scoreOnly,    // 라운드별 점수 입력 (Count-Up, 501 점수 등)
  cricketMarks, // 라운드별 마크 수 입력 (크리켓 MPR)
}

/// 드릴 난이도
enum DrillDifficulty {
  veryEasy,
  easy,
  normal,
  hard,
  veryHard,
}

/// UI 패턴
enum DrillUIPattern {
  boardArea,      // 4분할/상하/좌우 등 보드 영역 중심
  segmentTarget,  // 특정 번호/트리플/더블 등 세그먼트 타겟
  scoreGame,      // Count-Up/501 등 점수 누적 게임
  cricketMarks,   // 크리켓 마크 입력형
  checkoutRoute,  // 체크아웃/피니시 루트형
}

/// 런 스크린 패널 타입
enum TrainingDrillRunPanelType {
  genericHit,
  tripleSwitch,
  doubleClock,
  randomCheckout,
  fullCricket,
  t20Focus,
  fixedRoute,
}

/// 티어 범위 클래스
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

/// "정의용" 드릴 메타데이터
class TrainingDrillDefinition {
  final String id;

  /// 🔹 제목 다국어 필드
  final String titleKo;
  final String titleEn;
  final String titleJa;
  final String titleZh;
  final String titleZhHans;
  final String titleZhHant;

  /// 🔹 짧은 설명 다국어 필드
  final String shortDescriptionKo;
  final String shortDescriptionEn;
  final String shortDescriptionJa;
  final String shortDescriptionZh;
  final String shortDescriptionZhHans;
  final String shortDescriptionZhHant;

  final TrainingDrillCategory category;
  final DrillTierRange tierRange;
  final TrainingDrillInputMode inputMode;
  final int? estimatedMinutes;
  final int? recommendedDarts;
  final String targetLabel;

  /// 🔹 가이드 다국어 필드
  final String guideKo;
  final String? guideEn;
  final String? guideJa;
  final String? guideZh;
  final String? guideZhHans;
  final String? guideZhHant;

  final DrillDifficulty? difficulty;
  final DrillUIPattern? uiPattern;
  final Map<String, dynamic>? extraConfig;
  final TrainingDrillRunPanelType runPanelType;
  final int baseXp;
  final int maxBonusXp;

  const TrainingDrillDefinition({
    required this.id,
    required this.titleKo,
    required this.titleEn,
    required this.titleJa,
    required this.titleZh,
    required this.titleZhHans,
    required this.titleZhHant,
    required this.shortDescriptionKo,
    required this.shortDescriptionEn,
    required this.shortDescriptionJa,
    required this.shortDescriptionZh,
    required this.shortDescriptionZhHans,
    required this.shortDescriptionZhHant,
    required this.category,
    required this.tierRange,
    required this.inputMode,
    this.estimatedMinutes,
    this.recommendedDarts,
    required this.targetLabel,
    required this.guideKo,
    this.guideEn,
    this.guideJa,
    this.guideZh,
    this.guideZhHans,
    this.guideZhHant,
    this.difficulty,
    this.uiPattern,
    this.extraConfig,
    this.runPanelType = TrainingDrillRunPanelType.genericHit,
    this.baseXp = 50,
    this.maxBonusXp = 50,
  });
}