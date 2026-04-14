// lib/presentation/widgets/training/drill_stat_summary.dart

import 'package:flutter/material.dart';
import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class DrillStatSummary extends StatelessWidget {
  final TrainingSessionModel session;
  final TrainingDrillDefinition drill;

  const DrillStatSummary({
    super.key,
    required this.session,
    required this.drill,
  });

  @override
  Widget build(BuildContext context) {
    final tierLabel = session.tierAtThatTime.labelKo;

    // 🔹 날짜/시간 정보 (endedAt 없으면 startedAt 사용)
    final DateTime endAt = session.endedAt ?? session.startedAt;
    final dateStr =
        '${endAt.year}.${endAt.month.toString().padLeft(2, '0')}.${endAt.day.toString().padLeft(2, '0')}';

    // 🔹 소요 시간 (분)
    final durationSeconds =
    endAt.difference(session.startedAt).inSeconds.clamp(0, 86400);
    final int durationMin =
        (durationSeconds ~/ 60) + (durationSeconds % 60 > 0 ? 1 : 0);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 + 티어
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    session.drillTitle.isNotEmpty
                        ? session.drillTitle
                        : drill.titleKo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tierLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyan,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$dateStr  ·  약 ${durationMin}분  ·  ${drill.category.name}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),

            // 지표들 Chip 로우
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _buildMetricChips(),
            ),

            const SizedBox(height: 10),
            Text(
              drill.shortDescriptionKo,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMetricChips() {
    final List<Widget> chips = [];

    // 🔹 extra에서 파생 데이터 꺼내기
    final extra = session.extra ?? {};

    // inputMode: extra['inputMode'] 에 문자열로 저장됨
    final String? inputModeName = extra['inputMode'] as String?;
    TrainingDrillInputMode? inputMode;
    if (inputModeName != null) {
      inputMode = TrainingDrillInputMode.values.firstWhere(
            (e) => e.name == inputModeName,
        orElse: () => TrainingDrillInputMode.hitCount,
      );
    } else {
      inputMode = TrainingDrillInputMode.hitCount;
    }

    // 공통: 총 다트 / 라운드
    final totalDarts = session.totalAttempts;
    final totalRounds = session.totalRounds;

    chips.add(_metricChip(
      label: '총 다트',
      value: '$totalDarts',
    ));

    if (totalRounds > 0) {
      chips.add(_metricChip(
        label: '라운드',
        value: '$totalRounds',
      ));
    }

    switch (inputMode) {
      case TrainingDrillInputMode.hitCount:
      // hitCount 모드: 명중 수, 명중률
        final hitCount = session.successCount;
        final hitRate =
            (extra['hitRate'] as num?)?.toDouble() ?? 0.0; // 0.0~1.0
        final hitRateText = (hitRate * 100).toStringAsFixed(1);

        chips.add(_metricChip(
          label: '명중 수',
          value: '$hitCount',
        ));
        chips.add(_metricChip(
          label: '명중률',
          value: '$hitRateText%',
        ));
        break;

      case TrainingDrillInputMode.cricketMarks:
      // cricketMarks 모드: 총 마크, MPR
        final totalMarks = (extra['totalMarks'] as num?)?.toInt() ?? 0;
        final mpr = (extra['mpr'] as num?)?.toDouble() ?? 0.0;

        chips.add(_metricChip(
          label: '총 마크',
          value: '$totalMarks',
        ));
        chips.add(_metricChip(
          label: 'MPR',
          value: mpr.toStringAsFixed(2),
        ));
        break;

      case TrainingDrillInputMode.scoreOnly:
      // scoreOnly 모드: 총 점수, PPD
        final totalScore = (extra['totalScore'] as num?)?.toInt() ?? 0;
        final ppd = (extra['ppd'] as num?)?.toDouble() ?? 0.0;

        chips.add(_metricChip(
          label: '총 점수',
          value: '$totalScore',
        ));
        chips.add(_metricChip(
          label: 'PPD',
          value: ppd.toStringAsFixed(2),
        ));
        break;
    }

    return chips;
  }

  Widget _metricChip({required String label, required String value}) {
    return Chip(
      backgroundColor: Colors.blueGrey.withOpacity(0.08),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
