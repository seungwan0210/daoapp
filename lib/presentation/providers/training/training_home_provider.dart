// lib/presentation/providers/training/training_home_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/core/constants/training_drill_constants.dart'
as drill_constants;
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/data/models/training_drill_model.dart';

/// 내 현재 DAO 트레이닝 티어에 맞는
/// "오늘 추천 드릴 리스트"
final trainingDrillsForTierProvider =
Provider.family<List<TrainingDrillDefinition>, DaoTrainingTier>(
      (ref, tier) {
    // 지금은 티어 기준으로만 추천하지만,
    // 나중에 요일/최근 기록/취약 영역 반영할 때 이 함수만 바꿔주면 됨.
    return drill_constants.recommendedDrillsForToday(tier);
  },
);
