// lib/presentation/widgets/training/drill_stat_summary.dart

import 'package:flutter/material.dart';
import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class DrillStatSummary extends StatelessWidget {
  final TrainingSessionModel session;
  final TrainingDrillDefinition drill;

  const DrillStatSummary({
    super.key,
    required this.session,
    required this.drill,
  });

  // 🔹 현재 언어에 맞는 티어 라벨 가져오기
  String _getTierLabel(BuildContext context, DaoTrainingTier tier) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'en') return tier.labelEn;
    if (locale.languageCode == 'ja') return tier.labelJa;
    if (locale.languageCode == 'zh') {
      return locale.scriptCode == 'Hant' ? tier.labelZhHant : tier.labelZhHans;
    }
    return tier.labelKo;
  }

  // 🔹 현재 언어에 맞는 드릴 제목 가져오기
  String _getDrillTitle(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode;

    // 만약 세션에 저장된 타이틀이 있으면 사용 (보통 한국어일 확률이 높음)
    // 글로벌 대응을 위해 drill 정의의 다국어 필드를 우선 참조하는 것이 좋음
    if (lang == 'ja') return drill.titleJa;
    if (lang == 'en') return drill.titleEn;
    if (lang == 'zh') {
      return locale.scriptCode == 'Hant' ? drill.titleZhHant : drill.titleZhHans;
    }
    return drill.titleKo;
  }

  // 🔹 현재 언어에 맞는 드릴 짧은 설명 가져오기
  String _getDrillShortDesc(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode;

    if (lang == 'ja') return drill.shortDescriptionJa;
    if (lang == 'en') return drill.shortDescriptionEn;
    if (lang == 'zh') {
      return locale.scriptCode == 'Hant' ? drill.shortDescriptionZhHant : drill.shortDescriptionZhHans;
    }
    return drill.shortDescriptionKo;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final tierLabel = _getTierLabel(context, session.tierAtThatTime);

    // 🔹 날짜/시간 정보
    final DateTime endAt = session.endedAt ?? session.startedAt;
    final dateStr =
        '${endAt.year}.${endAt.month.toString().padLeft(2, '0')}.${endAt.day.toString().padLeft(2, '0')}';

    // 🔹 소요 시간
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
                    _getDrillTitle(context),
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
              '$dateStr  ·  ${s.drill_approx_duration(durationMin.toString())}  ·  ${drill.category.name}',
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
              children: _buildMetricChips(context), // context 전달
            ),

            const SizedBox(height: 10),
            Text(
              _getDrillShortDesc(context),
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

  List<Widget> _buildMetricChips(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final List<Widget> chips = [];
    final extra = session.extra ?? {};

    final String? inputModeName = extra['inputMode'] as String?;
    TrainingDrillInputMode inputMode = TrainingDrillInputMode.hitCount;
    if (inputModeName != null) {
      inputMode = TrainingDrillInputMode.values.firstWhere(
            (e) => e.name == inputModeName,
        orElse: () => TrainingDrillInputMode.hitCount,
      );
    }

    final totalDarts = session.totalAttempts;
    final totalRounds = session.totalRounds;

    chips.add(_metricChip(
      label: s.drill_stat_total_darts,
      value: '$totalDarts',
    ));

    if (totalRounds > 0) {
      chips.add(_metricChip(
        label: s.drill_stat_rounds,
        value: '$totalRounds',
      ));
    }

    switch (inputMode) {
      case TrainingDrillInputMode.hitCount:
        final hitCount = session.successCount;
        final hitRate = (extra['hitRate'] as num?)?.toDouble() ?? 0.0;
        final hitRateText = (hitRate * 100).toStringAsFixed(1);

        chips.add(_metricChip(
          label: s.drill_stat_hit_count,
          value: '$hitCount',
        ));
        chips.add(_metricChip(
          label: s.drill_stat_hit_rate,
          value: '$hitRateText%',
        ));
        break;

      case TrainingDrillInputMode.cricketMarks:
        final totalMarks = (extra['totalMarks'] as num?)?.toInt() ?? 0;
        final mpr = (extra['mpr'] as num?)?.toDouble() ?? 0.0;

        chips.add(_metricChip(
          label: s.drill_stat_total_marks,
          value: '$totalMarks',
        ));
        chips.add(_metricChip(
          label: 'MPR', // 🔹 MPR/PPD는 글로벌 공용어라 그대로 둠
          value: mpr.toStringAsFixed(2),
        ));
        break;

      case TrainingDrillInputMode.scoreOnly:
        final totalScore = (extra['totalScore'] as num?)?.toInt() ?? 0;
        final ppd = (extra['ppd'] as num?)?.toDouble() ?? 0.0;

        chips.add(_metricChip(
          label: s.drill_stat_total_score,
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
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}