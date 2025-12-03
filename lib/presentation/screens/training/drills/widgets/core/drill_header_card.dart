// lib/presentation/screens/training/drills/widgets/core/drill_header_card.dart

import 'package:flutter/material.dart';
import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';

class DrillHeaderCard extends StatelessWidget {
  final TrainingDrillDefinition drill;
  final DaoTrainingTier? tier;

  const DrillHeaderCard({
    super.key,
    required this.drill,
    this.tier,
  });

  Color _categoryColor(TrainingDrillCategory category) {
    return switch (category) {
      TrainingDrillCategory.boardMapping => Colors.teal.shade600,
      TrainingDrillCategory.scoring => Colors.orange.shade700,
      TrainingDrillCategory.finish => Colors.redAccent.shade700,
      TrainingDrillCategory.doublePractice => Colors.indigo.shade600,
      TrainingDrillCategory.bull => Colors.green.shade700,
      _ => Colors.cyan.shade700,
    };
  }

  String _estimatedTime() {
    final extra = drill.extraConfig ?? {};
    final minutes = extra['estimatedMinutes'] as int? ??
        drill.estimatedMinutes ??
        (drill.recommendedDarts != null ? (drill.recommendedDarts! / 6).ceil() : 10);
    return "~${minutes}분";
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(drill.category);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.95), color.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // 왼쪽: 제목 + 티어
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 + 티어 한 줄로!
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        drill.titleKo,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tier != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tier!.labelKo,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 6),

                // 목표 + 예상 시간 한 줄로!
                Row(
                  children: [
                    Icon(Icons.flag_circle, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "목표: ${drill.targetLabel}",
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _estimatedTime(),
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}