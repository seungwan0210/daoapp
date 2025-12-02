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

/// "설정용" 드릴 정의 (하드코딩 상수 테이블)
///
/// Firestore에 저장되는 건 이 드릴의 결과(TrainingSessionModel)이고,
/// 이 정의는 앱 코드에서만 사용하는 메타데이터야.
class TrainingDrillDefinition {
  final String id;                      // 예: "advanced_d16_8r"
  final String titleKo;                 // UI 표시용 한글 제목
  final String titleEn;                 // 영문 제목
  final String shortDescriptionKo;      // 카드/리스트 요약 설명 (한글)
  final String shortDescriptionEn;      // 카드/리스트 요약 설명 (영문)
  final TrainingDrillCategory category; // 보드맵핑/피니시/더블 등
  final DaoTrainingTier minTier;        // 이 티어부터 추천
  final DaoTrainingTier maxTier;        // 이 티어까지 추천
  final int rounds;                     // 전체 라운드 수 (예: 8R)
  final int dartsPerRound;              // 라운드당 다트 수 (예: 3다트 고정)
  final String targetLabel;             // 목표 구간 설명 (예: "D16", "1~20 Single")
  final String guideKo;                 // 상세 가이드 (한글)
  final String guideEn;                 // 상세 가이드 (영문)

  /// 추가 설정이 필요하면 여기에 확장 (예: 제한시간, 목표 성공률 등)
  final Map<String, dynamic>? extraConfig;

  const TrainingDrillDefinition({
    required this.id,
    required this.titleKo,
    required this.titleEn,
    required this.shortDescriptionKo,
    required this.shortDescriptionEn,
    required this.category,
    required this.minTier,
    required this.maxTier,
    required this.rounds,
    required this.dartsPerRound,
    required this.targetLabel,
    required this.guideKo,
    required this.guideEn,
    this.extraConfig,
  });

  /// 현재 DAO 티어가 이 드릴 추천 범위 안에 들어가는지 체크
  bool isTierInRange(DaoTrainingTier tier) {
    return tier.index >= minTier.index && tier.index <= maxTier.index;
  }
}
