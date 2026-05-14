// lib/presentation/screens/training/widgets/training_recommendation_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/presentation/providers/training/training_history_provider.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class TrainingRecommendationCard extends ConsumerWidget {
  final TrainingDrillDefinition drill;
  final VoidCallback? onTap;

  const TrainingRecommendationCard({
    super.key,
    required this.drill,
    this.onTap,
  });

  // targetLabel을 짧은 라벨로 변환
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
    final s = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode;

    // 🔹 다국어 텍스트 선택
    String title = drill.titleKo;
    String desc = drill.shortDescriptionKo;

    if (lang == 'en') {
      title = drill.titleEn;
      desc = drill.shortDescriptionEn;
    } else if (lang == 'ja') {
      title = drill.titleJa;
      desc = drill.shortDescriptionJa;
    } else if (lang == 'zh') {
      if (locale.scriptCode == 'Hant') {
        title = drill.titleZhHant;
        desc = drill.shortDescriptionZhHant;
      } else {
        title = drill.titleZhHans;
        desc = drill.shortDescriptionZhHans;
      }
    }

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
                    title, // 🔹 다국어 적용
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // 배경 테마에 맞춰 조정 필요 (AppCard가 흰색이면 검정색)
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc, // 🔹 다국어 적용
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
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
                        hasDoneToday ? s.drill_rec_done : s.drill_rec_start, // 🔹 다국어 적용
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