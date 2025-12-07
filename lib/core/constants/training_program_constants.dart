// lib/core/constants/training_program_constants.dart

import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/core/constants/training_drill_constants.dart'
as drill_constants;
import 'package:daoapp/data/models/training_drill_model.dart';

class TrainingProgramDefinition {
  final String id;
  final String titleKo;
  final String titleEn;
  final String descriptionKo;
  final String descriptionEn;

  final DaoTrainingTier minTier;
  final DaoTrainingTier maxTier;
  final List<TrainingDrillDefinition> drills;
  final int recommendedSessionsPerWeek;

  const TrainingProgramDefinition({
    required this.id,
    required this.titleKo,
    required this.titleEn,
    required this.descriptionKo,
    required this.descriptionEn,
    required this.minTier,
    required this.maxTier,
    required this.drills,
    this.recommendedSessionsPerWeek = 3,
  });

  bool isTierInRange(DaoTrainingTier tier) =>
      tier.index >= minTier.index && tier.index <= maxTier.index;
}

/// ========================================
/// 7티어 기반 기본 프로그램 예시
/// ========================================

/// 비기너용: “기초 감각 쌓기” 루틴
const TrainingProgramDefinition beginnerProgram = TrainingProgramDefinition(
  id: 'program_beginner_4w',
  titleKo: '비기너 4주 기초 프로그램',
  titleEn: 'Beginner 4-week Basics',
  descriptionKo: '보드를 4분할/상·하로 나눠 던져 보고, 숫자 한 바퀴와 S20·Bull·Count-Up까지 '
      '기초 감각을 쌓는 과정입니다.',
  descriptionEn:
  'Build basic board mapping, S20/bull feel, and light Count-Up practice.',
  minTier: DaoTrainingTier.beginner,
  maxTier: DaoTrainingTier.beginner,
  drills: [
    // 워밍업: 큰 영역 감각
    drill_constants.beginnerQuadrantBasic,
    drill_constants.beginnerTopBottomBasic,
    // 메인: 숫자 감각 + 스코어링
    drill_constants.beginnerAroundTheBoardSingle,
    drill_constants.beginnerLargeSingle20,
    // 피니시: Bull 감각 + 가벼운 Count-Up
    drill_constants.beginnerBigBull,
    drill_constants.beginnerLooseCountUp,
  ],
);

/// 러너용: “싱글·보드 컨트롤” 루틴
const TrainingProgramDefinition learnerProgram = TrainingProgramDefinition(
  id: 'program_learner_4w',
  titleKo: '러너 4주 컨트롤 프로그램',
  titleEn: 'Learner 4-week Control Program',
  descriptionKo: '싱글 20 명중률과 상·하 컨트롤, 상단(20/19/18)·중단(17/16/15) 3섹터 루프를 통해 '
      '실전 스코어링의 기본 발판을 만드는 과정입니다.',
  descriptionEn:
  'Improve S20 accuracy, top/bottom control, and 3-sector loops on the 20/19/18 and 17/16/15 lines for real-game scoring.',
  minTier: DaoTrainingTier.learner,
  maxTier: DaoTrainingTier.learner,
  drills: [
    // 워밍업: 싱글 정확도 + 상/하 컨트롤
    drill_constants.learnerSingle20x60,
    drill_constants.learnerTopBottomAdvanced,
    // 메인: 상단/중단 3섹터 루프
    drill_constants.learner20to19Switch,   // 상단 20/19/18
    drill_constants.learner17to15Line,     // 중단 17/16/15
  ],
);

// 앞으로 competitor ~ master 도 같은 패턴으로 추가하면 됨.
/// ========================================

List<TrainingProgramDefinition> getProgramsForTier(DaoTrainingTier tier) {
  const all = [
    beginnerProgram,
    learnerProgram,
    // 앞으로 tier별 프로그램 추가
  ];

  return all.where((p) => p.isTierInRange(tier)).toList();
}

/// 이 티어에서 “대표 프로그램 하나” 선택
TrainingProgramDefinition? getPrimaryProgramForTier(DaoTrainingTier tier) {
  final programs = getProgramsForTier(tier);
  if (programs.isEmpty) return null;
  // 일단 첫 번째 것을 메인 프로그램으로 사용
  return programs.first;
}

/// ========================================
/// “오늘의 추천 패턴” 헬퍼
///  - 홈 화면에서 바로 쓸 수 있는 루틴 리스트
///  - 1순위: 프로그램에 정의된 드릴들
///  - 2순위: kTrainingDrillsByTier (fallback)
/// ========================================

List<TrainingDrillDefinition> getRecommendedDrillsForToday(
    DaoTrainingTier tier,
    ) {
  final program = getPrimaryProgramForTier(tier);
  if (program != null && program.drills.isNotEmpty) {
    return program.drills;
  }

  // 프로그램이 아직 없거나 비어 있으면: 티어별 기본 드릴 사용
  return drill_constants.getDrillsForTier(tier);
}
