// lib/core/constants/training_drill_constants.dart

import 'package:daoapp/core/utils/dao_training_rating_utils.dart' as rating_utils;
import 'package:daoapp/data/models/training_drill_model.dart';

/// ===============================
/// 1. Beginner (초보자) 드릴
/// ===============================

const TrainingDrillDefinition beginnerQuadrantBasic = TrainingDrillDefinition(
  id: 'beginner_quadrant_basic',
  titleKo: '4분할 감각 만들기',
  titleEn: 'Quadrant Basic',
  shortDescriptionKo: '보드를 4구역으로 나눠 방향·거리 감각을 만드는 입문 드릴',
  shortDescriptionEn: 'Build basic feel using 4 board quadrants.',
  category: TrainingDrillCategory.boardMapping,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.beginner,
    maxTier: rating_utils.DaoTrainingTier.beginner,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 10,
  recommendedDarts: 30,
  targetLabel: '우상단 / 우하단 / 좌하단 / 좌상단',
  guideKo: '앱이 지시하는 구역(예: 우상단)에 3다트를 던지고, '
      '해당 구역 안에 들어간 화살 개수(0~3)를 라운드별로 입력하세요. '
      '10라운드(30발) 중 15발 이상을 목표 구역 안에 모으는 것이 1차 목표입니다.',
  difficulty: DrillDifficulty.veryEasy,
  uiPattern: DrillUIPattern.boardArea,
  extraConfig: {
    'mode': 'quadrant',
    'rounds': 10,
    'dartsPerRound': 3,
    'successTarget': 15,
  },
);

const TrainingDrillDefinition beginnerTopBottomBasic = TrainingDrillDefinition(
  id: 'beginner_top_bottom_basic',
  titleKo: '상단/하단 영역 익히기',
  titleEn: 'Top / Bottom Area Control',
  shortDescriptionKo: '상단/하단 큰 영역을 목표로 던져보며 방향 감각을 만든다.',
  shortDescriptionEn: 'Learn to control top and bottom halves of the board.',
  category: TrainingDrillCategory.boardMapping,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.beginner,
    maxTier: rating_utils.DaoTrainingTier.beginner,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 10,
  recommendedDarts: 40,
  targetLabel: '상단 / 하단',
  guideKo: '먼저 상단 영역만 20발, 그 다음 하단 영역만 20발을 던집니다. '
      '각 라운드(3다트)마다 해당 영역 안에 들어간 다트 개수(0~3)를 입력하세요. '
      '각 영역 20발 중 10발 이상 들어가는 것을 목표로 합니다.',
  difficulty: DrillDifficulty.veryEasy,
  uiPattern: DrillUIPattern.boardArea,
  extraConfig: {
    'mode': 'top_bottom',
    'totalDartsPerArea': 20,
    'dartsPerRound': 3,
  },
);

const TrainingDrillDefinition beginnerAroundTheBoardSingle = TrainingDrillDefinition(
  id: 'beginner_around_board_single',
  titleKo: '싱글 한 바퀴',
  titleEn: 'Around the Board Single',
  shortDescriptionKo: '1→20→Bull 순서로 싱글을 한 바퀴 도는 기초 드릴',
  shortDescriptionEn: 'Hit singles 1→20 then Bull in order.',
  category: TrainingDrillCategory.boardMapping,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.beginner,
    maxTier: rating_utils.DaoTrainingTier.beginner,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 15,
  recommendedDarts: 60,
  targetLabel: '1~20 + S Bull',
  guideKo: '1 → 2 → 3 → … → 20 → S Bull 순서로, 각 숫자를 최소 한 번 맞추면 다음으로 이동합니다. '
      '앱에는 전체 사용 다트 수만 기록하고, 다음 세션에서 더 적은 다트로 완주하는 것을 목표로 합니다.',
  difficulty: DrillDifficulty.easy,
  uiPattern: DrillUIPattern.boardArea,
  extraConfig: {
    'mode': 'around_board',
    'sequence': [
      '1','2','3','4','5','6','7','8','9','10',
      '11','12','13','14','15','16','17','18','19','20','SB',
    ],
  },
);

const TrainingDrillDefinition beginnerLargeSingle20 = TrainingDrillDefinition(
  id: 'beginner_large_single_20',
  titleKo: 'Large Single 20 입문',
  titleEn: 'Large Single 20 Intro',
  shortDescriptionKo: '가까운 거리에서 S20 큰 영역을 노리며 “맞는 느낌”을 만든다.',
  shortDescriptionEn: 'Focus on the large S20 to build basic control.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.beginner,
    maxTier: rating_utils.DaoTrainingTier.beginner,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 10,
  recommendedDarts: 50,
  targetLabel: 'S20 (큰 영역)',
  guideKo: '거리 조절이 필요하다면 약간 앞으로 와서 S20 큰 영역만 50발 던집니다. '
      '각 라운드마다 S20 안에 들어간 개수(0~3)를 입력하고, 25발 이상을 목표로 합니다. '
      '익숙해지면 정규 거리에서 30/50을 목표로 옮깁니다.',
  difficulty: DrillDifficulty.easy,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'targetSegment': 'S20',
    'dartsPerRound': 3,
  },
);

const TrainingDrillDefinition beginnerBigBull = TrainingDrillDefinition(
  id: 'beginner_big_bull',
  titleKo: '빅 Bull 감각',
  titleEn: 'Big Bull Feel',
  shortDescriptionKo: 'BULL 링 전체를 노리며 “센터 쪽으로 모이는 느낌” 만들기',
  shortDescriptionEn: 'Aim at the whole Bull ring to feel the center.',
  category: TrainingDrillCategory.bull,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.beginner,
    maxTier: rating_utils.DaoTrainingTier.beginner,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 10,
  recommendedDarts: 50,
  targetLabel: '전체 Bull 링',
  guideKo: 'BULL 링(SBull+DBull)을 모두 포함하는 큰 원만 노리고 50발을 던집니다. '
      '각 라운드마다 Bull 링 안에 들어간 개수를 입력하고, 총 10발 이상을 목표로 합니다.',
  difficulty: DrillDifficulty.easy,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'targetArea': 'big_bull',
    'dartsPerRound': 3,
  },
);

const TrainingDrillDefinition beginnerLooseCountUp = TrainingDrillDefinition(
  id: 'beginner_loose_countup_8r',
  titleKo: '느슨한 Count-Up',
  titleEn: 'Loose Count-Up',
  shortDescriptionKo: '점수보다는 “보드에 꽂히는 경험”을 쌓는 가벼운 Count-Up',
  shortDescriptionEn: 'A relaxed Count-Up to gain throwing experience.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.beginner,
    maxTier: rating_utils.DaoTrainingTier.beginner,
  ),
  inputMode: TrainingDrillInputMode.scoreOnly,
  estimatedMinutes: 5,
  recommendedDarts: 24,
  targetLabel: '8R Count-Up',
  guideKo: '일반 8R Count-Up을 1게임 플레이하고 최종 점수만 앱에 입력합니다. '
      '200점 → 250점 → 300점 순으로 목표를 올려가세요.',
  difficulty: DrillDifficulty.veryEasy,
  uiPattern: DrillUIPattern.scoreGame,
  extraConfig: {
    'gameType': 'countup',
    'rounds': 8,
    'targetScores': [200, 250, 300],
  },
);

/// ===============================
/// 2. Learner ~ Master 모든 드릴 (guideEn 완전 삭제)
/// ===============================

const TrainingDrillDefinition learnerSingle20x100 = TrainingDrillDefinition(
  id: 'learner_single20_100',
  titleKo: 'Single 20 100발',
  titleEn: 'Single 20 x100',
  shortDescriptionKo: '정규 거리에서 S20만 100발 던지는 정확도 드릴',
  shortDescriptionEn: 'Shoot 100 darts at S20 from the official distance.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(minTier: rating_utils.DaoTrainingTier.learner, maxTier: rating_utils.DaoTrainingTier.learner),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 15,
  recommendedDarts: 100,
  targetLabel: 'S20',
  guideKo: '정규 거리에서 S20만 100발 던지며, 각 라운드(3다트)마다 S20 안에 들어간 개수를 기록합니다. '
      '100발 중 60발 이상을 목표로 합니다.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {'targetSegment': 'S20', 'totalDarts': 100, 'dartsPerRound': 3, 'targetHits': 60},
);

const TrainingDrillDefinition learnerTopBottomAdvanced = TrainingDrillDefinition(
  id: 'learner_top_bottom_advanced',
  titleKo: '상단/하단 영역 컨트롤(심화)',
  titleEn: 'Top / Bottom Advanced',
  shortDescriptionKo: '초보 단계에서 만든 상/하 영역 감각을 더 정교하게 다듬는 드릴',
  shortDescriptionEn: 'Refine your top/bottom control with more darts.',
  category: TrainingDrillCategory.boardMapping,
  tierRange: DrillTierRange(minTier: rating_utils.DaoTrainingTier.learner, maxTier: rating_utils.DaoTrainingTier.learner),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 12,
  recommendedDarts: 60,
  targetLabel: '상단 / 하단',
  guideKo: '상단 30발, 하단 30발을 던지며 각 라운드마다 해당 영역 안에 들어간 개수를 기록합니다. '
      '각 영역 30발 중 20발 이상 들어가는 것이 목표입니다.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.boardArea,
  extraConfig: {'mode': 'top_bottom', 'totalDartsPerArea': 30},
);

const TrainingDrillDefinition learner20to19Switch = TrainingDrillDefinition(
  id: 'learner_20_19_switch',
  titleKo: '20↔19 스위치',
  titleEn: '20 ↔ 19 Switch',
  shortDescriptionKo: '20과 19 사이를 오가며 큰 실수를 줄이는 이동 연습',
  shortDescriptionEn: 'Practice switching between 20 and 19 without big misses.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(minTier: rating_utils.DaoTrainingTier.learner, maxTier: rating_utils.DaoTrainingTier.learner),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 15,
  recommendedDarts: 60,
  targetLabel: '20 / 19',
  guideKo: '세트1: 3발 모두 20, 세트2: 3발 모두 19를 1사이클로 보고, 이를 10사이클 반복합니다. '
      '각 세트에서 목표 숫자에 맞춘 개수 또는 점수를 기록하고, 1·5 같은 빅 넘버를 줄이는 것이 목표입니다.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {'segments': ['20', '19'], 'cycles': 10, 'dartsPerSet': 3},
);

const TrainingDrillDefinition comp20SectorTsd = TrainingDrillDefinition(
  id: 'comp_20_sector_tsd_100',
  titleKo: '20 섹터(T/S/D) 100발',
  titleEn: '20 Sector T/S/D x100',
  shortDescriptionKo: '20 섹터(T20/S20/D20)에만 100발 던지며 정확도와 구성 파악',
  shortDescriptionEn: 'Shoot 100 darts into the 20 sector (T/S/D).',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(minTier: rating_utils.DaoTrainingTier.competitor, maxTier: rating_utils.DaoTrainingTier.competitor),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 15,
  recommendedDarts: 100,
  targetLabel: 'T20 / S20 / D20',
  guideKo: '20 섹터만 노리고 100발을 던지며, T20/S20/D20을 각각 몇 번 맞췄는지 기록합니다. '
      'T20 10개, D20 3개 이상을 목표로 합니다.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {'segments': ['T20', 'S20', 'D20'], 'totalDarts': 100},
);

const TrainingDrillDefinition compDoubleClockHalf = TrainingDrillDefinition(
  id: 'comp_double_clock_half',
  titleKo: '더블 시계 (D1~D10)',
  titleEn: 'Double Clock Half',
  shortDescriptionKo: 'D1~D10까지 반 시계를 돌면서 더블 감각을 올리는 드릴',
  shortDescriptionEn: 'Practice doubles from D1 to D10 with limited darts.',
  category: TrainingDrillCategory.doublePractice,
  tierRange: DrillTierRange(minTier: rating_utils.DaoTrainingTier.competitor, maxTier: rating_utils.DaoTrainingTier.competitor),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 15,
  recommendedDarts: 50,
  targetLabel: 'D1 ~ D10',
  guideKo: 'D1부터 D10까지, 각 더블당 최대 5다트 안에 맞추면 다음 숫자로 이동합니다. '
      '앱에는 전체 사용 다트 수를 기록하고, 점점 적은 다트로 한 바퀴 도는 것이 목표입니다.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'doubleSequence': ['D1','D2','D3','D4','D5','D6','D7','D8','D9','D10'],
    'maxDartsPerDouble': 5,
  },
);

const TrainingDrillDefinition compCheckout40to80 = TrainingDrillDefinition(
  id: 'comp_checkout_40_80',
  titleKo: '40–80 더블 아웃 필수 구간',
  titleEn: '40–80 Double-Out Essentials',
  shortDescriptionKo: '40~80 구간을 더블로 마무리하는 필수 체크아웃 드릴',
  shortDescriptionEn: 'Practice finishing 40–80 only via doubles.',
  category: TrainingDrillCategory.finish,
  tierRange: DrillTierRange(minTier: rating_utils.DaoTrainingTier.competitor, maxTier: rating_utils.DaoTrainingTier.competitor),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 20,
  recommendedDarts: 60,
  targetLabel: '40~80 Double-Out',
  guideKo: '40, 48, 50, 52, 56, 60, 64, 72, 80 등 실전 숫자를 대상으로, '
      '각 숫자당 최대 6다트 안에 반드시 더블로 마무리해야 합니다. '
      '10세트 중 몇 세트를 성공했는지 기록하고 4~5세트 이상을 목표로 합니다.',
  difficulty: DrillDifficulty.hard,
  uiPattern: DrillUIPattern.checkoutRoute,
  extraConfig: {
    'scores': [40,48,50,52,56,60,64,72,80],
    'maxDartsPerScore': 6,
    'totalSets': 10,
  },
);

const TrainingDrillDefinition compCricket2019 = TrainingDrillDefinition(
  id: 'comp_cricket_20_19',
  titleKo: 'Cricket 20/19 집중',
  titleEn: 'Cricket 20 & 19 Focus',
  shortDescriptionKo: '20, 19만 사용하는 크리켓 연습으로 MPR 2.0을 노린다.',
  shortDescriptionEn: 'Practice cricket using only 20 and 19 aiming for 2.0 MPR.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(minTier: rating_utils.DaoTrainingTier.competitor, maxTier: rating_utils.DaoTrainingTier.competitor),
  inputMode: TrainingDrillInputMode.cricketMarks,
  estimatedMinutes: 15,
  recommendedDarts: 45,
  targetLabel: 'Cricket 20 & 19 (15R)',
  guideKo: '20과 19만 사용하는 연습 크리켓을 15라운드 진행하며, '
      '각 라운드마다 만든 마크 수(0~9)를 입력합니다. 앱이 자동으로 MPR을 계산하고, '
      '평균 2.0 이상을 목표로 합니다.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.cricketMarks,
  extraConfig: {'cricketNumbers': ['20','19'], 'rounds': 15, 'targetMpr': 2.0},
);

const TrainingDrillDefinition compCountUpHigh20 = TrainingDrillDefinition(
  id: 'comp_countup_high20',
  titleKo: '20만 던지는 Count-Up (600점 도전)',
  titleEn: 'Count-Up with 20 Only (600+)',
  shortDescriptionKo: '모든 다트를 20에만 던져 600점(=PPD 25)을 노리는 드릴',
  shortDescriptionEn: 'Throw only at 20 in Count-Up and aim for 600+ points.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(minTier: rating_utils.DaoTrainingTier.competitor, maxTier: rating_utils.DaoTrainingTier.challenger),
  inputMode: TrainingDrillInputMode.scoreOnly,
  estimatedMinutes: 8,
  recommendedDarts: 24,
  targetLabel: '20 Only Count-Up (8R)',
  guideKo: '8라운드 동안 모든 다트를 20에만 던지는 Count-Up입니다. '
      '최종 점수만 입력하고, 600점(평균 25점/다트) 이상을 목표로 합니다.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.scoreGame,
  extraConfig: {'gameType': 'countup_fixed_sector', 'rounds': 8, 'fixedSector': 20, 'targetScore': 600},
);

const TrainingDrillDefinition compBullDoubleIntro = TrainingDrillDefinition(
  id: 'comp_bull_double_intro',
  titleKo: 'Bull 더블 입문',
  titleEn: 'Bull Double Intro',
  shortDescriptionKo: 'Bull 60발 중 SBull/DBull을 나누어 기록하는 상급 입문 드릴',
  shortDescriptionEn: 'Shoot 60 darts at Bull and track SBull/DBull separately.',
  category: TrainingDrillCategory.bull,
  tierRange: DrillTierRange(minTier: rating_utils.DaoTrainingTier.competitor, maxTier: rating_utils.DaoTrainingTier.competitor),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 10,
  recommendedDarts: 60,
  targetLabel: 'SBull / DBull',
  guideKo: 'Bull을 향해 60발을 던지며, SBull과 DBull을 따로 기록합니다. '
      'DBull 5개 이상, SBull+DBull 합 20개 이상을 목표로 합니다.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {'targetArea': 'bull_split', 'totalDarts': 60, 'targetSbPlusDb': 20, 'targetDb': 5},
);

// Challenger ~ Master 드릴도 동일하게 계속 정의 (총 70개 이상 드릴 포함)

const TrainingDrillDefinition challCheckout60to100Random = TrainingDrillDefinition(
  id: 'chall_checkout_60_100_random',
  titleKo: '60~100 랜덤 체크아웃',
  titleEn: 'Random Checkout 60–100',
  shortDescriptionKo: '60~100 구간 숫자를 랜덤으로 받아 2R(6다트) 안에 마무리하는 드릴',
  shortDescriptionEn: 'Random finish practice between 60–100 in up to 6 darts.',
  category: TrainingDrillCategory.finish,
  tierRange: DrillTierRange(minTier: rating_utils.DaoTrainingTier.challenger, maxTier: rating_utils.DaoTrainingTier.challenger),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 20,
  recommendedDarts: 180,
  targetLabel: '60~100 랜덤 Double-Out',
  guideKo: '앱이 60~100 사이 점수를 랜덤으로 제시합니다.\n'
      '각 세트마다 최대 2라운드(6다트) 안에 체크아웃을 시도하고, '
      '성공/실패로 기록하세요.\n'
      '30세트 후 성공률 30~40% 정도를 목표로 합니다.',
  difficulty: DrillDifficulty.hard,
  uiPattern: DrillUIPattern.checkoutRoute,
  extraConfig: {
    'mode': 'random_range',
    'minScore': 60,
    'maxScore': 100,
    'maxDartsPerScore': 6,
    'totalSets': 30,
  },
);

// Ch4.2 더블 시계 풀 (2단 분리)
const TrainingDrillDefinition challDoubleClockFull = TrainingDrillDefinition(
  id: 'chall_double_clock_full',
  titleKo: '더블 시계 풀 (D1~D20 + DB)',
  titleEn: 'Full Double Clock',
  shortDescriptionKo:
  'D1~D20과 DB까지 전 구간 더블을 돌며 한 바퀴 완주를 노리는 드릴',
  shortDescriptionEn:
  'Run the full double clock from D1 to D20 plus DB with limited darts.',
  category: TrainingDrillCategory.doublePractice,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.challenger,
    maxTier: rating_utils.DaoTrainingTier.challenger,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 25,
  recommendedDarts: 21 * 6, // (D1~D20 + DB) × 최대 6다트
  targetLabel: 'D1 ~ D20 + DBull',
  guideKo: 'D1부터 D20, 그리고 DBull까지 전 구간 더블을 연습합니다.\n'
      '실제 운영은 2일로 나눠도 좋습니다.\n'
      '- Day1: D1~D10\n'
      '- Day2: D11~D20 + DB\n\n'
      '각 더블당 최대 6다트 안에 맞추면 다음 숫자로 이동하고,\n'
      '앱에는 전체 사용 다트 수와 맞춘 더블 개수를 기록합니다.\n'
      '궁극적인 목표는 “한 바퀴를 100다트 안쪽으로 정리”하는 것입니다.',
  difficulty: DrillDifficulty.hard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'doubleSequence': [
      'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'D8', 'D9', 'D10',
      'D11', 'D12', 'D13', 'D14', 'D15', 'D16', 'D17', 'D18', 'D19', 'D20',
      'DBULL',
    ],
    'maxDartsPerDouble': 6,
    'suggestSplitDays': true,
  },
);

// Ch4.3 T20 집중 60발
const TrainingDrillDefinition challT20Focus60 = TrainingDrillDefinition(
  id: 'chall_t20_focus_60',
  titleKo: 'T20 집중 60발',
  titleEn: 'T20 Focus x60',
  shortDescriptionKo: 'T20만 60발 던져 25% 이상 트리플 성공률을 노리는 드릴',
  shortDescriptionEn: 'Throw 60 darts at T20 aiming for 25%+ success.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.challenger,
    maxTier: rating_utils.DaoTrainingTier.challenger,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 12,
  recommendedDarts: 60,
  targetLabel: 'T20 x60',
  guideKo: 'T20만 집중해서 60발을 던지고, 라운드마다 T20에 맞춘 개수를 기록합니다.\n'
      '전체 60발 중 T20 15개 이상(약 25% 성공률)을 목표로 합니다.\n'
      '히스토리에서는 날짜별 T20 성공 개수를 그래프로 확인하면 좋습니다.',
  difficulty: DrillDifficulty.hard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'segments': ['T20'],
    'totalDarts': 60,
    'targetHits': 15,
  },
);

// Ch4.4 풀 크리켓(20~15+B) MPR 드릴
const TrainingDrillDefinition challCricketFull2015B = TrainingDrillDefinition(
  id: 'chall_cricket_full_20_15_bull',
  titleKo: 'Cricket 20~15 + Bull MPR 드릴',
  titleEn: 'Full Cricket 20–15 + Bull',
  shortDescriptionKo: '20~15와 Bull을 모두 사용하는 풀 크리켓 연습, 목표 MPR 2.2~2.5',
  shortDescriptionEn:
  'Practice full cricket (20–15 + Bull) targeting 2.2–2.5 MPR.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.challenger,
    maxTier: rating_utils.DaoTrainingTier.challenger,
  ),
  inputMode: TrainingDrillInputMode.cricketMarks,
  estimatedMinutes: 20,
  recommendedDarts: 15 * 3,
  targetLabel: 'Cricket 20–15 + Bull (15R)',
  guideKo: '20 → 19 → 18 → 17 → 16 → 15 → Bull 순서로 진행하는 연습 크리켓입니다.\n'
      '15라운드를 플레이하며, 각 라운드의 총 마크 수(0~9)를 입력하면 앱이 자동으로 MPR을 계산합니다.\n'
      '평균 MPR 2.2~2.5 정도를 목표로 설정하고, 자신의 평균이 어떻게 변하는지 히스토리로 확인해 보세요.',
  difficulty: DrillDifficulty.hard,
  uiPattern: DrillUIPattern.cricketMarks,
  extraConfig: {
    'cricketNumbers': ['20', '19', '18', '17', '16', '15', 'Bull'],
    'rounds': 15,
    'targetMprMin': 2.2,
    'targetMprMax': 2.5,
  },
);

// Ch4.5 Count-Up 700 도전
const TrainingDrillDefinition challCountUp700 = TrainingDrillDefinition(
  id: 'chall_countup_700',
  titleKo: 'Count-Up 700점 도전',
  titleEn: 'Count-Up 700 Challenge',
  shortDescriptionKo: '8R Count-Up에서 650→700→720 단계 목표에 도전하는 드릴',
  shortDescriptionEn:
  '8-round Count-Up aiming for 650 → 700 → 720 score milestones.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.challenger,
    maxTier: rating_utils.DaoTrainingTier.challenger,
  ),
  inputMode: TrainingDrillInputMode.scoreOnly,
  estimatedMinutes: 8,
  recommendedDarts: 8 * 3,
  targetLabel: 'Count-Up (8R)',
  guideKo: '일반 8라운드 Count-Up을 1게임 플레이하고 최종 점수를 앱에 입력합니다.\n'
      '목표 점수는 650 → 700 → 720 단계로 설정해 두고, 히스토리에서 날짜별 최고 점수 그래프를 보면 좋습니다.\n'
      '단순 점수뿐 아니라 “어느 구간에서 점수가 많이 빠지는지” 코멘트로 남겨두면 코칭에도 도움이 됩니다.',
  difficulty: DrillDifficulty.hard,
  uiPattern: DrillUIPattern.scoreGame,
  extraConfig: {
    'gameType': 'countup',
    'rounds': 8,
    'milestones': [650, 700, 720],
  },
);

// ===============================
// 5. Elite (엘리트) 전용 드릴
// ===============================

// E5.1 T20 60발 정밀
const TrainingDrillDefinition eliteT20Precision60 = TrainingDrillDefinition(
  id: 'elite_t20_precision_60',
  titleKo: 'T20 정밀 60발',
  titleEn: 'T20 Precision x60',
  shortDescriptionKo: 'T20만 60발 던져 트리플 성공률 33% 이상을 노리는 드릴',
  shortDescriptionEn: 'Throw 60 darts at T20 aiming for 33%+ success.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.elite,
    maxTier: rating_utils.DaoTrainingTier.elite,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 12,
  recommendedDarts: 60,
  targetLabel: 'T20 x60',
  guideKo: 'T20만 집중해서 60발을 던지고, 라운드마다 T20에 맞춘 개수를 기록합니다.\n'
      '전체 60발 중 T20 20개 이상(약 33% 성공률)을 목표로 합니다.\n'
      '히스토리에서 날짜별 T20 성공 개수를 그래프로 확인하면 좋습니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'segments': ['T20'],
    'totalDarts': 60,
    'targetHits': 20,
  },
);

// E5.2 T20 ↔ T19 트리플 스위치
const TrainingDrillDefinition eliteT20T19TripleSwitch = TrainingDrillDefinition(
  id: 'elite_t20_t19_triple_switch',
  titleKo: 'T20 ↔ T19 트리플 스위치',
  titleEn: 'T20 ↔ T19 Triple Switch',
  shortDescriptionKo:
  '세트마다 T20→T20→T19 패턴으로 30세트를 진행하며 트리플 전환 감각을 만든다.',
  shortDescriptionEn:
  '30 sets of T20→T20→T19 to build triple switching consistency.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.elite,
    maxTier: rating_utils.DaoTrainingTier.elite,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 20,
  recommendedDarts: 30 * 3,
  targetLabel: 'T20 → T20 → T19 (30세트)',
  guideKo: '1세트 = 3다트로, 1·2번째는 T20, 3번째는 T19를 노립니다.\n'
      '총 30세트를 진행하면서, 각 세트별 T20/T19 트리플 개수를 기록하거나 '
      '전체 세션에서 T20·T19 합계를 기록해도 좋습니다.\n'
      '목표는 T20+T19 합계 30개 이상(세트당 평균 1개 이상)입니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'patternDescription': 'Dart1: T20, Dart2: T20, Dart3: T19',
    'segments': ['T20', 'T19'],
    'sets': 30,
    'dartsPerSet': 3,
    'targetTotalTriples': 30,
  },
);

// E5.3 61~120 핵심 체크아웃
const TrainingDrillDefinition eliteCheckout61to120 = TrainingDrillDefinition(
  id: 'elite_checkout_61_120',
  titleKo: '61~120 핵심 체크아웃',
  titleEn: 'Key Checkout 61–120',
  shortDescriptionKo: '61~120 구간을 랜덤으로 받아 6다트 안에 마무리하는 핵심 피니시 드릴',
  shortDescriptionEn:
  'Random finish practice between 61–120 with up to 6 darts per attempt.',
  category: TrainingDrillCategory.finish,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.elite,
    maxTier: rating_utils.DaoTrainingTier.elite,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 25,
  recommendedDarts: 30 * 6,
  targetLabel: '61~120 Random Checkout',
  guideKo: '앱이 61~120 사이의 점수를 랜덤으로 제시합니다.\n'
      '각 세트마다 최대 6다트 안에 체크아웃을 시도하고, 성공/실패를 기록합니다.\n'
      '30세트 진행 후 성공률이 40% 근처에 도달하는 것을 목표로 합니다.\n'
      '루트(예: 96= T20→D18 / T19→D19 등)를 메모해두면 실제 경기에서 큰 도움이 됩니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.checkoutRoute,
  extraConfig: {
    'mode': 'random_range',
    'minScore': 61,
    'maxScore': 120,
    'maxDartsPerScore': 6,
    'totalSets': 30,
    'targetSuccessRate': 0.4,
  },
);

// E5.4 D16 & D20 더블 집중
const TrainingDrillDefinition eliteDoubleClusterD16D20 = TrainingDrillDefinition(
  id: 'elite_double_cluster_d16_d20',
  titleKo: 'D16 & D20 더블 클러스터',
  titleEn: 'D16 & D20 Double Cluster',
  shortDescriptionKo: 'D16과 D20 각각 60발씩 던져 더블 성공률을 집중적으로 끌어올리는 드릴',
  shortDescriptionEn:
  'Throw 60 darts each at D16 and D20 to sharpen double accuracy.',
  category: TrainingDrillCategory.doublePractice,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.elite,
    maxTier: rating_utils.DaoTrainingTier.elite,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 25,
  recommendedDarts: 120,
  targetLabel: 'D16 x60 / D20 x60',
  guideKo: 'D16만 60발, D20만 60발을 각각 던지며, 라운드마다 맞춘 개수를 기록합니다.\n'
      '각 번호당 20개 이상(33% 이상) 맞추는 것을 1차 목표로 잡고, '
      '익숙해지면 목표치를 조금씩 올려보세요.\n'
      '실전 501 Double-Out에서 가장 자주 나오는 더블을 강하게 만들어 줍니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'segments': ['D16', 'D20'],
    'dartsPerSegment': 60,
    'totalDarts': 120,
    'targetHitsPerSegment': 20,
  },
);

// E5.5 501 더블 압박 드릴 (라운드형)
const TrainingDrillDefinition elite501PressureFinish = TrainingDrillDefinition(
  id: 'elite_501_pressure_finish_30x',
  titleKo: '501 더블 압박 피니시 (30세트)',
  titleEn: '501 Pressure Finish (30 Sets)',
  shortDescriptionKo:
  '61~100 구간에서 3다트 안에 더블 아웃을 노리는 압박 피니시 드릴',
  shortDescriptionEn:
  'Practice finishing 61–100 under pressure with only 3 darts per set.',
  category: TrainingDrillCategory.finish,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.elite,
    maxTier: rating_utils.DaoTrainingTier.elite,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 30,
  recommendedDarts: 30 * 3,
  targetLabel: '61~100 Double-Out (3Darts)',
  guideKo: '앱에서 61~100 사이 숫자를 랜덤으로 제시합니다.\n'
      '각 세트마다 해당 점수에서 3다트 안에 더블 아웃을 노립니다.\n'
      '3다트를 다 쓰면, 이 세트가 성공(1)인지 실패(0)인지 입력만 하면 됩니다.\n'
      '총 30세트 진행 후, 성공 세트 수와 성공률을 확인하고 '
      '다음 세션에서 기록을 갱신하는 것을 목표로 합니다.\n'
      '※ 실제 501 전체 레그 통계를 외울 필요 없이, '
      '“마무리 순간만 집중해서 기록하는” 연습용 피니시 드릴입니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.checkoutRoute,
  extraConfig: {
    'scoreRangeMin': 61,
    'scoreRangeMax': 100,
    'totalSets': 30,
    'maxDartsPerSet': 3,
    'hintTargetSuccessRateMin': 0.35,
    'hintTargetSuccessRateMax': 0.45,
  },
);

// E5.6 Cricket 파워 (마크 입력형 MPR 드릴)
const TrainingDrillDefinition eliteCricketPowerMarks = TrainingDrillDefinition(
  id: 'elite_cricket_power_marks_15r',
  titleKo: 'Cricket 파워 15R (마크 드릴)',
  titleEn: 'Cricket Power 15R (Marks Drill)',
  shortDescriptionKo:
  '20~15 + Bull을 대상으로 15라운드 동안 마크 수를 입력하며 MPR 2.8~3.0을 노리는 드릴',
  shortDescriptionEn:
  'Practice full-board cricket marks for 15 rounds targeting 2.8–3.0 MPR.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.elite,
    maxTier: rating_utils.DaoTrainingTier.elite,
  ),
  inputMode: TrainingDrillInputMode.cricketMarks,
  estimatedMinutes: 20,
  recommendedDarts: 15 * 3,
  targetLabel: 'Cricket 20–15 + B (15R)',
  guideKo: '20, 19, 18, 17, 16, 15, Bull을 모두 사용하는 연습 크리켓입니다.\n'
      '15라운드 동안 각 라운드가 끝날 때마다, 해당 라운드에서 만든 총 마크 수(0~9)를 앱에 입력합니다.\n'
      '세션이 끝나면 앱이 자동으로 MPR을 계산해주며, 평균 2.8~3.0 MPR을 목표로 합니다.\n'
      '실제 게임처럼 복잡한 점수/상대 정보는 신경쓰지 않고, '
      '“매 라운드 3다트로 몇 마크를 만들었는지”에만 집중할 수 있는 구조입니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.cricketMarks,
  extraConfig: {
    'cricketNumbers': ['20', '19', '18', '17', '16', '15', 'B'],
    'rounds': 15,
    'targetMprMin': 2.8,
    'targetMprMax': 3.0,
  },
);

// ===============================
// 6. Pro (프로) 전용 드릴
// ===============================

// P6.1 501 Double-Out 18다트 스탠다드 (T20 집중)
const TrainingDrillDefinition pro501Standard18Darts = TrainingDrillDefinition(
  id: 'pro_501_standard_18darts',
  titleKo: '501 Double-Out 18다트 스탠다드 (T20 집중)',
  titleEn: '501 Double-Out 18-Dart Standard (T20 Focus)',
  shortDescriptionKo:
  '불에 의존하지 않고 T20 중심 스코어링으로 501을 18다트 이내에 끝내는지 체크하는 프로용 드릴',
  shortDescriptionEn:
  'Check if you can finish 501 within 18 darts using T20-focused scoring.',
  category: TrainingDrillCategory.finish,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.pro,
    maxTier: rating_utils.DaoTrainingTier.pro,
  ),
  inputMode: TrainingDrillInputMode.scoreOnly,
  estimatedMinutes: 40,
  recommendedDarts: 0,
  targetLabel: '501 Double-Out (<=18 Darts, T20)',
  guideKo: '각 세트마다 501 Double-Out 한 레그를 플레이합니다.\n'
      '- 기본 전략은 T20 중심 스코어링 (130~170대 스코어 지향)\n'
      '- 불에만 의존하지 않고, 20 트리플/더블 위주의 마무리 이미지를 가져갑니다.\n\n'
      '레그가 끝나면 그 레그에 사용한 “총 다트 수”만 앱에 입력하세요.\n'
      '앱은 18다트 이내면 “성공”, 넘으면 “실패”로 처리해 세션별 성공 세트 수를 보여줄 수 있습니다.\n'
      '총 10세트 정도를 권장하며, 18다트 이내 완주 비율을 점점 올리는 것을 목표로 합니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.scoreGame,
  extraConfig: {
    'gameType': '501_doubleout_18darts_t20',
    'suggestedSets': 10,
    'successThresholdDarts': 18,
    'scoringFocus': 'T20',
  },
);

// P6.2 T20 100발 (프로 스탠다드)
const TrainingDrillDefinition proT20_100Darts = TrainingDrillDefinition(
  id: 'pro_t20_100_darts',
  titleKo: 'T20 집중 100발',
  titleEn: 'T20 Focus x100',
  shortDescriptionKo:
  'T20만 100발 던져 트리플 성공률 40% 이상을 노리는 프로용 스코어링 드릴',
  shortDescriptionEn:
  'Throw 100 darts at T20 aiming for 40%+ triple success rate.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.pro,
    maxTier: rating_utils.DaoTrainingTier.pro,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 20,
  recommendedDarts: 100,
  targetLabel: 'T20 x100',
  guideKo: 'T20만 100발을 던지면서, 라운드마다 T20에 맞춘 개수를 기록합니다.\n'
      '전체 100발 중 T20 40개 이상(40% 성공률)을 1차 목표로 삼고, '
      '상태가 좋을 때는 45~50개도 도전할 수 있습니다.\n'
      '히스토리에서 세션별 T20 개수를 비교하면 스코어링 성장도를 한눈에 볼 수 있습니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'segments': ['T20'],
    'totalDarts': 100,
    'targetHits': 40,
  },
);

// P6.3 대표 하이 피니시 8개 세트
const TrainingDrillDefinition proHighFinishSet = TrainingDrillDefinition(
  id: 'pro_high_finish_set_8',
  titleKo: '대표 하이 피니시 8개',
  titleEn: 'High Finish Set of 8',
  shortDescriptionKo:
  '170, 167, 164, 161, 160, 158, 157, 153 등 대표 하이 피니시 루트를 세트별로 반복 연습',
  shortDescriptionEn:
  'Practice 8 classic high finishes (170, 167, 164, etc.) in repeated sets.',
  category: TrainingDrillCategory.finish,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.pro,
    maxTier: rating_utils.DaoTrainingTier.pro,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 30,
  recommendedDarts: 40 * 3,
  targetLabel: 'High Finish x8 (40세트)',
  guideKo: '연습 숫자: 170, 167, 164, 161, 160, 158, 157, 153.\n'
      '각 숫자당 5세트씩, 총 40세트를 진행합니다.\n'
      '각 세트에서 “설정한 루트대로 3다트 안에 마무리했는지”만 기준으로 성공/실패를 기록합니다.\n'
      '실제 성공률이 10~20%만 돼도 이미 상급이며, '
      '루트 암기와 2다트 남기기 감각을 만드는 것이 핵심입니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.checkoutRoute,
  extraConfig: {
    'scores': [170, 167, 164, 161, 160, 158, 157, 153],
    'setsPerScore': 5,
    'totalSets': 40,
    'maxDartsPerSet': 3,
    'hintTargetSuccessRateMin': 0.1,
    'hintTargetSuccessRateMax': 0.2,
  },
);

// P6.4 크리켓 상위 MPR (마크 드릴, Pro 버전)
const TrainingDrillDefinition proCricketHighMprMarks = TrainingDrillDefinition(
  id: 'pro_cricket_high_mpr_marks_20r',
  titleKo: 'Cricket 상위 MPR 20R',
  titleEn: 'High MPR Cricket 20R',
  shortDescriptionKo:
  '20~15 + Bull 풀 크리켓 마크를 20라운드 입력하며 MPR 3.4~3.8을 노리는 드릴',
  shortDescriptionEn:
  'Record marks over 20 rounds of full-board cricket aiming for 3.4–3.8 MPR.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.pro,
    maxTier: rating_utils.DaoTrainingTier.pro,
  ),
  inputMode: TrainingDrillInputMode.cricketMarks,
  estimatedMinutes: 25,
  recommendedDarts: 20 * 3,
  targetLabel: 'Cricket 20–15 + B (20R)',
  guideKo: '20, 19, 18, 17, 16, 15, Bull을 모두 사용하는 연습 크리켓입니다.\n'
      '20라운드 동안 각 라운드가 끝날 때마다, 그 라운드에서 만든 총 마크 수(0~9)를 앱에 입력합니다.\n'
      '세션이 끝나면 앱이 자동으로 MPR을 계산하며, 평균 3.4~3.8 MPR을 목표로 합니다.\n'
      '실제 경기처럼 룰/점수 전체를 기억할 필요 없이, '
      '“3다트로 몇 마크를 만들어냈는지”에만 집중할 수 있는 프로용 마크 드릴입니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.cricketMarks,
  extraConfig: {
    'cricketNumbers': ['20', '19', '18', '17', '16', '15', 'B'],
    'rounds': 20,
    'targetMprMin': 3.4,
    'targetMprMax': 3.8,
  },
);

// P6.5 Bull 컨트롤 100발 (Pro 기준)
const TrainingDrillDefinition proBull100 = TrainingDrillDefinition(
  id: 'pro_bull_100',
  titleKo: 'Bull 컨트롤 100발',
  titleEn: 'Bull Control x100',
  shortDescriptionKo:
  'BULL 100발을 던지며 SBull/DBull 개수를 나누어 기록하는 컨트롤 드릴',
  shortDescriptionEn:
  'Throw 100 darts at Bull tracking SBull and DBull separately.',
  category: TrainingDrillCategory.bull,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.pro,
    maxTier: rating_utils.DaoTrainingTier.pro,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 20,
  recommendedDarts: 100,
  targetLabel: 'Bull x100',
  guideKo: 'BULL을 향해 100발을 던지면서, SBull과 DBull 개수를 따로 기록합니다.\n'
      '목표:\n'
      '- SBull+DBull 합 60개 이상\n'
      '- DBull 15개 이상\n'
      'Bull 컨트롤은 소프트/스틸 모두에서 마무리, 점수, 멘탈에 큰 영향을 줍니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'targetArea': 'bull_split',
    'totalDarts': 100,
    'targetSbPlusDb': 60,
    'targetDb': 15,
  },
);

// P6.6 클러치 더블 2다트 드릴
const TrainingDrillDefinition proClutchDouble2Darts = TrainingDrillDefinition(
  id: 'pro_clutch_double_2darts_30x',
  titleKo: '클러치 더블 2다트 (30세트)',
  titleEn: 'Clutch Double 2-Dart (30 Sets)',
  shortDescriptionKo:
  'D16, D20 등 자주 쓰는 더블을 2다트만 가지고 마무리하는 압박 상황 재현 드릴',
  shortDescriptionEn:
  'Simulate pressure doubles (like D16/D20) with only 2 darts per set.',
  category: TrainingDrillCategory.doublePractice,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.pro,
    maxTier: rating_utils.DaoTrainingTier.pro,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 20,
  recommendedDarts: 30 * 2,
  targetLabel: 'D16 / D20 (2 Darts)',
  guideKo: 'D16, D20, D8, D12 등 본인이 자주 사용하는 더블을 선택해서, '
      '각 세트마다 2다트만 사용해 마무리를 시도합니다.\n'
      '2다트 안에 더블을 맞추면 성공(1), 못 맞추면 실패(0)로 기록합니다.\n'
      '총 30세트를 진행하며, 성공 세트 수와 성공률을 확인하고 '
      '실전 클러치 더블 성공 감각을 끌어올리는 것이 목표입니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'preferredDoubles': ['D16', 'D20', 'D8', 'D12'],
    'dartsPerSet': 2,
    'totalSets': 30,
    'hintTargetSuccessRateMin': 0.4,
    'hintTargetSuccessRateMax': 0.6,
  },
);

// ===============================
// 7. Master (마스터) 전용 드릴
// ===============================

// M7.1 T20 120발 (50% 목표)
const TrainingDrillDefinition masterT20_120Darts = TrainingDrillDefinition(
  id: 'master_t20_120_darts',
  titleKo: 'T20 집중 120발',
  titleEn: 'T20 Focus x120',
  shortDescriptionKo:
  'T20만 120발을 던지며 트리플 성공률 50%를 노리는 마스터용 스코어링 드릴',
  shortDescriptionEn:
  'Throw 120 darts at T20 aiming for 50% triple success rate.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.master,
    maxTier: rating_utils.DaoTrainingTier.master,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 25,
  recommendedDarts: 120,
  targetLabel: 'T20 x120',
  guideKo: 'T20만 120발을 던집니다.\n'
      '라운드(3다트)가 끝날 때마다 이번 라운드에서 맞춘 T20 개수(0~3)를 앱에 입력합니다.\n'
      '전체 120발 중 T20 60개 이상(50% 성공률)을 1차 목표로 삼고, 컨디션 좋을 때는 70개 이상도 도전해보세요.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'segments': ['T20'],
    'totalDarts': 120,
    'targetHits': 60,
  },
);

// M7.2 170 체크아웃 루트 집중 (30세트)
const TrainingDrillDefinition master170RouteFocused30 = TrainingDrillDefinition(
  id: 'master_170_route_focused_30',
  titleKo: '170 체크아웃 루트 집중 (30세트)',
  titleEn: '170 Checkout Route Focus (30 Sets)',
  shortDescriptionKo:
  'T20 → T20 → Bull 170 루트를 30세트 반복하며 루트 선택과 자신감을 만드는 드릴',
  shortDescriptionEn:
  'Repeat the 170 route (T20, T20, Bull) over 30 sets to build confidence.',
  category: TrainingDrillCategory.finish,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.master,
    maxTier: rating_utils.DaoTrainingTier.master,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 20,
  recommendedDarts: 30 * 3,
  targetLabel: '170 Route (T20,T20,Bull)',
  guideKo: '각 세트마다 170 상황을 가정하고 T20 → T20 → Bull 루트대로 3다트를 던집니다.\n'
      '루트 그대로 3다트 안에 170을 마무리하면 성공(1), 중간에 루트를 바꾸거나 못 끝내면 실패(0)로 기록하세요.\n'
      '30세트 중 1~2회 성공만 나와도 충분히 높은 수준이고, '
      '실제 목표는 “항상 같은 루트를 자신 있게 선택해서 던지는 것”입니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.checkoutRoute,
  extraConfig: {
    'score': 170,
    'route': ['T20', 'T20', 'Bull'],
    'totalSets': 30,
    'maxDartsPerSet': 3,
    'hintTargetSuccessMin': 1,
    'hintTargetSuccessMax': 2,
  },
);

// M7.3 Cricket 4.0+ MPR 드릴 (마크 20R)
const TrainingDrillDefinition masterCricket4Mpr20R = TrainingDrillDefinition(
  id: 'master_cricket_4mpr_20r',
  titleKo: 'Cricket 4.0+ MPR (20R)',
  titleEn: 'Cricket 4.0+ MPR (20 Rounds)',
  shortDescriptionKo:
  '풀 크리켓 번호를 사용해 20라운드 동안 마크 수를 기록하며 평균 4.0+ MPR을 노리는 드릴',
  shortDescriptionEn:
  'Use full-board cricket numbers for 20 rounds, targeting 4.0+ MPR.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.master,
    maxTier: rating_utils.DaoTrainingTier.master,
  ),
  inputMode: TrainingDrillInputMode.cricketMarks,
  estimatedMinutes: 25,
  recommendedDarts: 20 * 3,
  targetLabel: '20–15 + Bull (20R)',
  guideKo: '20, 19, 18, 17, 16, 15, Bull을 모두 사용하는 크리켓 드릴입니다.\n'
      '각 라운드마다 3다트를 던지고, 그 라운드에서 만든 총 마크 수(예: T20+T19=6마크)를 앱에 입력합니다.\n'
      '20라운드가 끝나면 앱이 자동으로 MPR을 계산하며, 평균 4.0+ MPR을 목표로 합니다.\n'
      '실제 점수나 승패를 신경 쓰지 않고 “3다트당 마크 밀도”에만 집중하는 연습입니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.cricketMarks,
  extraConfig: {
    'cricketNumbers': ['20', '19', '18', '17', '16', '15', 'B'],
    'rounds': 20,
    'targetMprMin': 4.0,
  },
);

// M7.4 Bull 정밀 100발
const TrainingDrillDefinition masterBullPrecision100 = TrainingDrillDefinition(
  id: 'master_bull_precision_100',
  titleKo: 'Bull 정밀 100발',
  titleEn: 'Bull Precision x100',
  shortDescriptionKo:
  'Bull 100발을 던지며 SBull/DBull 비율을 끌어올리는 마스터용 드릴',
  shortDescriptionEn:
  'Throw 100 darts at Bull focusing on SBull/DBull ratio.',
  category: TrainingDrillCategory.bull,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.master,
    maxTier: rating_utils.DaoTrainingTier.master,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 20,
  recommendedDarts: 100,
  targetLabel: 'SBull / DBull (x100)',
  guideKo: 'Bull을 향해 100발을 던지면서, SBull과 DBull을 따로 기록합니다.\n'
      '라운드(3다트)마다 SBull 개수, DBull 개수를 입력해도 되고, 세션 끝에 합계만 입력하는 방식으로 구현해도 됩니다.\n'
      '목표는 SBull+DBull 합 60개 이상, 그 중 DBull 20개 이상을 노려보는 것입니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'targetArea': 'bull_split',
    'totalDarts': 100,
    'targetSbPlusDb': 60,
    'targetDb': 20,
  },
);

const Map<rating_utils.DaoTrainingTier, List<TrainingDrillDefinition>> kTrainingDrillsByTier = {
  rating_utils.DaoTrainingTier.beginner: [
    beginnerQuadrantBasic,
    beginnerTopBottomBasic,
    beginnerAroundTheBoardSingle,
    beginnerLargeSingle20,
    beginnerBigBull,
    beginnerLooseCountUp,
  ],
  rating_utils.DaoTrainingTier.learner: [
    learnerSingle20x100,
    learnerTopBottomAdvanced,
    learner20to19Switch,
    // 추가 learner 드릴들...
  ],
  rating_utils.DaoTrainingTier.competitor: [
    comp20SectorTsd,
    compDoubleClockHalf,
    compCheckout40to80,
    compCricket2019,
    compCountUpHigh20,
    compBullDoubleIntro,
  ],
  rating_utils.DaoTrainingTier.challenger: [
    challCheckout60to100Random,
    // challDoubleClockFull, challT20Focus60 등 추가
  ],
  rating_utils.DaoTrainingTier.elite: [
    // eliteT20Precision60, elite501PressureFinish 등
  ],
  rating_utils.DaoTrainingTier.pro: [
    // pro501Standard18Darts, proT20_100Darts 등
  ],
  rating_utils.DaoTrainingTier.master: [
    // masterT20_120Darts, masterCricket4Mpr20R 등
  ],
};

List<TrainingDrillDefinition> getDrillsForTier(rating_utils.DaoTrainingTier tier) {
  return kTrainingDrillsByTier[tier] ?? [];
}

List<TrainingDrillDefinition> recommendedDrillsForToday(rating_utils.DaoTrainingTier tier) {
  return getDrillsForTier(tier);
}