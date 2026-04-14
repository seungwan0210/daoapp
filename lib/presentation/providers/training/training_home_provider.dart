// lib/presentation/providers/training/training_home_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/data/models/training_drill_model.dart';

// 오늘의 추천 드릴 (기존)
import 'package:daoapp/core/constants/training_program_constants.dart'
as program_constants;

/// ------------------------------------------------------------------
/// 1) 내 현재 DAO 트레이닝 티어에 맞는 "오늘 추천 드릴 리스트"
/// ------------------------------------------------------------------
final trainingDrillsForTierProvider =
Provider.family<List<TrainingDrillDefinition>, DaoTrainingTier>(
      (ref, tier) {
    return program_constants.getRecommendedDrillsForToday(tier);
  },
);
