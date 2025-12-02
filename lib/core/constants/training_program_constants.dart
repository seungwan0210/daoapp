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

const TrainingProgramDefinition beginnerProgram = TrainingProgramDefinition(
  id: 'program_beginner_4w',
  titleKo: '비기너 4주 기초 프로그램',
  titleEn: 'Beginner 4-week Basics',
  descriptionKo: '보드 숫자 순서 익히기와 기본 타겟 감각을 쌓는 과정입니다.',
  descriptionEn: 'Learn basic board mapping and targeting fundamentals.',
  minTier: DaoTrainingTier.beginner,
  maxTier: DaoTrainingTier.beginner,
  drills: [
    rookieBoardMappingDrill,
  ],
);

const TrainingProgramDefinition learnerProgram = TrainingProgramDefinition(
  id: 'program_learner_4w',
  titleKo: '러너 4주 루트 이해 프로그램',
  titleEn: 'Learner 4-week Route Awareness',
  descriptionKo: '싱글 타겟을 확실히 하고, 쉬운 체크아웃 루트를 익힙니다.',
  descriptionEn: 'Gain confidence in singles and basic checkout routes.',
  minTier: DaoTrainingTier.learner,
  maxTier: DaoTrainingTier.learner,
  drills: [
    rookieBoardMappingDrill,
    basicCheckout81Drill,
  ],
);

/// 나머지(컴페티터~마스터)는 지금 만든 구조로 확장만 하면 됨.
/// ========================================

List<TrainingProgramDefinition> getProgramsForTier(DaoTrainingTier tier) {
  const all = [
    beginnerProgram,
    learnerProgram,
    // 앞으로 tier별 프로그램 추가
  ];

  return all.where((p) => p.isTierInRange(tier)).toList();
}
