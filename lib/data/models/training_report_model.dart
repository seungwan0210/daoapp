// lib/data/models/training_report_model.dart

import 'package:flutter/widgets.dart'; // 🔹 BuildContext 사용을 위해 추가
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 언어팩 임포트
import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/data/models/training_progress_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';

/// DAO 트레이닝 리포트 모델
class TrainingReportModel {
  final TrainingSessionModel session;
  final int xpEarned;
  final int totalXpBefore;
  final int totalXpAfter;
  final int xpTargetPerCheck;
  final double gaugeBeforeRatio;
  final double gaugeAfterRatio;
  final DaoTrainingTier currentTier;
  final List<TrainingHighlight> highlights;

  const TrainingReportModel({
    required this.session,
    required this.xpEarned,
    required this.totalXpBefore,
    required this.totalXpAfter,
    required this.xpTargetPerCheck,
    required this.gaugeBeforeRatio,
    required this.gaugeAfterRatio,
    required this.currentTier,
    required this.highlights,
  });
}

/// 리포트 하단에 표시할 하이라이트 문구 항목
class TrainingHighlight {
  final String label;
  final String value;
  final String? subLabel;
  final HighlightType type;

  const TrainingHighlight({
    required this.label,
    required this.value,
    this.subLabel,
    this.type = HighlightType.neutral,
  });
}

enum HighlightType {
  gain,
  loss,
  neutral,
}

/// Report Builder
class TrainingReportBuilder {
  static TrainingReportModel build({
    required BuildContext context, // 🔹 다국어 처리를 위해 추가
    required TrainingSessionModel session,
    required TrainingProgressModel progressBefore,
    required TrainingProgressModel progressAfter,
  }) {
    final int beforeXp = progressBefore.xpSinceLastCheck;
    final int afterXp = progressAfter.xpSinceLastCheck;
    final int target = progressAfter.cycleSize;

    final double beforeRatio = target > 0 ? beforeXp / target : 0.0;
    final double afterRatio = target > 0 ? afterXp / target : 0.0;

    return TrainingReportModel(
      session: session,
      xpEarned: session.xpEarned,
      totalXpBefore: beforeXp,
      totalXpAfter: afterXp,
      xpTargetPerCheck: target,
      gaugeBeforeRatio: beforeRatio,
      gaugeAfterRatio: afterRatio,
      currentTier: session.tierAtThatTime,
      highlights: _generateHighlights(context, session), // 🔹 context 전달
    );
  }

  /// 세션 데이터 기반으로 변화 포인트 생성 (다국어 대응)
  static List<TrainingHighlight> _generateHighlights(
      BuildContext context,
      TrainingSessionModel s,
      ) {
    final sLang = AppLocalizations.of(context)!; // 🔹 다국어 인스턴스 생성
    final List<TrainingHighlight> list = [];

    // 명중률 (Hit Rate)
    if (s.hitRate != null) {
      final hr = (s.hitRate! * 100).toStringAsFixed(1);
      list.add(
        TrainingHighlight(
          label: sLang.drill_stat_success, // 🔹 "성공률" 또는 "명중률"
          value: "$hr%",
          type: s.hitRate! >= 0.5 ? HighlightType.gain : HighlightType.neutral,
        ),
      );
    }

    // PPD
    if (s.ppd != null) {
      list.add(
        TrainingHighlight(
          label: "PPD", // PPD는 만국 공통 약어이므로 그대로 유지
          value: s.ppd!.toStringAsFixed(2),
          type: HighlightType.neutral,
        ),
      );
    }

    // MPR
    if (s.mpr != null) {
      list.add(
        TrainingHighlight(
          label: "MPR", // MPR 역시 약어 유지
          value: s.mpr!.toStringAsFixed(2),
          type: HighlightType.neutral,
        ),
      );
    }

    // 던진 다트 수 (Total Darts)
    list.add(
      TrainingHighlight(
        label: sLang.drill_stat_darts, // 🔹 "다트 수" 또는 "사용 다트"
        value: s.totalAttempts.toString(),
        type: HighlightType.neutral,
      ),
    );

    return list;
  }
}