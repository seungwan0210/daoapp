// lib/core/constants/training_drill_constants.dart

import 'package:daoapp/core/utils/dao_training_rating_utils.dart'
as rating_utils; // <- 7티어 DaoTrainingTier
import 'package:daoapp/data/models/training_drill_model.dart';

/// ===============================
/// 개별 드릴 정의
/// ===============================

/// 비기너/러너용: 보드 숫자 순서 익히기
const TrainingDrillDefinition rookieBoardMappingDrill = TrainingDrillDefinition(
  id: 'rookie_board_mapping_1to20',
  titleKo: '보드 숫자 순서 연습',
  titleEn: 'Board Number Mapping',
  shortDescriptionKo: '1번부터 20번까지 순서대로 맞춰보는 기본 마킹 연습',
  shortDescriptionEn: 'Hit numbers 1 to 20 in order to learn the board.',
  category: TrainingDrillCategory.boardMapping, // ✅ 여기!
  minTier: rating_utils.DaoTrainingTier.beginner, // 비기너
  maxTier: rating_utils.DaoTrainingTier.learner,  // 러너까지
  rounds: 5,
  dartsPerRound: 3,
  targetLabel: '1~20 Single',
  guideKo: '보드를 시계 방향으로 따라가며 1 → 20 순서대로 싱글을 맞춰보세요.\n'
      '실패 시 같은 숫자를 다시 시도하고, 성공/실패를 기록합니다.',
  guideEn: 'Aim single segments from 1 to 20 in order.\n'
      'If you miss, retry the same number and log success/failure.',
);

/// 러너/컴페티터용: 81 체크아웃 루트
const TrainingDrillDefinition basicCheckout81Drill = TrainingDrillDefinition(
  id: 'basic_checkout_81',
  titleKo: '81점 체크아웃 루트',
  titleEn: '81 Checkout Route',
  shortDescriptionKo: 'T15 → D18 루트를 반복하며 마무리 감각을 익히는 연습',
  shortDescriptionEn: 'Practice 81 checkout via T15 → D18 route.',
  category: TrainingDrillCategory.finish, // ✅
  minTier: rating_utils.DaoTrainingTier.learner,       // 러너
  maxTier: rating_utils.DaoTrainingTier.competitor,    // 컴페티터까지
  rounds: 6,
  dartsPerRound: 3,
  targetLabel: '81 Finish (T15 → D18)',
  guideKo: '81점에서 시작하여 T15 → D18 마무리 루트를 상상하며 던져보세요.\n'
      '각 라운드마다 3다트 안에 마무리 성공 여부를 기록합니다.',
  guideEn: 'Start from 81 and imagine T15 → D18 finish route.\n'
      'Record whether you finish within 3 darts per round.',
);

/// 컴페티터/챌린저/엘리트: D16 더블 집중
const TrainingDrillDefinition advancedD16DoubleDrill = TrainingDrillDefinition(
  id: 'advanced_d16_8r',
  titleKo: 'D16 더블 집중 8R',
  titleEn: 'D16 Double Focus (8R)',
  shortDescriptionKo: '중상급 티어를 위한 D16 마무리 집중 연습 (8라운드)',
  shortDescriptionEn: 'Upper-tier focused D16 finishing drill (8 rounds).',
  category: TrainingDrillCategory.doublePractice, // ✅
  minTier: rating_utils.DaoTrainingTier.competitor, // 컴페티터
  maxTier: rating_utils.DaoTrainingTier.elite,      // 엘리트까지
  rounds: 8,
  dartsPerRound: 3,
  targetLabel: 'D16',
  guideKo: '각 라운드마다 D16만 노리고 3다트를 던집니다.\n'
      '라운드별 1~3다트 성공 여부를 기록해, 더블 성공률을 확인합니다.',
  guideEn: 'In each round, throw 3 darts only at D16.\n'
      'Log success for each dart to track your double hit rate.',
);

/// 엘리트/프로/마스터: 170 이미지 트레이닝
const TrainingDrillDefinition expert170RouteDrill = TrainingDrillDefinition(
  id: 'expert_170_route',
  titleKo: '170 체크아웃 이미지 트레이닝',
  titleEn: '170 Checkout Imagery',
  shortDescriptionKo: 'T20 × 2 → Bull 170 마무리 루트를 머릿속에서 반복 연습',
  shortDescriptionEn: 'Visualize and practice the classic 170 finish route.',
  category: TrainingDrillCategory.finish, // ✅
  minTier: rating_utils.DaoTrainingTier.elite,   // 엘리트
  maxTier: rating_utils.DaoTrainingTier.master,  // 마스터까지
  rounds: 5,
  dartsPerRound: 3,
  targetLabel: 'T20, T20, Bull',
  guideKo: '170 상황을 상상하며 T20 → T20 → Bull 루트를 그립니다.\n'
      '각 다트마다 목표 세그먼트를 정하고, 성공/실패를 기록합니다.',
  guideEn: 'Imagine a 170 finish: T20 → T20 → Bull.\n'
      'For each dart, decide the target and log hit or miss.',
);

/// ===============================
/// 티어별 추천 드릴 목록
/// ===============================

const Map<rating_utils.DaoTrainingTier, List<TrainingDrillDefinition>>
kTrainingDrillsByTier = {
  rating_utils.DaoTrainingTier.beginner: [
    rookieBoardMappingDrill,
  ],
  rating_utils.DaoTrainingTier.learner: [
    rookieBoardMappingDrill,
    basicCheckout81Drill,
  ],
  rating_utils.DaoTrainingTier.competitor: [
    rookieBoardMappingDrill,
    basicCheckout81Drill,
    advancedD16DoubleDrill,
  ],
  rating_utils.DaoTrainingTier.challenger: [
    basicCheckout81Drill,
    advancedD16DoubleDrill,
    expert170RouteDrill,
  ],
  rating_utils.DaoTrainingTier.elite: [
    advancedD16DoubleDrill,
    expert170RouteDrill,
  ],
  rating_utils.DaoTrainingTier.pro: [
    advancedD16DoubleDrill,
    expert170RouteDrill,
  ],
  rating_utils.DaoTrainingTier.master: [
    advancedD16DoubleDrill,
    expert170RouteDrill,
  ],
};

List<TrainingDrillDefinition> getDrillsForTier(
    rating_utils.DaoTrainingTier tier,
    ) {
  return kTrainingDrillsByTier[tier] ?? const [];
}

List<TrainingDrillDefinition> recommendedDrillsForToday(
    rating_utils.DaoTrainingTier tier,
    ) {
  return getDrillsForTier(tier);
}
