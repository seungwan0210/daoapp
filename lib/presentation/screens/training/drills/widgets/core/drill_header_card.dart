// lib/presentation/screens/training/drills/widgets/core/drill_header_card.dart

import 'package:flutter/material.dart';
import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 임포트 경로 확인

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

  /// 카테고리 이름을 다국어 키로 매핑하는 헬퍼 메서드
  String _getCategoryLabel(BuildContext context, TrainingDrillCategory category) {
    final s = AppLocalizations.of(context)!;
    return switch (category) {
      TrainingDrillCategory.boardMapping => s.drill_category_board_mapping,
      TrainingDrillCategory.scoring => s.drill_category_scoring,
      TrainingDrillCategory.finish => s.drill_category_finish,
      TrainingDrillCategory.doublePractice => s.drill_category_double,
      TrainingDrillCategory.bull => s.drill_category_bull,
      TrainingDrillCategory.other => s.drill_category_other,
    };
  }

  /// 예상 소요 시간 계산 및 다국어 포맷팅
  String _estimatedTime(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final m = drill.estimatedMinutes ??
        (drill.recommendedDarts != null
            ? (drill.recommendedDarts! / 6).ceil()
            : 10);

    // 🔹 함수형 인자 호출로 수정 ({min} 값 전달)
    return s.drill_time_format(m.toString());
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final color = _categoryColor(drill.category);

    // 현재 기기의 언어 및 스크립트 정보 확인
    final locale = Localizations.localeOf(context);
    final String langCode = locale.languageCode;
    final String? scriptCode = locale.scriptCode;

    // 🔹 다국어 제목 선택 헬퍼
    String getDrillTitle() {
      if (langCode == 'ja') return drill.titleJa;
      if (langCode == 'zh') {
        return scriptCode == 'Hant' ? drill.titleZhHant : drill.titleZhHans;
      }
      return drill.titleKo;
    }

    // 🔹 다국어 설명 선택 헬퍼
    String getDrillDesc() {
      if (langCode == 'ja') return drill.shortDescriptionJa;
      if (langCode == 'zh') {
        return scriptCode == 'Hant' ? drill.shortDescriptionZhHant : drill.shortDescriptionZhHans;
      }
      return drill.shortDescriptionKo;
    }

    // 🔹 다국어 티어 라벨 선택 헬퍼 (DaoTrainingTierX 익스텐션 활용)
    String getTierLabel() {
      if (tier == null) return '';
      if (langCode == 'ja') return tier!.labelJa;
      if (langCode == 'en') return tier!.labelEn;
      if (langCode == 'zh') {
        return scriptCode == 'Hant' ? tier!.labelZhHant : tier!.labelZhHans;
      }
      return tier!.labelKo;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                  getDrillTitle(),
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
                    getTierLabel(),
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
            getDrillDesc(),
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
              const Icon(Icons.flag_circle, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  // 🔹 수정됨: s.translate 대신 헬퍼 메서드 사용
                  _getCategoryLabel(context, drill.category),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              const Icon(Icons.access_time, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                _estimatedTime(context),
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}