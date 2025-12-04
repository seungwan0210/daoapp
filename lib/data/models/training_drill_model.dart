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

/// (옵션) 카테고리 한글 라벨이 필요할 때 쓸 수 있는 확장자
extension TrainingDrillCategoryX on TrainingDrillCategory {
  String get labelKo {
    switch (this) {
      case TrainingDrillCategory.boardMapping:
        return '보드 맵핑';
      case TrainingDrillCategory.finish:
        return '체크아웃/피니시';
      case TrainingDrillCategory.doublePractice:
        return '더블 연습';
      case TrainingDrillCategory.scoring:
        return '스코어링';
      case TrainingDrillCategory.bull:
        return '불 연습';
      case TrainingDrillCategory.other:
      default:
        return '기타';
    }
  }

  String get labelEn {
    switch (this) {
      case TrainingDrillCategory.boardMapping:
        return 'Board Mapping';
      case TrainingDrillCategory.finish:
        return 'Finish';
      case TrainingDrillCategory.doublePractice:
        return 'Double Practice';
      case TrainingDrillCategory.scoring:
        return 'Scoring';
      case TrainingDrillCategory.bull:
        return 'Bull Practice';
      case TrainingDrillCategory.other:
      default:
        return 'Other';
    }
  }
}

/// 입력 방식: 런 모드에서 어떤 UI/로직을 쓸지 결정
enum TrainingDrillInputMode {
  hitCount,     // 성공/실패 개수 입력 (싱글, 더블, T20 등)
  scoreOnly,    // 라운드별 점수 입력 (Count-Up, 501 점수 등)
  cricketMarks, // 라운드별 마크 수 입력 (크리켓 MPR)
}

/// 드릴 난이도 (필수 X, 통계/추천용 메타)
enum DrillDifficulty {
  veryEasy,
  easy,
  normal,
  hard,
  veryHard,
}

/// UI 패턴 (경고: 아직 완전히 쓰지 않아도 됨, 런모드/히스토리 꾸밀 때 참고용)
enum DrillUIPattern {
  boardArea,      // 4분할/상하/좌우 등 보드 영역 중심
  segmentTarget,  // 특정 번호/트리플/더블 등 세그먼트 타겟
  scoreGame,      // Count-Up/501 등 점수 누적 게임
  cricketMarks,   // 크리켓 마크 입력형
  checkoutRoute,  // 체크아웃/피니시 루트형
}

/// 런 스크린에서 어떤 패널을 사용할지
///
/// - genericHit     : 기본 성공/실패 패널 (GenericHitPanel)
/// - tripleSwitch   : T20/T20/T19 패턴 등 트리플 스위치
/// - doubleClock    : D1~DBull 더블 시계
/// - randomCheckout : 랜덤 체크아웃 (60~100 등)
/// - fullCricket    : 풀 크리켓 MPR 드릴
/// - t20Focus       : T20 집중 드릴
/// - fixedRoute     : 고정 루트 체크아웃 (170, 130 등)
enum TrainingDrillRunPanelType {
  genericHit,
  tripleSwitch,
  doubleClock,
  randomCheckout,
  fullCricket,
  t20Focus,
  fixedRoute,
}

/// 이 드릴이 어떤 티어 구간에 추천되는지 범위
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
///
/// - 이건 **코드 상수로만 존재**하고 Firestore에 저장되는 건 아님.
/// - 실제로 저장되는 건 `TrainingSessionModel` (결과 기록) 쪽.
/// - 그래서 여기서는 toJson / fromJson 안 만들어도 괜찮아.
class TrainingDrillDefinition {
  /// 고유 ID (예: "beginner_quadrant_basic")
  final String id;

  /// UI에 보여줄 제목 (한/영)
  final String titleKo;
  final String titleEn;

  /// 짧은 설명 (카드/리스트에서 사용)
  final String shortDescriptionKo;
  final String shortDescriptionEn;

  /// 어떤 카테고리에 속하는지
  final TrainingDrillCategory category;

  /// 어떤 등급 구간(티어)에 추천되는지
  final DrillTierRange tierRange;

  /// 런모드 입력 방식 (hitCount / scoreOnly / cricketMarks)
  final TrainingDrillInputMode inputMode;

  /// 예상 소요 시간 (분) – 없으면 null
  final int? estimatedMinutes;

  /// 추천 총 다트 수 – 없으면 null
  final int? recommendedDarts;

  /// 목표 문구 (예: "T20 x60", "Cricket 20–15 + Bull")
  final String targetLabel;

  /// 한글 가이드 (현재 주력 설명)
  final String guideKo;

  /// (선택) 영어 가이드 – 지금은 안 써도 되니까 optional
  final String? guideEn;

  /// 난이도 – 안 넣으면 null (표시 안 해도 무방)
  final DrillDifficulty? difficulty;

  /// UI 패턴 – 안 넣으면 null (기본 런모드 UI만 사용)
  final DrillUIPattern? uiPattern;

  /// 추가 설정 (라운드 수, 총 다트 수, 타겟 세그먼트 리스트 등)
  ///
  /// 예:
  /// - {'rounds': 10, 'dartsPerRound': 3}
  /// - {'segments': ['T20', 'T19']}
  /// - {'gameType': 'countup', 'targetScore': 600}
  final Map<String, dynamic>? extraConfig;

  /// 런 스크린에서 사용할 패널 타입
  ///
  /// 지정하지 않으면 genericHit 패널 사용.
  final TrainingDrillRunPanelType runPanelType;

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
    this.guideEn,       // 더 이상 필수 아님
    this.difficulty,    // 난이도
    this.uiPattern,     // UI 패턴
    this.extraConfig,   // 추가 설정
    this.runPanelType = TrainingDrillRunPanelType.genericHit, // 기본값
  });
}
