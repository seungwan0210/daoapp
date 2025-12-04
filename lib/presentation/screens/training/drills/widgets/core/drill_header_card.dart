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

  Color _categoryColor(TrainingDrillCategory category) => switch (category) {
    TrainingDrillCategory.boardMapping => Colors.teal,
    TrainingDrillCategory.scoring => Colors.orange,
    TrainingDrillCategory.finish => Colors.redAccent,
    TrainingDrillCategory.doublePractice => Colors.indigo,
    TrainingDrillCategory.bull => Colors.green,
    TrainingDrillCategory.other => Colors.cyan,
  };

  /// 예상 소요 시간 계산
  String _estimatedTime() {
    // 🔥 공식 시간배치 규칙: drill.estimatedMinutes → 있으면 우선 사용
    final m = drill.estimatedMinutes ??
        (drill.recommendedDarts != null
            ? (drill.recommendedDarts! / 6).ceil()
            : 10);
    return "~${m}분";
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(drill.category);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.95),
            color.withOpacity(0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== 제목 + 티어 배지 =====
          Row(
            children: [
              Expanded(
                child: Text(
                  drill.titleKo,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tier != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tier!.labelKo,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(height: 6),

          // ===== 설명 =====
          Text(
            drill.shortDescriptionKo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(.9),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),

          // ===== 목표 & 시간 =====
          Row(
            children: [
              if (drill.targetLabel.isNotEmpty) ...[
                const Icon(Icons.flag_circle, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    drill.targetLabel,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.access_time, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                _estimatedTime(),
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
