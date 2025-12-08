// lib/core/constants/training_drill_constants.dart

import 'package:daoapp/core/utils/dao_training_rating_utils.dart'
as rating_utils;
import 'package:daoapp/data/models/training_drill_model.dart';

/// ===============================
/// 1. Beginner (초보자) 드릴
/// ===============================

const TrainingDrillDefinition beginnerQuadrantBasic = TrainingDrillDefinition(
  id: 'beginner_quadrant_basic',
  titleKo: '4분할 감각 만들기',
  titleEn: 'Quadrant Basic',
  shortDescriptionKo:
  '보드를 4구역(우상/우하/좌하/좌상)으로 나눠 방향·거리 감각을 만드는 입문 드릴',
  shortDescriptionEn: 'Build basic feel using 4 board quadrants.',
  category: TrainingDrillCategory.boardMapping,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.beginner,
    maxTier: rating_utils.DaoTrainingTier.beginner,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 15,
  recommendedDarts: 60,
  targetLabel: '우상단 / 우하단 / 좌하단 / 좌상단',
  guideKo:
  '보드를 4색(빨강/노랑/초록/파랑)으로 4구역(우상단/우하단/좌하단/좌상단)으로 나누고, '
      '앱이 지시하는 구역에 3다트를 던집니다. 1색당 5라운드(=15발)씩, 총 4구역 20라운드(=60발)를 진행합니다. '
      '각 라운드마다 해당 구역 안에 들어간 화살 개수(0~3)를 입력하고, 색(15발) 단위로 성공률(%)을 확인하며 '
      '구역별로 얼마나 잘 모이고 있는지 확인하세요.',
  difficulty: DrillDifficulty.veryEasy,
  uiPattern: DrillUIPattern.boardArea,
  extraConfig: {
    'mode': 'quadrant',
    'rounds': 20, // 5R × 4구역 = 20R
    'dartsPerRound': 3, // 총 60발
    'successTarget': 15, // 기준값
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
  estimatedMinutes: 15,
  recommendedDarts: 60, // 상단 30 + 하단 30
  targetLabel: '상단 / 하단',
  guideKo:
  '보드를 상단(예: 빨강) / 하단(예: 노랑) 두 영역으로 나누고, 먼저 상단에만 30발, '
      '그 다음 하단에만 30발을 던집니다. 각 라운드(3다트)마다 목표 영역 안에 들어간 다트 개수(0~3)를 입력하세요. '
      '각 영역 30발 기준으로 총 히트 수와 성공률(%)을 확인하며, 상단/하단 방향 감각을 점검합니다.',
  difficulty: DrillDifficulty.veryEasy,
  uiPattern: DrillUIPattern.boardArea,
  extraConfig: {
    'mode': 'top_bottom',
    'totalDartsPerArea': 30, // 상단 30, 하단 30 → 총 60발
    'dartsPerRound': 3,
    'rounds': 20,
  },
);

const TrainingDrillDefinition beginnerAroundTheBoardSingle =
TrainingDrillDefinition(
  id: 'beginner_around_board_single',
  titleKo: '싱글 한 바퀴',
  titleEn: 'Around the Board Single',
  shortDescriptionKo: '1→20→SB까지 싱글을 한 바퀴 도는 기초 드릴',
  shortDescriptionEn: 'Hit singles 1→20 then SB in order.',
  category: TrainingDrillCategory.boardMapping,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.beginner,
    maxTier: rating_utils.DaoTrainingTier.beginner,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 15,
  recommendedDarts: 60, // 완주 시 대략 60발 전후를 예상
  targetLabel: '1~20 + SB',
  guideKo: '1 → 2 → 3 → … → 20 → SB 순서로 진행하며, 각 숫자를 최소 한 번 맞추면 다음 숫자로 이동합니다. '
      '앱에는 이번 완주에 사용한 총 다트 수만 기록하고, 이전 기록과 비교해 “더 적은 다트로 완주하기”를 목표로 합니다. '
      '완주 기록이 쌓일수록 등급 상승/유지/하락 같은 피드백을 줄 수 있습니다.',
  difficulty: DrillDifficulty.easy,
  uiPattern: DrillUIPattern.boardArea,
  extraConfig: {
    'mode': 'around_board',
    'sequence': [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
      '12',
      '13',
      '14',
      '15',
      '16',
      '17',
      '18',
      '19',
      '20',
      'SB',
    ],
  },
);

const TrainingDrillDefinition beginnerLargeSingle20 = TrainingDrillDefinition(
  id: 'beginner_large_single_20',
  titleKo: 'Large Single 20 입문',
  titleEn: 'Large Single 20 Intro',
  shortDescriptionKo: 'S20 큰 영역에 안정적으로 맞추는 감각을 만드는 입문 스코어링 드릴',
  shortDescriptionEn: 'Focus on the large S20 to build basic control.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.beginner,
    maxTier: rating_utils.DaoTrainingTier.beginner,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 15,
  recommendedDarts: 60,
  targetLabel: 'S20 (싱글 20라인)',
  guideKo:
  '정규 거리 또는 조금 편한 거리에서 S20 큰 영역만 60발 던집니다. '
      '20라운드(3다트 × 20R)로 진행하며, 매 라운드마다 S20 안에 들어간 개수(0~3)를 입력하세요. '
      '세션이 끝나면 60발 기준 성공률(%)을 보고, 예를 들어 30/60(50%) 이상을 1차 목표로 삼습니다.',
  difficulty: DrillDifficulty.easy,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'targetSegment': 'S20',
    'dartsPerRound': 3,
    'rounds': 20, // 총 60발
  },
);

const TrainingDrillDefinition beginnerBigBull = TrainingDrillDefinition(
  id: 'beginner_big_bull',
  titleKo: '빅 Bull 감각',
  titleEn: 'Big Bull Feel',
  shortDescriptionKo: 'Bull 링 전체를 노리며 “그루핑을 중점으로”만드는 드릴',
  shortDescriptionEn: 'Aim at the whole Bull ring to feel the center.',
  category: TrainingDrillCategory.bull,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.beginner,
    maxTier: rating_utils.DaoTrainingTier.beginner,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 15,
  recommendedDarts: 60,
  targetLabel: '전체 Bull ',
  guideKo:
  'BULL 링(SBull+DBull)을 모두 포함하는 큰 원만 노리고 60발을 던집니다. '
      '20라운드(3다트 × 20R) 동안 매 라운드 Bull 링 안에 들어간 개수(0~3)를 입력하세요. '
      '세션 종료 후 총 Bull 히트 수와 성공률(%)을 보고, 예를 들어 10/60 이상을 1차 기준으로 삼아 '
      '점차 목표치를 올려갈 수 있습니다.',
  difficulty: DrillDifficulty.easy,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'targetArea': 'big_bull',
    'dartsPerRound': 3,
    'rounds': 20, // 총 60발
  },
);

const TrainingDrillDefinition beginnerLooseCountUp = TrainingDrillDefinition(
  id: 'beginner_loose_countup_8r',
  titleKo: '느슨한 Count-Up',
  titleEn: 'Loose Count-Up',
  shortDescriptionKo: '점수보다는 “보드에 꽂히는 경험”을 쌓는 가벼운 8R Count-Up',
  shortDescriptionEn:
  'A relaxed 8-round Count-Up to gain throwing experience.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.beginner,
    maxTier: rating_utils.DaoTrainingTier.beginner,
  ),
  inputMode: TrainingDrillInputMode.scoreOnly,
  estimatedMinutes: 5,
  recommendedDarts: 24,
  targetLabel: '8R Count-Up',
  guideKo:
  '일반 8R Count-Up을 1게임 플레이하고 최종 점수만 앱에 입력합니다. '
      '목표는 “점수를 따내기”보다는 “보드에 많이 던져보는 것”입니다. '
      '200점 → 250점 → 300점 순으로 목표 점수를 설정하고, 예를 들어 220점을 기록했다면 '
      '“200 클리어, 다음 목표 250!”처럼 다음 목표를 정해 연습을 이어가세요.',
  difficulty: DrillDifficulty.veryEasy,
  uiPattern: DrillUIPattern.scoreGame,
  extraConfig: {
    'gameType': 'countup',
    'rounds': 8,
    'targetScores': [200, 250, 300],
  },
);

/// ===============================
/// 2. Learner (러너) 드릴
/// ===============================

const TrainingDrillDefinition learnerSingle20x60 = TrainingDrillDefinition(
  id: 'learner_single20_60',
  titleKo: 'Single 20 60발',
  titleEn: 'Single 20 x60',
  shortDescriptionKo: '정규 거리에서 S20만 60발 던지며 명중률을 끌어올리는 드릴',
  shortDescriptionEn: 'Throw 60 darts at S20 from the official distance.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.learner,
    maxTier: rating_utils.DaoTrainingTier.learner,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 15,
  recommendedDarts: 60,
  targetLabel: 'S20',
  guideKo:
  '정규 거리에서 S20만 60발 던집니다. 20라운드(3다트 × 20R)로 진행하면서, '
      '각 라운드마다 S20 안에 들어간 개수(0~3)를 입력하세요. '
      '세션 종료 후 전체 60발 기준 성공률(%)을 보고, 40/60(66.7%) 정도를 1차 목표로 삼습니다. '
      '라운드별 히트 히스토리를 통해 어느 구간에서 집중력이 떨어지는지도 확인할 수 있습니다.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'targetSegment': 'S20',
    'totalDarts': 60,
    'dartsPerRound': 3,
    'rounds': 20,
    'targetHits': 40,
  },
);

const TrainingDrillDefinition learnerTopBottomAdvanced =
TrainingDrillDefinition(
  id: 'learner_top_bottom_advanced',
  titleKo: '상단/하단 컨트롤 심화',
  titleEn: 'Top / Bottom Advanced',
  shortDescriptionKo: 'Beginner 때 만든 상/하 영역 감각을 더 정교하게 다듬는 드릴',
  shortDescriptionEn: 'Refine your top/bottom control with structured reps.',
  category: TrainingDrillCategory.boardMapping,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.learner,
    maxTier: rating_utils.DaoTrainingTier.learner,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 15,
  recommendedDarts: 60,
  targetLabel: '상단 / 하단',
  guideKo:
  'Beginner 단계에서 만들었던 상단/하단 감각을 한 단계 끌어올리는 드릴입니다. '
      '보드를 상단(예: 빨강) / 하단(예: 노랑)으로 나누고, 상단 30발 → 하단 30발을 던집니다. '
      '각 라운드(3다트)마다 목표 영역 안에 들어간 개수(0~3)를 입력하세요. '
      '세션 종료 후 상단 30발 기준 성공률(%), 하단 30발 기준 성공률(%)을 각각 확인하며 '
      '두 영역의 편차를 줄이는 것을 목표로 합니다.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.boardArea,
  extraConfig: {
    'mode': 'top_bottom',
    'totalDartsPerArea': 30,
    'dartsPerRound': 3,
    'rounds': 20,
  },
);

const TrainingDrillDefinition learner20to19Switch = TrainingDrillDefinition(
  id: 'learner_20_19_switch',
  titleKo: '상단 3섹터 루프 (20/19/18)',
  titleEn: 'Top 3 Sectors Loop (20/19/18)',
  shortDescriptionKo: '20/19/18 상단 구역을 돌면서 빅미스를 줄이는 연습',
  shortDescriptionEn: 'Loop through 20/19/18 to reduce big misses.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.learner,
    maxTier: rating_utils.DaoTrainingTier.learner,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 15,
  recommendedDarts: 60, // 60발: 섹터당 20발 정도
  targetLabel: '20 / 19 / 18',
  guideKo:
  '20, 19, 18 상단 세 구역을 차례대로(20 → 19 → 18 → 20 → …) 돌면서 총 60다트를 던집니다. '
      '각 다트마다 현재 타겟에 맞으면 성공으로 기록하고, 1/5 같은 빅 넘버로 새는 비율을 줄이는 것이 목표입니다.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'segments': ['20', '19', '18'],
    'totalDarts': 60,
  },
);

const TrainingDrillDefinition learner17to15Line = TrainingDrillDefinition(
  id: 'learner_17_16_15_line',
  titleKo: '중단 3섹터 루프 (17/16/15)',
  titleEn: 'Middle 3 Sectors Loop (17/16/15)',
  shortDescriptionKo: '17/16/15 라인에서 스코어링과 빅미스 감소 연습',
  shortDescriptionEn:
  'Practice scoring on 17/16/15 while reducing big misses.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.learner,
    maxTier: rating_utils.DaoTrainingTier.learner,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 15,
  recommendedDarts: 60,
  targetLabel: '17 / 16 / 15',
  guideKo:
  '17, 16, 15 세 구역을 차례대로(17 → 16 → 15 → 17 → …) 돌면서 총 60다트를 던집니다. '
      '각 다트마다 현재 타겟에 맞으면 성공으로 기록하고, 빅 넘버나 바깥으로 새는 비율을 줄이는 것이 목표입니다.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'segments': ['17', '16', '15'],
    'totalDarts': 60,
  },
);

/// 러너용 8R Count-Up (티어 밴드: 350~549)
const TrainingDrillDefinition learnerStandardCountUp8r =
TrainingDrillDefinition(
  id: 'learner_countup_8r_standard',
  titleKo: '러너 기준 Count-Up 8R',
  titleEn: 'Learner Standard Count-Up 8R',
  shortDescriptionKo: '8R Count-Up에서 350~500점 구간을 목표로 하는 러너용 드릴',
  shortDescriptionEn:
  '8-round Count-Up drill targeting scores in the 350–500 range.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.learner,
    maxTier: rating_utils.DaoTrainingTier.learner,
  ),
  inputMode: TrainingDrillInputMode.scoreOnly,
  estimatedMinutes: 8,
  recommendedDarts: 24,
  targetLabel: '8R Count-Up (러너 구간)',
  guideKo:
  '일반 8라운드 Count-Up을 1게임 플레이한 뒤, 최종 점수만 앱에 입력하는 드릴입니다. '
      '러너 구간(350~549점)을 기준으로, 350점 → 400점 → 450점 → 500점 순으로 단계 목표를 잡습니다. '
      '예를 들어 380점을 기록했다면 “350 클리어, 다음 목표 400!”처럼 다음 목표를 정해 연습을 이어가세요.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.scoreGame,
  extraConfig: {
    'gameType': 'countup',
    'rounds': 8,
    'targetScores': [350, 400, 450, 500],
  },
);

/// ===============================
/// 3. Competitor (컴페티터) 드릴
/// ===============================

const TrainingDrillDefinition compTriple201918 = TrainingDrillDefinition(
  id: 'comp_triple_20_19_18_line',
  titleKo: '트리플 루프 (T20/T19/T18)',
  titleEn: 'Top Triple Loop (T20/T19/T18)',
  shortDescriptionKo: 'T20 → T19 → T18 트리플 영역을 순환하며 스코어링 전환 리듬을 만드는 연습',
  shortDescriptionEn:
  'Loop T20 → T19 → T18 to stabilize scoring transitions.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.competitor,
    maxTier: rating_utils.DaoTrainingTier.competitor,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 12,
  recommendedDarts: 60, // 20발 × 3섹터
  targetLabel: 'T20 / T19 / T18',
  guideKo:
  'T20 → T19 → T18 순서로 반복하여 총 60발을 던집니다. '
      '각 다트마다 명중 여부(0/1)를 입력하며, 트리플 라인 스위칭 시 리듬을 유지하는 것이 핵심입니다. '
      '끝나면 각 트리플 성공률을 비교하여 본인의 강점과 약점을 파악하세요.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'segments': ['T20', 'T19', 'T18'], // 🔥 수정됨
    'totalDarts': 60,
    'loopSize': 3,
  },
);

const TrainingDrillDefinition compDoubleClockHalf = TrainingDrillDefinition(
  id: 'comp_double_clock_half',
  titleKo: '더블 시계 전반부 (D1~D10)',
  titleEn: 'Double Clock Front (D1–D10)',
  shortDescriptionKo: 'D1~D10까지 반 시계를 돌면서 더블 감각을 올리는 드릴',
  shortDescriptionEn: 'Practice doubles from D1 to D10 with limited attempts.',
  category: TrainingDrillCategory.doublePractice,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.competitor,
    maxTier: rating_utils.DaoTrainingTier.competitor,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 15,
  recommendedDarts: 50,
  targetLabel: 'D1 ~ D10',
  guideKo:
  'D1 → D2 → … → D10 순서로 진행하는 전반부 더블 시계입니다. '
      '각 더블마다 3발을 던지고, 맞으면 다음 번호로 이동합니다. '
      '앱에서는 “3발 던지고 돌아와서 이번 더블을 몇 번째 세트만에 성공했는지”를 기록합니다. '
      '전체 사용 세트/다트 수를 줄여가는 것이 목표이며, '
      '가능하면 각 더블을 5세트(=15다트) 이내에 마무리하는 기준을 잡을 수 있습니다.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'doubleSequence': [
      'D1',
      'D2',
      'D3',
      'D4',
      'D5',
      'D6',
      'D7',
      'D8',
      'D9',
      'D10'
    ],
    'maxDartsPerDouble': 15,
    'dartsPerSet': 3,
  },
);

const TrainingDrillDefinition compDoubleClockBack = TrainingDrillDefinition(
  id: 'comp_double_clock_back',
  titleKo: '더블 시계 후반부 (D11~D20)',
  titleEn: 'Double Clock Back (D11–D20)',
  shortDescriptionKo: 'D11~D20까지 후반부 더블을 집중 연습하는 드릴',
  shortDescriptionEn:
  'Practice doubles from D11 to D20 with structured sets.',
  category: TrainingDrillCategory.doublePractice,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.competitor,
    maxTier: rating_utils.DaoTrainingTier.competitor,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 15,
  recommendedDarts: 50,
  targetLabel: 'D11 ~ D20',
  guideKo:
  'D11 → D12 → … → D20 순서로 진행하는 후반부 더블 시계입니다. '
      '역시 각 더블마다 3발을 던지고, 맞으면 다음 숫자로 이동합니다. '
      '3발 던진 후 앱으로 돌아와 “이번 더블을 몇 번째 세트에서 성공했는지” 버튼으로 기록하세요. '
      '전체 사용 세트/다트 수를 기록해서, 전반부(D1~D10)와 비교하며 약한 구간을 찾아가는 데 활용합니다.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'doubleSequence': [
      'D11',
      'D12',
      'D13',
      'D14',
      'D15',
      'D16',
      'D17',
      'D18',
      'D19',
      'D20'
    ],
    'maxDartsPerDouble': 15,
    'dartsPerSet': 3,
  },
);

const TrainingDrillDefinition compCheckout40to80 = TrainingDrillDefinition(
  id: 'comp_checkout_40_80',
  titleKo: '40–80 더블 아웃 필수 구간',
  titleEn: '40–80 Double-Out Essentials',
  shortDescriptionKo: '40~80 점수대를 더블로 마무리하는 필수 체크아웃 드릴',
  shortDescriptionEn:
  'Practice finishing 40–80 scores via doubles within 6 darts.',
  category: TrainingDrillCategory.finish,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.competitor,
    maxTier: rating_utils.DaoTrainingTier.competitor,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 20,
  recommendedDarts: 60,
  targetLabel: '40~80 Double-Out',
  guideKo:
  '40~80 점수대를 최대 3다트 안에 더블 아웃으로 마무리하는 실전형 드릴입니다. '
      '각 세트마다 랜덤 점수가 주어지고, 실제로 점수를 입력하면서 연습합니다. '
      '총 20세트 진행 후 성공률을 확인하세요!',
  difficulty: DrillDifficulty.hard,
  uiPattern: DrillUIPattern.checkoutRoute,
  extraConfig: {
    'mode': 'checkout_practice', // 이게 핵심!
    'minScore': 40,
    'maxScore': 80,
    'maxDartsPerSet': 3, // 3다트 제한
    'totalSets': 20,
    'requireDoubleOut': true,
  },
);

const TrainingDrillDefinition compCricket2019 = TrainingDrillDefinition(
  id: 'comp_cricket_20_19',
  titleKo: '크리켓 20↔19 실전 훈련',
  titleEn: 'Cricket 20↔19 Real Training',
  shortDescriptionKo: '20과 19만 번갈아 던지며 실전 MPR 2.0+을 노리는 집중 드릴',
  shortDescriptionEn:
  'Alternate between 20 and 19 for real-game MPR training.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.competitor,
    maxTier: rating_utils.DaoTrainingTier.competitor,
  ),
  inputMode: TrainingDrillInputMode.cricketMarks,
  estimatedMinutes: 10, // ← 15분 → 10분 (8라운드라 더 짧음)
  recommendedDarts: 24, // ← 45 → 24 (8R × 3다트)
  targetLabel: '20 ↔ 19 (8R 실전)',
  guideKo: '실전 크리켓에서 가장 중요한 20과 19만 집중 훈련하는 8라운드 드릴입니다.\n\n'
      '• 1~7라운드: 20 → 19 → 20 → 19 → 20 → 19 → 20 순서 강제\n'
      '• 8라운드: 20 또는 19 중 약한 쪽 자유 선택\n\n'
      '각 라운드마다 3다트로 만든 마크 수를 입력하면 실시간 MPR이 표시됩니다.\n\n'
      '목표: 평균 MPR 2.0 이상!\n'
      '2.0 미만이면 20/19 마크 밀도가 부족하다는 뜻!',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.cricketMarks,
  extraConfig: {
    // 이제 패널이 알아서 8라운드로 고정 + 20/19 번갈아가며 처리하니까
    // extraConfig 거의 필요 없음!
  },
);

/// 컴페티터용 8R Count-Up (티어 밴드: 550~649)
const TrainingDrillDefinition compCountUpHigh20 = TrainingDrillDefinition(
  id: 'comp_countup_high20', // 🔹 id는 그대로 두고 내용만 변경
  titleKo: '컴페티터 기준 Count-Up 8R',
  titleEn: 'Competitor Standard Count-Up 8R',
  shortDescriptionKo: '8R Count-Up에서 550~650점 구간을 노리는 컴페티터용 드릴',
  shortDescriptionEn:
  '8-round Count-Up drill targeting scores in the 550–650 range.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.competitor,
    maxTier: rating_utils.DaoTrainingTier.challenger,
  ),
  inputMode: TrainingDrillInputMode.scoreOnly,
  estimatedMinutes: 8,
  recommendedDarts: 24,
  targetLabel: '8R Count-Up (컴페티터 구간)',
  guideKo:
  '일반 8라운드 Count-Up을 1게임 플레이한 뒤, 최종 점수만 앱에 입력하는 드릴입니다. '
      '컴페티터 구간(550~649점)을 기준으로, 550점 → 600점 → 650점 순으로 단계 목표를 잡습니다. '
      '예를 들어 580점을 기록했다면 “550 클리어, 다음 목표 600!”처럼 다음 목표를 정해 연습을 이어가세요.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.scoreGame,
  extraConfig: {
    'gameType': 'countup',       // ✅ 일반 Count-Up
    'rounds': 8,
    'targetScores': [550, 600, 650],
  },
);

const TrainingDrillDefinition compBullDoubleIntro = TrainingDrillDefinition(
  id: 'comp_bull_double_intro',
  titleKo: 'Bull 더블 입문',
  titleEn: 'Bull Double Intro',
  shortDescriptionKo: 'Bull 60발 중 SBull/DBull을 나누어 기록하는 상급 입문 드릴',
  shortDescriptionEn:
  'Shoot 60 darts at Bull and track SBull/DBull separately.',
  category: TrainingDrillCategory.bull,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.competitor,
    maxTier: rating_utils.DaoTrainingTier.competitor,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 10,
  recommendedDarts: 60,
  targetLabel: 'SBull / DBull',
  guideKo:
  'Bull을 향해 60발을 던지며, SBull과 DBull을 따로 기록하는 드릴입니다. '
      '세션 동안 SBull을 맞출 때마다 S 버튼, DBull을 맞출 때마다 D 버튼으로 개수를 올려 주세요. '
      '세션 종료 후 SBull+DBull 합과 DBull 개수를 기준치와 비교하며, '
      'SBull+DBull 20개 이상, DBull 5개 이상을 1차 목표로 합니다.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'targetArea': 'bull_split',
    'totalDarts': 60,
    'targetSbPlusDb': 20,
    'targetDb': 5,
  },
);

/// ===============================
/// 4. Challenger (챌린저) 드릴
/// ===============================

const TrainingDrillDefinition challCheckout60to100Random =
TrainingDrillDefinition(
  id: 'chall_checkout_60_100_random',
  titleKo: '60~100 랜덤 체크아웃',
  titleEn: 'Random Checkout 60–100',
  shortDescriptionKo: '60~100 점수대를 랜덤으로 받아 더블 아웃 성공률을 끌어올리는 드릴',
  shortDescriptionEn:
  'Randomly practice double-out finishes between 60 and 100.',
  category: TrainingDrillCategory.finish,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.challenger,
    maxTier: rating_utils.DaoTrainingTier.challenger,
  ),
  inputMode: TrainingDrillInputMode.hitCount, // ✅ 세트 성공/실패 카운트에 잘 맞는 모드
  estimatedMinutes: 25,
  recommendedDarts: 180, // (참고용, 실제 진행은 totalSets 기준)
  targetLabel: '60~100 Double-Out (랜덤)',
  guideKo:
  '60~100 사이 점수를 랜덤으로 받아 최대 6다트 안에 더블 아웃을 시도합니다. '
      '실제로 점수를 입력하면서 남은 점수를 보고 연습하는 실전형 드릴입니다. '
      '총 30세트 진행 후 성공률을 확인하세요!',
  difficulty: DrillDifficulty.hard,
  uiPattern: DrillUIPattern.checkoutRoute,
  extraConfig: {
    'mode': 'checkout_practice', // ✅ 여기 때문에 CheckoutPracticePanel로 연결됨
    'minScore': 60,
    'maxScore': 100,
    'maxDartsPerSet': 6,
    'totalSets': 30,
    'requireDoubleOut': true,
  },
);

const TrainingDrillDefinition challDoubleClockFull = TrainingDrillDefinition(
  id: 'chall_double_clock_full',
  titleKo: '더블 시계 풀 (D1~D20 + DBull)',
  titleEn: 'Full Double Clock (D1–D20 + DBull)',
  shortDescriptionKo: 'D1~D20 + DBull 전체 더블 시계를 완주하는 챌린저 필수 드릴',
  shortDescriptionEn:
  'Complete the full double clock from D1 to D20 plus DBull.',
  category: TrainingDrillCategory.doublePractice,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.challenger,
    maxTier: rating_utils.DaoTrainingTier.challenger,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 30,
  recommendedDarts: 120,
  targetLabel: 'D1~D20 + DBull',
  guideKo:
  'D1 → D2 → … → D20 → DBull 순서로 진행하는 풀 더블 시계입니다. '
      '각 더블마다 3다트를 던지고, 맞추면 다음 번호로 이동합니다. '
      '3발을 던지고 돌아와 “이번 더블을 몇 번째 세트에서 성공했는지”를 앱에 기록하세요. '
      '전체 D1~DBull을 완주하는 데 들어간 총 세트 수/다트 수를 시각화해 주며, '
      '여러 날로 나누어(suggestSplitDays) 완주를 노리는 장기 프로젝트형 드릴로 사용할 수 있습니다.',
  difficulty: DrillDifficulty.hard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'doubleSequence': [
      'D1',
      'D2',
      'D3',
      'D4',
      'D5',
      'D6',
      'D7',
      'D8',
      'D9',
      'D10',
      'D11',
      'D12',
      'D13',
      'D14',
      'D15',
      'D16',
      'D17',
      'D18',
      'D19',
      'D20',
      'DBULL',
    ],
    'maxDartsPerDouble': 6,
    'dartsPerSet': 3,
    'suggestSplitDays': true,
  },
);

const TrainingDrillDefinition challT20Focus60 = TrainingDrillDefinition(
  id: 'chall_t20_focus_60',
  titleKo: 'T20 집중 60발',
  titleEn: 'T20 Focus 60 Darts',
  shortDescriptionKo: 'T20 60발에서 15개(25%) 이상을 노리는 챌린저 스코어링 드릴',
  shortDescriptionEn:
  'Throw 60 darts at T20 aiming for 25%+ hit rate.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.challenger,
    maxTier: rating_utils.DaoTrainingTier.challenger,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 12,
  recommendedDarts: 60,
  targetLabel: 'T20 (60발)',
  guideKo:
  'T20만 노리고 총 60발(3다트 × 20라운드)을 던지는 드릴입니다. '
      '각 라운드마다 T20에 들어간 개수(0~3)를 입력하고, '
      '세션 종료 후 전체 T20 히트 수와 성공률(%)을 확인합니다. '
      '60발 중 15개(=25%) 이상을 1차 목표로 삼고, 익숙해지면 20개 이상을 도전 목표로 잡을 수 있습니다.',
  difficulty: DrillDifficulty.hard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'segments': ['T20'],
    'totalDarts': 60,
    'dartsPerRound': 3,
    'rounds': 20,
    'targetHits': 15,
  },
);

const TrainingDrillDefinition challCricketFull = TrainingDrillDefinition(
  id: 'chall_cricket_full_20_15_bull',
  titleKo: '크리켓 8R 실전 훈련',
  titleEn: 'Cricket 8R Real Training',
  shortDescriptionKo: '20→Bull 순서 + 마지막 자유 라운드로 실전 MPR을 끌어올리는 드릴',
  shortDescriptionEn:
  '7 fixed rounds + 1 free round to build real cricket MPR.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.challenger,
    maxTier: rating_utils.DaoTrainingTier.challenger,
  ),
  inputMode: TrainingDrillInputMode.cricketMarks,
  estimatedMinutes: 10, // ← 15분 → 10분으로 변경 (8R이라 더 짧음)
  recommendedDarts: 24, // ← 45 → 24로 변경 (8R × 3다트)
  targetLabel: 'Cricket 8R (20→Bull + 자유)',
  guideKo: '실전과 똑같은 8라운드 크리켓 훈련입니다.\n\n'
      '• 1~7라운드: 20 → 19 → 18 → 17 → 16 → 15 → Bull 순서로 강제 진행\n'
      '• 8라운드: 원하는 숫자 자유 선택 (약점 보완)\n'
      '각 라운드마다 3다트로 만든 마크 수를 입력하면 실시간 MPR이 계산됩니다.\n\n'
      '목표: 평균 MPR 2.4 이상!',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.cricketMarks,
  extraConfig: {
    // 패널이 8R 고정 처리
  },
);

const TrainingDrillDefinition challCountup700 = TrainingDrillDefinition(
  id: 'chall_countup_700',
  titleKo: 'Count-Up 700 도전',
  titleEn: 'Count-Up 700 Challenge',
  shortDescriptionKo: '8R Count-Up에서 650 → 700 → 720 단계 목표에 도전하는 드릴',
  shortDescriptionEn:
  '8-round Count-Up aiming for 650, then 700, then 720.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.challenger,
    maxTier: rating_utils.DaoTrainingTier.elite,
  ),
  inputMode: TrainingDrillInputMode.scoreOnly,
  estimatedMinutes: 8,
  recommendedDarts: 24,
  targetLabel: '8R Count-Up (700 목표)',
  guideKo:
  '일반 8라운드 Count-Up을 1게임 플레이한 뒤, 최종 점수만 앱에 입력하는 드릴입니다. '
      '앱은 점수가 650 / 700 / 720 중 어느 구간에 해당하는지 보여주고, '
      '이전 세션과 비교해 성장 추세를 시각화합니다. '
      '먼저 650점을 안정적으로 넘기는 것을 목표로 하고, 이후 700점, 720점까지 단계적으로 도전합니다.',
  difficulty: DrillDifficulty.normal,
  uiPattern: DrillUIPattern.scoreGame,
  extraConfig: {
    'gameType': 'countup',
    'rounds': 8,
    'milestones': [650, 700, 720],
  },
);

/// ===============================
/// 5. Elite (엘리트) 드릴
/// ===============================

const TrainingDrillDefinition eliteT20Precision60 = TrainingDrillDefinition(
  id: 'elite_t20_precision_60',
  titleKo: 'T20 정밀 60발',
  titleEn: 'T20 Precision 60',
  shortDescriptionKo: 'T20만 60발 던져 33% 이상 트리플 성공률을 노리는 정밀 스코어링 드릴',
  shortDescriptionEn:
  'Throw 60 darts at T20 aiming for 33%+ triple hit rate.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.elite,
    maxTier: rating_utils.DaoTrainingTier.elite,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 12,
  recommendedDarts: 60,
  targetLabel: 'T20 (60발)',
  guideKo:
  'T20만 노리고 총 60발(3다트 × 20라운드)을 던지는 정밀 드릴입니다. '
      '각 라운드마다 T20에 들어간 개수(0~3)를 입력하고, 세션 종료 후 전체 T20 히트 수를 기준으로 성공률(%)을 확인합니다. '
      '60발 중 20개 미만이면 “목표 미달”, 20~24개면 “목표 성공(33~40%)”, 25개 이상이면 “하이 레벨”로 볼 수 있습니다.',
  difficulty: DrillDifficulty.hard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'segments': ['T20'],
    'totalDarts': 60,
    'rounds': 20,
    'dartsPerRound': 3,
    'targetHits': 20,
  },
);

const TrainingDrillDefinition eliteT20T19TripleSwitch =
TrainingDrillDefinition(
  id: 'elite_t20_t19_triple_switch',
  titleKo: 'T20/T19/T18 트리플 루프',
  titleEn: 'T20–T19–T18 Triple Loop',
  shortDescriptionKo:
  'T20 → T19 → T18을 반복하며 상단 트리플 3구역을 동시에 끌어올리는 엘리트용 드릴',
  shortDescriptionEn:
  'Elite triple loop drill cycling through T20, T19 and T18 to balance high scoring.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.elite,
    maxTier: rating_utils.DaoTrainingTier.elite,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 18,
  recommendedDarts: 90,
  targetLabel: 'T20 / T19 / T18 트리플',
  guideKo:
  'T20, T19, T18 세 트리플을 순서대로 노리며 상단 스코어링 밸런스를 맞추는 엘리트용 드릴입니다.\n\n'
      '• 1세트 = 3다트\n'
      '  ‣ 1발째: T20 트리플\n'
      '  ‣ 2발째: T19 트리플\n'
      '  ‣ 3발째: T18 트리플\n\n'
      '이 패턴으로 총 30세트(= 90발)를 진행하면서, 각 다트가 해당 타겟 트리플에 들어가면 성공으로 기록합니다.\n'
      '세션이 끝난 뒤, 기록된 총 트리플 개수(T20+T19+T18)를 기준으로\n'
      '• 30개 미만  → “목표 미달(세트당 1개 이하)”\n'
      '• 30~40개    → “엘리트 기준 도달(세트당 평균 1.0~1.3개)”\n'
      '• 40개 이상  → “상위 엘리트 존”\n'
      '같은 피드백을 줄 수 있습니다.',
  difficulty: DrillDifficulty.hard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'patternDescription': '1발 T20, 2발 T19, 3발 T18',
    'segments': ['T20', 'T19', 'T18'],
    'sets': 30,
    'dartsPerSet': 3,
    'totalDarts': 90,
    'targetTotalTriples': 30,
  },
);

const TrainingDrillDefinition eliteCheckout61to120 = TrainingDrillDefinition(
  id: 'elite_checkout_61_120',
  titleKo: '61~120 핵심 체크아웃',
  titleEn: 'Key Checkouts 61–120',
  shortDescriptionKo:
  '61~120 점수대에서 6다트 안에 마무리하는 실전 피니시 감각 드릴',
  shortDescriptionEn:
  'Random double-out finish practice for scores between 61 and 120.',
  category: TrainingDrillCategory.finish,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.elite,
    maxTier: rating_utils.DaoTrainingTier.elite,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 25,
  recommendedDarts: 180, // 6다트 × 30세트 기준으로 맞춰도 되고
  targetLabel: '61~120 Double-Out (랜덤)',
  guideKo:
  '각 세트 시작 시 앱이 61~120 사이 점수를 랜덤으로 제시합니다. '
      '플레이어는 최대 6다트 안에 Double-Out을 시도하고, 세트별로 성공/실패를 기록합니다. '
      '30세트 진행 후 전체 성공 세트 수와 성공률(%)을 확인하며, 성공률 40% 근처에 도달하면 '
      '“엘리트 타겟 도달” 기준으로 삼을 수 있습니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.checkoutRoute,
  extraConfig: {
    'mode': 'checkout_practice',   // ✅ CheckoutPracticePanel 타도록 통일
    'minScore': 61,
    'maxScore': 120,
    'maxDartsPerSet': 6,           // ✅ 패널 파라미터 이름에 맞춤
    'totalSets': 30,
    'requireDoubleOut': true,
    'targetSuccessRate': 0.4,      // 🔹 나중에 결과 분석에서 쓰고 싶으면 남겨둬도 됨
  },
);

const TrainingDrillDefinition eliteDoubleClusterD16D20 =
TrainingDrillDefinition(
  id: 'elite_double_cluster_d16_d20',
  titleKo: 'D16 & D20 더블 클러스터',
  titleEn: 'D16 & D20 Double Cluster',
  shortDescriptionKo:
  '실전에서 가장 자주 쓰는 D16, D20 더블을 각각 60발씩 집중 연습하는 드릴',
  shortDescriptionEn:
  'Intensive double practice focusing on D16 and D20 (60 darts each).',
  category: TrainingDrillCategory.doublePractice,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.elite,
    maxTier: rating_utils.DaoTrainingTier.elite,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 20,
  recommendedDarts: 120,
  targetLabel: 'D16 / D20 (각 60발)',
  guideKo:
  '먼저 D16만 60발(3다트 × 20라운드)을 던지며, 각 라운드마다 D16에 들어간 개수(0~3)를 입력합니다. '
      '이후 D20만 60발을 같은 방식으로 진행합니다. 각 번호별로 총 맞춘 개수 / 60으로 성공률(%)을 계산하고, '
      'D16, D20 각각 20개 이상(33% 이상)을 1차 목표로 삼습니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'segments': ['D16', 'D20'],
    'dartsPerSegment': 60,
    'totalDarts': 120,
    'targetHitsPerSegment': 20,
    'dartsPerRound': 3,
    'roundsPerSegment': 20,
  },
);

const TrainingDrillDefinition eliteCricketPowerMarks15r =
TrainingDrillDefinition(
  id: 'elite_cricket_power_marks_15r',
  titleKo: 'Cricket 파워 8R (마크 드릴)',
  titleEn: 'Cricket Power 8R (Marks)',
  shortDescriptionKo:
  '풀 크리켓(20~15 + Bull)에서 MPR 2.8~3.0 수준을 노리는 엘리트용 8R 마크 드릴',
  shortDescriptionEn:
  'Full-board cricket marks drill (8 rounds) aiming for 2.8–3.0 MPR.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.elite,
    maxTier: rating_utils.DaoTrainingTier.elite,
  ),
  inputMode: TrainingDrillInputMode.cricketMarks,
  estimatedMinutes: 10, // 15 → 10 (8R라 더 짧게)
  recommendedDarts: 24, // 45 → 24 (8R × 3다트)
  targetLabel: 'Full Cricket (8R, MPR 2.8~3.0)',
  guideKo:
  '20, 19, 18, 17, 16, 15, Bull을 모두 사용하는 풀 보드 크리켓을 8라운드 진행합니다. '
      '각 라운드가 끝날 때 이번 3다트로 만든 총 마크 수(0~9)를 입력하면, 앱이 평균 MPR을 자동으로 계산합니다. '
      '평균 2.8~3.0 구간이면 “엘리트 파워 마크 유지 중”, 2.8 미만이면 “마크 밀도 보완 필요”와 같은 피드백을 줄 수 있습니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.cricketMarks,
  extraConfig: {
    'cricketNumbers': ['20', '19', '18', '17', '16', '15', 'Bull'],
    'rounds': 8, // 15 → 8
    'targetMprMin': 2.8,
    'targetMprMax': 3.0,
  },
);

/// 엘리트용 8R Count-Up (티어 밴드: 750~899)
const TrainingDrillDefinition eliteCountUp8r = TrainingDrillDefinition(
  id: 'elite_countup_8r',
  titleKo: '엘리트 Count-Up 8R',
  titleEn: 'Elite Count-Up 8R',
  shortDescriptionKo: '8R Count-Up에서 750~880점대를 노리는 엘리트용 드릴',
  shortDescriptionEn:
  '8-round Count-Up drill targeting 750–880 points for elite players.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.elite,
    maxTier: rating_utils.DaoTrainingTier.elite,
  ),
  inputMode: TrainingDrillInputMode.scoreOnly,
  estimatedMinutes: 8,
  recommendedDarts: 24,
  targetLabel: '8R Count-Up (엘리트 구간)',
  guideKo:
  '일반 8라운드 Count-Up을 1게임 플레이하고, 최종 점수만 앱에 입력하는 드릴입니다. '
      '엘리트 구간(750~899점) 기준으로, 750점 → 820점 → 880점 같은 단계 목표를 제공합니다. '
      '이전 기록과 비교하여 “엘리트 구간 유지/이탈/상승” 같은 피드백을 확인할 수 있습니다.',
  difficulty: DrillDifficulty.hard,
  uiPattern: DrillUIPattern.scoreGame,
  extraConfig: {
    'gameType': 'countup',
    'rounds': 8,
    'milestones': [750, 820, 880],
  },
);

/// ===============================
/// 6. Pro (프로) 드릴
/// ===============================

const TrainingDrillDefinition pro501Standard18darts = TrainingDrillDefinition(
  id: 'pro_501_standard_18darts',
  titleKo: '501 Double-Out 18다트 스탠다드',
  titleEn: '501 Double-Out 18 Darts Standard',
  shortDescriptionKo:
  'T20 중심 스코어링으로 18다트 이내 501 마무리가 가능한지 체크하는 기준 드릴',
  shortDescriptionEn:
  'Check if you can finish 501 within 18 darts using mainly T20 scoring.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.pro,
    maxTier: rating_utils.DaoTrainingTier.pro,
  ),
  inputMode: TrainingDrillInputMode.scoreOnly,
  estimatedMinutes: 25,
  recommendedDarts: 180,
  targetLabel: '501 Double-Out (18다트 기준)',
  guideKo:
  '1세트 = 501 Double-Out 입니다. 각 set가 끝난 뒤, 사용한 총 다트 수만 앱에 입력합니다. '
      '18다트 이하면 “성공”, 19다트 이상이면 “실패”로 기록하며, 총 10세트를 진행합니다. '
      '세션 종료 후 18다트 이내 완주 비율(예: 5/10 = 50%)을 확인하여, 프로 기준 달성 여부를 체크합니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.scoreGame,
  extraConfig: {
    // 🔹 멀티 세트 501 모드 플래그
    'gameType': '501_multi_18darts',

    // 🔹 세트 수 / 다트 수 설정
    'totalSets': 10,          // 총 10 leg
    'minDartsPerLeg': 9,      // 이론상 최소 (9다트)
    'maxDartsPerLeg': 30,     // 최대 허용 입력값

    // 🔹 18다트 이내면 "성공 세트"
    'successThresholdDarts': 18,
  },
);


const TrainingDrillDefinition proT20_90Darts = TrainingDrillDefinition(
  id: 'pro_t20_90_darts',
  titleKo: 'T20 집중 90발',
  titleEn: 'T20 Focus 90 Darts',
  shortDescriptionKo:
  'T20 90발에서 트리플 성공률 40%를 목표로 하는 프로용 스코어링 드릴',
  shortDescriptionEn:
  'Throw 90 darts at T20 aiming for 40% triple hit rate.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.pro,
    maxTier: rating_utils.DaoTrainingTier.pro,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 18,
  recommendedDarts: 90,
  targetLabel: 'T20 (90발)',
  guideKo:
  'T20만 향해 총 90발을 던지는 드릴입니다. 실제 플레이에서는 라운드 구조에 상관없이, '
      '세션을 마친 뒤 T20에 들어간 총 개수만 입력해도 됩니다. '
      '앱은 T20 히트 수 / 90으로 성공률(%)을 계산하며, 40% 이상이면 “프로 스탠다드 달성”으로 봅니다. '
      '원한다면 30라운드(3다트 × 30R)로 나누어 라운드별 T20 히트 수를 기록하는 방식도 선택할 수 있습니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'segments': ['T20'],
    'totalDarts': 90,
    'targetHits': 40,
    'optionalRounds': 30,
    'dartsPerRound': 3,
  },
);

const TrainingDrillDefinition proHighFinishSet8 = TrainingDrillDefinition(
  id: 'pro_high_finish_set_8',
  titleKo: '대표 하이 피니시 8개 세트',
  titleEn: 'High Finish Set of 8',
  shortDescriptionKo:
  '170, 167, 164, 161, 160, 158, 157, 153 하이 피니시 루트를 몸에 익히는 드릴',
  shortDescriptionEn:
  'Practice 8 representative high finishes (170, 167, 164, 161, 160, 158, 157, 153).',
  category: TrainingDrillCategory.finish,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.pro,
    maxTier: rating_utils.DaoTrainingTier.pro,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 25,
  recommendedDarts: 120, // 40세트 × 3다트 = 120
  targetLabel: '하이 피니시 8종 (각 5세트)',
  guideKo:
  '170, 167, 164, 161, 160, 158, 157, 153 총 8가지 대표 하이 피니시를 다룹니다. '
      '각 점수별로 5세트씩, 총 40세트를 진행하며 세트당 3다트 안에 설정한 루트(T20/T19 기반)대로 마무리하면 성공, '
      '못 끝내면 실패로 기록합니다. 세션 종료 후 성공 세트 수 / 40으로 성공률(%)을 확인하며, '
      '10~20%만 나와도 이미 상당히 높은 수준이라는 안내 텍스트를 함께 보여줄 수 있습니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.checkoutRoute,
  extraConfig: {
    // 🔹 여기부터 CheckoutPracticePanel과 맞춰주는 핵심 설정

    // 👉 DrillRunScreen에서 mode == 'checkout_practice' 분기로 태움
    'mode': 'checkout_practice',

    // 👉 CheckoutPracticePanel에 직접 전달되는 값들
    'minScore': 153,
    'maxScore': 170,
    'totalSets': 40,        // 8점수 × 5세트 = 40세트
    'maxDartsPerSet': 3,
    'requireDoubleOut': true,

    // 👉 메타 정보(지금 패널은 안 쓰지만, 나중에 확장할 때 참고 가능)
    'scores': [170, 167, 164, 161, 160, 158, 157, 153],
    'setsPerScore': 5,

    'hintTargetSuccessRateMin': 0.1,
    'hintTargetSuccessRateMax': 0.2,
  },
);


const TrainingDrillDefinition proCricketHighMpr15r = TrainingDrillDefinition(
  id: 'pro_cricket_high_mpr_marks_15r',
  titleKo: 'Cricket 상위 MPR 8R',
  titleEn: 'High MPR Cricket 8R',
  shortDescriptionKo:
  '풀 크리켓에서 MPR 3.4~3.8 수준을 겨냥하는 프로용 8R 마크 드릴',
  shortDescriptionEn:
  'Full-board cricket marks drill (8 rounds) aiming for 3.4–3.8 MPR.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.pro,
    maxTier: rating_utils.DaoTrainingTier.pro,
  ),
  inputMode: TrainingDrillInputMode.cricketMarks,
  estimatedMinutes: 10,
  recommendedDarts: 24,
  targetLabel: 'Full Cricket (8R, MPR 3.4~3.8)',
  guideKo:
  '20, 19, 18, 17, 16, 15, Bull을 모두 사용하는 풀 크리켓을 8라운드 진행합니다. '
      '각 라운드가 끝날 때 이번 3다트로 만든 총 마크 수(0~9)를 입력하면, 앱이 평균 MPR을 자동 계산합니다. '
      '평균 3.4~3.8 구간이면 “프로 기준 달성”, 그보다 낮으면 어느 정도 마크 밀도가 부족한지 확인하는 지표로 활용할 수 있습니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.cricketMarks,
  extraConfig: {
    'cricketNumbers': ['20', '19', '18', '17', '16', '15', 'B'],
    'rounds': 8, // 15 → 8
    'targetMprMin': 3.4,
    'targetMprMax': 3.8,
  },
);

const TrainingDrillDefinition proBull90 = TrainingDrillDefinition(
  id: 'pro_bull_90',
  titleKo: 'Bull 컨트롤 90발',
  titleEn: 'Bull Control 90 Darts',
  shortDescriptionKo:
  'Bull 90발로 SBull/DBull 분포와 정확도를 체크하는 컨트롤 드릴',
  shortDescriptionEn:
  'Control drill with 90 darts at Bull to track SBull/DBull distribution.',
  category: TrainingDrillCategory.bull,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.pro,
    maxTier: rating_utils.DaoTrainingTier.pro,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 15,
  recommendedDarts: 90,
  targetLabel: 'Bull 90발 (SBull / DBull)',
  guideKo:
  'Bull만 90발을 던지는 드릴입니다. SBull은 S 버튼, DBull은 D 버튼으로 각각 개수를 기록합니다. '
      '앱은 SBull+DBull 합 / 90으로 전체 Bull 성공률을, DBull / 90으로 DBull 비율을 계산합니다. '
      '목표치는 SBull+DBull 60개 이상, DBull 15개 이상으로 두고 자신의 분포와 정확도를 체크합니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'mode': 'bull_split', // 🔹 DrillRunScreen에서 bull 패널로 태우기 위한 키
    'targetArea': 'bull_split',
    'totalDarts': 90,
    'targetSbPlusDb': 60,
    'targetDb': 15,
  },
);


const TrainingDrillDefinition proClutchDouble2Darts30x =
TrainingDrillDefinition(
  id: 'pro_clutch_double_2darts_30x',
  titleKo: '클러치 더블 라인 컨트롤',
  titleEn: 'Clutch Double Line Control',
  shortDescriptionKo:
  'D16, D20, D8, D12 네 가지 실전 핵심 더블 라인을 한 번에 묶어서 명중률을 체크하는 드릴',
  shortDescriptionEn:
  'Practice four key match doubles (D16, D20, D8, D12) and track hit rates by segment.',
  category: TrainingDrillCategory.doublePractice,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.pro,
    maxTier: rating_utils.DaoTrainingTier.pro,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 18,
  recommendedDarts: 60, // 4개 더블 x 15발 = 60발
  targetLabel: '클러치 더블 라인 (D16·D20·D8·D12)',
  guideKo: '실전에서 가장 많이 쓰는 더블 라인인 D16, D20, D8, D12 네 구역을 한 번에 연습하는 드릴입니다. '
      '각 더블마다 15발씩, 총 60발을 던지며 명중/미스를 기록합니다. '
      '실제 게임에서는 “2다트 안에 해결한다”는 느낌으로 루틴을 가져가되, 앱에서는 전체/세그먼트별 명중률을 기준으로 '
      '자신의 약한 더블과 강한 더블을 눈으로 확인할 수 있게 도와줍니다. '
      '세션 종료 후에는 전체 더블 적중률과, D16·D20·D8·D12 각각의 적중률을 비교해 보세요.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    // 🔹 T20FocusPanel 멀티 세그먼트 모드와 매칭되는 설정
    'segments': ['D16', 'D20', 'D8', 'D12'],
    'dartsPerSegment': 15, // 각 더블 15발씩
    // 아래는 계산에 꼭 필요하진 않지만 명시적으로 남겨 둠
    'totalDarts': 60,
  },
);


/// 프로용 8R Count-Up (티어 밴드: 900~999)
const TrainingDrillDefinition proCountUp8r = TrainingDrillDefinition(
  id: 'pro_countup_8r',
  titleKo: '프로 Count-Up 8R',
  titleEn: 'Pro Count-Up 8R',
  shortDescriptionKo: '8R Count-Up에서 900~1000점대를 노리는 프로용 드릴',
  shortDescriptionEn:
  '8-round Count-Up drill targeting 900–1000+ points for pro players.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.pro,
    maxTier: rating_utils.DaoTrainingTier.pro,
  ),
  inputMode: TrainingDrillInputMode.scoreOnly,
  estimatedMinutes: 8,
  recommendedDarts: 24,
  targetLabel: '8R Count-Up (프로 구간)',
  guideKo:
  '일반 8라운드 Count-Up을 1게임 플레이하고, 최종 점수만 앱에 입력하는 드릴입니다. '
      '프로 구간(900~999점)을 기준으로, 900점 → 950점 → 1000점 같은 단계 목표를 제공합니다. '
      '1000점 이상 기록 시 “마스터 밴드 진입” 같은 메시지로 상위 구간 도전 욕구를 자극할 수 있습니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.scoreGame,
  extraConfig: {
    'gameType': 'countup',
    'rounds': 8,
    'milestones': [900, 950, 1000],
  },
);

/// ===============================
/// 7. Master (마스터) 드릴
/// ===============================

const TrainingDrillDefinition masterT20_120Darts = TrainingDrillDefinition(
  id: 'master_t20_120_darts',
  titleKo: 'T20 집중 120발',
  titleEn: 'T20 Focus 120 Darts',
  shortDescriptionKo:
  'T20 120발 기준 트리플 성공률 50%를 노리는 마스터용 스코어링 드릴',
  shortDescriptionEn:
  'Master-level T20 drill aiming for 50% triple hit rate over 120 darts.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.master,
    maxTier: rating_utils.DaoTrainingTier.master,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 22,
  recommendedDarts: 120,
  targetLabel: 'T20 (120발)',
  guideKo:
  'T20만 향해 총 120발(3다트 × 40라운드)을 던지는 마스터용 스코어링 드릴입니다. '
      '라운드 기반 모드에서는 매 라운드마다 T20 히트 수(0~3)를 입력하고, '
      '간단 모드에서는 세션 종료 후 T20 총 개수만 입력해도 됩니다. '
      '120발 중 60개 이상이면 트리플 성공률 50% 도달, 60~70개는 상위 마스터 영역, '
      '70개를 넘기면 사실상 “괴물 존 🤣”으로 간주할 수 있습니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'segments': ['T20'],
    'totalDarts': 120,
    'targetHits': 60,
    'rounds': 40,
    'dartsPerRound': 3,
  },
);

const TrainingDrillDefinition master170RouteFocused30 =
TrainingDrillDefinition(
  id: 'master_170_route_focused_30',
  titleKo: '170 체크아웃 루트 집중 (30세트)',
  titleEn: '170 Checkout Route Focus (30 Sets)',
  shortDescriptionKo:
  'T20 → T20 → Bull 루트를 170 상황에서 몸에 새겨넣는 하이피니시 드릴',
  shortDescriptionEn:
  'Fix the T20–T20–Bull 170 checkout route in your muscle memory.',
  category: TrainingDrillCategory.finish,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.master,
    maxTier: rating_utils.DaoTrainingTier.master,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 25,
  recommendedDarts: 90,
  targetLabel: '170 (T20 → T20 → Bull 루트)',
  guideKo:
  '항상 170 점수에서 시작해서, 1·2번째 다트는 T20, 3번째 다트는 Bull을 노리는 '
      'T20 → T20 → Bull 고정 루트로만 30세트를 진행합니다. '
      '각 세트는 “170 점수에서 3다트 찬스 1회”라고 생각하고, 다트마다 맞춘 점수를 입력하세요. '
      '3다트 안에 170을 정확히 마무리하면 성공, 루트를 어기거나 체크아웃에 실패하면 실패로 기록합니다. '
      '30세트 중 1~2회 성공만 나와도 정상적인 난이도(성공률 3~7%)로 보고, '
      '핵심은 항상 같은 루트를 자신 있게 던질 수 있도록 패턴을 몸에 새기는 것입니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.checkoutRoute,
  extraConfig: {
    // 🔹 CheckoutPracticePanel로 보내기 위한 모드 플래그
    'mode': 'checkout_practice',

    // 🔹 항상 170에서 시작 (min == max)
    'minScore': 170,
    'maxScore': 170,

    // 🔹 세트/다트 설정
    'totalSets': 30,
    'maxDartsPerSet': 3,

    // 🔹 더블아웃 / DBull 필수
    'requireDoubleOut': true,

    // 🔹 루트 정보(지금은 UI/결과 설명용으로만 보관)
    'route': ['T20', 'T20', 'Bull'],

    // 🔹 피드백용 목표 성공 세트 범위
    'hintTargetSuccessMin': 1,
    'hintTargetSuccessMax': 2,
  },
);


const TrainingDrillDefinition masterCricket4mpr15r =
TrainingDrillDefinition(
  id: 'master_cricket_4mpr_15r',
  titleKo: 'Cricket 4.0+ MPR (8R)',
  titleEn: 'Cricket 4.0+ MPR (8R)',
  shortDescriptionKo:
  '풀 크리켓에서 평균 MPR 4.0 이상을 노리는 마스터 레벨 8R 마크 드릴',
  shortDescriptionEn:
  'Master-level full-board cricket drill (8 rounds) aiming for 4.0+ MPR.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.master,
    maxTier: rating_utils.DaoTrainingTier.master,
  ),
  inputMode: TrainingDrillInputMode.cricketMarks,
  estimatedMinutes: 10,
  recommendedDarts: 24,
  targetLabel: 'Full Cricket (8R, MPR 4.0+)',
  guideKo:
  '20, 19, 18, 17, 16, 15, Bull을 모두 사용하는 풀보드 크리켓을 8라운드 진행합니다. '
      '각 라운드가 끝날 때 이번 라운드에서 만든 총 마크 수(0~9)를 입력하면, 앱이 평균 MPR을 계산합니다. '
      '평균 MPR이 4.0 이상일 때만 “마스터 기준 도달” 배지나 메시지를 제공하고, '
      '그 아래 구간에서는 어떤 구간(20~15, Bull)에서 마크가 부족한지 스스로 체크하는 용도로 활용할 수 있습니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.cricketMarks,
  extraConfig: {
    'cricketNumbers': ['20', '19', '18', '17', '16', '15', 'B'],
    'rounds': 8, // 15 → 8
    'targetMprMin': 4.0,
  },
);

const TrainingDrillDefinition masterBullPrecision90 =
TrainingDrillDefinition(
  id: 'master_bull_precision_90',
  titleKo: 'Bull 정밀 90발',
  titleEn: 'Bull Precision 90 Darts',
  shortDescriptionKo:
  'Bull 90발에서 SBull+DBull 60개, DBull 20개를 노리는 정밀 컨트롤 드릴',
  shortDescriptionEn:
  'Precision bull drill: 90 darts aiming for 60 total bulls and 20 DBulls.',
  category: TrainingDrillCategory.bull,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.master,
    maxTier: rating_utils.DaoTrainingTier.master,
  ),
  inputMode: TrainingDrillInputMode.hitCount,
  estimatedMinutes: 18,
  recommendedDarts: 90,
  targetLabel: 'Bull 90발 (정밀 컨트롤)',
  guideKo:
  'Bull만 90발을 던지는 마스터용 정밀 컨트롤 드릴입니다. '
      '세션 중이든 끝난 뒤든, SBull에 맞출 때마다 S 버튼, DBull에 맞출 때마다 D 버튼으로 개수를 카운트합니다. '
      '세션이 끝나면 SBull+DBull 합 / 90으로 전체 Bull 성공률을, DBull / 90으로 DBull 비율을 계산합니다. '
      'SBull+DBull 60개 이상, DBull 20개 이상이면 “마스터 Bull 컨트롤 기준 달성”으로 안내합니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.segmentTarget,
  extraConfig: {
    'mode': 'bull_split',          // 🔥 이 한 줄이 없어서 패널이 안 타고 있었던 거
    'targetArea': 'bull_split',
    'totalDarts': 90,
    'targetSbPlusDb': 60,
    'targetDb': 20,
  },
);

/// 마스터용 8R Count-Up (티어 밴드: 1000+)
const TrainingDrillDefinition masterCountUp8r = TrainingDrillDefinition(
  id: 'master_countup_8r',
  titleKo: '마스터 Count-Up 8R',
  titleEn: 'Master Count-Up 8R',
  shortDescriptionKo: '8R Count-Up에서 1000~1200+ 점대를 노리는 마스터용 드릴',
  shortDescriptionEn:
  '8-round Count-Up drill targeting 1000–1200+ points for master level.',
  category: TrainingDrillCategory.scoring,
  tierRange: DrillTierRange(
    minTier: rating_utils.DaoTrainingTier.master,
    maxTier: rating_utils.DaoTrainingTier.master,
  ),
  inputMode: TrainingDrillInputMode.scoreOnly,
  estimatedMinutes: 8,
  recommendedDarts: 24,
  targetLabel: '8R Count-Up (마스터 구간)',
  guideKo:
  '일반 8라운드 Count-Up을 1게임 플레이하고, 최종 점수만 앱에 입력하는 드릴입니다. '
      '1000점 → 1100점 → 1200점 같은 단계 목표를 제시하여, 마스터 구간에서 자신의 피크 스코어를 끌어올리는 데 사용합니다. '
      '1000점을 안정적으로 넘기기 시작하면, 이후에는 1100, 1200 이상의 기록을 “개인 베스트 갱신”으로 관리할 수 있습니다.',
  difficulty: DrillDifficulty.veryHard,
  uiPattern: DrillUIPattern.scoreGame,
  extraConfig: {
    'gameType': 'countup',
    'rounds': 8,
    'milestones': [1000, 1100, 1200],
  },
);

/// ===============================
/// 티어별 드릴 매핑
/// ===============================

final Map<rating_utils.DaoTrainingTier, List<TrainingDrillDefinition>>
kTrainingDrillsByTier = {
  rating_utils.DaoTrainingTier.beginner: [
    beginnerQuadrantBasic,
    beginnerTopBottomBasic,
    beginnerAroundTheBoardSingle,
    beginnerLargeSingle20,
    beginnerBigBull,
    beginnerLooseCountUp,
  ],
  rating_utils.DaoTrainingTier.learner: [
    learnerStandardCountUp8r,
    learnerSingle20x60,
    learnerTopBottomAdvanced,
    learner20to19Switch,
    learner17to15Line,
  ],
  rating_utils.DaoTrainingTier.competitor: [
    compTriple201918,
    compDoubleClockHalf,
    compDoubleClockBack,
    compCheckout40to80,
    compCricket2019,
    compCountUpHigh20,
    compBullDoubleIntro,
  ],
  rating_utils.DaoTrainingTier.challenger: [
    challCheckout60to100Random,
    challDoubleClockFull,
    challT20Focus60,
    challCricketFull,
    challCountup700,
  ],
  rating_utils.DaoTrainingTier.elite: [
    eliteT20Precision60,
    eliteT20T19TripleSwitch,
    eliteCheckout61to120,
    eliteDoubleClusterD16D20,
    eliteCricketPowerMarks15r,
    eliteCountUp8r,
  ],
  rating_utils.DaoTrainingTier.pro: [
    pro501Standard18darts,
    proT20_90Darts,
    proHighFinishSet8,
    proCricketHighMpr15r,
    proBull90,
    proClutchDouble2Darts30x,
    proCountUp8r,
  ],
  rating_utils.DaoTrainingTier.master: [
    masterT20_120Darts,
    master170RouteFocused30,
    masterCricket4mpr15r,
    masterBullPrecision90,
    masterCountUp8r,
  ],
};

List<TrainingDrillDefinition> getDrillsForTier(
    rating_utils.DaoTrainingTier tier,
    ) {
  return kTrainingDrillsByTier[tier] ?? const <TrainingDrillDefinition>[];
}
