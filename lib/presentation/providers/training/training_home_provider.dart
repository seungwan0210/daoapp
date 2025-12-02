// lib/presentation/providers/training/training_home_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/core/constants/training_drill_constants.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/data/models/training_drill_model.dart';

/// 내 현재 유저 티어에 맞는 추천 드릴 리스트
final trainingDrillsForTierProvider = Provider.family<
    List<TrainingDrillDefinition>, DaoTrainingTier>((ref, tier) {
  return getDrillsForTier(tier);
});