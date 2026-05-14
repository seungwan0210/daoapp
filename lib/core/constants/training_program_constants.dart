// lib/core/constants/training_program_constants.dart

import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/core/constants/training_drill_constants.dart' as drill_constants;
import 'package:daoapp/data/models/training_drill_model.dart';

class TrainingProgramDefinition {
  final String id;
  final String titleKo;
  final String titleEn;
  final String titleJa; // 🔹 추가
  final String descriptionKo;
  final String descriptionEn;
  final String descriptionJa; // 🔹 추가

  final DaoTrainingTier minTier;
  final DaoTrainingTier maxTier;
  final List<TrainingDrillDefinition> drills;
  final int recommendedSessionsPerWeek;

  const TrainingProgramDefinition({
    required this.id,
    required this.titleKo,
    required this.titleEn,
    required this.titleJa, // 🔹 추가
    required this.descriptionKo,
    required this.descriptionEn,
    required this.descriptionJa, // 🔹 추가
    required this.minTier,
    required this.maxTier,
    required this.drills,
    this.recommendedSessionsPerWeek = 3,
  });

  bool isTierInRange(DaoTrainingTier tier) =>
      tier.index >= minTier.index && tier.index <= maxTier.index;
}

/// ========================================
/// 7티어 기반 기본 프로그램
/// ========================================

/// 비기너용: “기초 감각 쌓기” 루틴
const TrainingProgramDefinition beginnerProgram = TrainingProgramDefinition(
  id: 'program_beginner_4w',
  titleKo: '비기너 4주 기초 프로그램',
  titleEn: 'Beginner 4-week Basics',
  titleJa: 'ビギナー 4週間基礎プログラム',
  descriptionKo: '보드를 4분할/상·하로 나눠 던져 보고, 숫자 한 바퀴와 S20·Bull·Count-Up까지 기초 감각을 쌓는 과정입니다.',
  descriptionEn: 'Build basic board mapping, S20/bull feel, and light Count-Up practice.',
  descriptionJa: 'ボードの4分割、上下의 投げ分け、シングル一周からブル、カウントアップまで基礎を固めます。',
  minTier: DaoTrainingTier.beginner,
  maxTier: DaoTrainingTier.beginner,
  drills: [
    drill_constants.beginnerQuadrantBasic,
    drill_constants.beginnerTopBottomBasic,
    drill_constants.beginnerAroundTheBoardSingle,
    drill_constants.beginnerLargeSingle20,
    drill_constants.beginnerBigBull,
    drill_constants.beginnerLooseCountUp,
  ],
);

/// 러너용: “싱글·보드 컨트롤” 루틴
const TrainingProgramDefinition learnerProgram = TrainingProgramDefinition(
  id: 'program_learner_4w',
  titleKo: '러너 4주 컨트롤 프로그램',
  titleEn: 'Learner 4-week Control Program',
  titleJa: 'ラーナー 4週間コントロールプログラム',
  descriptionKo: '싱글 20 명중률과 상·하 컨트롤, 섹터 루프를 통해 실전 스코어링의 기본 발판을 만드는 과정입니다.',
  descriptionEn: 'Improve S20 accuracy, top/bottom control, and sector loops for real-game scoring.',
  descriptionJa: 'シングル20の的中率と上下のコントロールを強化し、スコアリングの土台を作ります。',
  minTier: DaoTrainingTier.learner,
  maxTier: DaoTrainingTier.learner,
  drills: [
    drill_constants.learnerStandardCountUp8r,
    drill_constants.learnerSingle20x60,
    // 🔹 아까 constants에서 정리한 드릴 이름으로 수정 (Advanced 등 없는 드릴 제거)
    drill_constants.learner20to19Switch,
  ],
);

/// ========================================
/// 티어별 프로그램 조회
/// ========================================

List<TrainingProgramDefinition> getProgramsForTier(DaoTrainingTier tier) {
  const all = [
    beginnerProgram,
    learnerProgram,
  ];

  return all.where((p) => p.isTierInRange(tier)).toList();
}

TrainingProgramDefinition? getPrimaryProgramForTier(DaoTrainingTier tier) {
  final programs = getProgramsForTier(tier);
  if (programs.isEmpty) return null;
  return programs.first;
}

List<TrainingDrillDefinition> getRecommendedDrillsForToday(DaoTrainingTier tier) {
  final program = getPrimaryProgramForTier(tier);
  if (program != null && program.drills.isNotEmpty) {
    return program.drills;
  }
  return drill_constants.getDrillsForTier(tier);
}