// lib/presentation/screens/training/widgets/training_recommendation_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/presentation/providers/training/training_history_provider.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class TrainingRecommendationCard extends ConsumerWidget {
  final TrainingDrillDefinition drill;
  final VoidCallback? onTap;

  const TrainingRecommendationCard({
    super.key,
    required this.drill,
    this.onTap,
  });

  // targetLabel을 짧은 라벨로 변환 (예: "D16" 또는 "T20×2+Bull" → "D16")
  String get shortLabel {
    final label = drill.targetLabel;
    if (label.contains('\n')) {
      return label.split('\n').first;
    }
    if (label.length > 8) {
      return label.substring(0, 7) + '..';
    }
    return label;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // todayDrillSessionsProvider는 List를 직접 반환 → AsyncValue 아님
    final todaySessions = ref.watch(todayDrillSessionsProvider(drill.id));
    final hasDoneToday = todaySessions.isNotEmpty;

    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // 왼쪽 라운드 라벨
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyan.withOpacity(0.15),
                border: Border.all(color: Colors.cyan.withOpacity(0.4), width: 2),
              ),
              child: Center(
                child: Text(
                  shortLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.cyan,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 가운데 설명
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drill.titleKo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    drill.shortDescriptionKo, // 정확한 필드명
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // 오른쪽 상태 표시
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasDoneToday
                        ? Colors.green.withOpacity(0.2)
                        : Colors.cyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasDoneToday ? Colors.green : Colors.cyan,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasDoneToday ? Icons.check_circle : Icons.play_arrow,
                        size: 16,
                        color: hasDoneToday ? Colors.green : Colors.cyan,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasDoneToday ? "오늘 완료" : "시작하기",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: hasDoneToday ? Colors.green : Colors.cyan,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}