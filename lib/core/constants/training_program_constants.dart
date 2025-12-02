// lib/core/constants/training_program_constants.dart

import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/core/constants/training_drill_constants.dart';
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
  descriptionKo: '보드 숫자 순서 익히기와 기본 타겟 감각을 쌓는 과정입니다.',
  descriptionEn: 'Learn basic board mapping and targeting fundamentals.',
  minTier: DaoTrainingTier.beginner,
  maxTier: DaoTrainingTier.beginner,
  drills: [
    // 워밍업: 큰 영역 감각
    beginnerQuadrantBasic,
    beginnerTopBottomBasic,
    // 메인: 숫자 감각 + 스코어링
    beginnerAroundTheBoardSingle,
    beginnerLargeSingle20,
    // 피니시: Bull 감각 + 가벼운 Count-Up
    beginnerBigBull,
    beginnerLooseCountUp,
  ],
);

/// 러너용: “싱글·루트 이해” 루틴
const TrainingProgramDefinition learnerProgram = TrainingProgramDefinition(
  id: 'program_learner_4w',
  titleKo: '러너 4주 루트 이해 프로그램',
  titleEn: 'Learner 4-week Route Awareness',
  descriptionKo: '싱글 타겟을 확실히 하고, 쉬운 체크아웃 루트를 익힙니다.',
  descriptionEn: 'Gain confidence in singles and basic checkout routes.',
  minTier: DaoTrainingTier.learner,
  maxTier: DaoTrainingTier.learner,
  drills: [
    // 워밍업: 싱글 정확도 + 상/하 컨트롤
    learnerSingle20x100,
    learnerTopBottomAdvanced,
    // 메인: 20↔19 스위치
    learner20to19Switch,
    // 나중에 Learner용 체크아웃/크리켓 드릴 추가 가능
  ],
);

/// 앞으로 competitor ~ master 도 같은 패턴으로 추가하면 됨.
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

  // 만약 해당 티어 프로그램이 아직 없으면
  // training_drill_constants.dart 쪽의 기본 드릴 맵 사용
  return getDrillsForTier(tier);
}
