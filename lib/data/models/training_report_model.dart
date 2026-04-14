// lib/data/models/training_report_model.dart

import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/data/models/training_progress_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';

/// DAO 트레이닝 리포트 모델
///
/// 한 번의 연습이 끝난 직후 사용자에게 보여주는
/// "이번 세션의 의미"에 집중한 리포트 데이터.
///
/// - 이번 세션에서 무엇을 얻었는가?
/// - 어떤 능력이 향상되었는가?
/// - 게이지가 얼마나 찼는가?
/// - 다음 목표까지 얼마나 남았는가?
class TrainingReportModel {
  /// 원본 세션 데이터 (점수/성공률/던진 수 등)
  final TrainingSessionModel session;

  /// 이번 세션으로 획득한 XP
  final int xpEarned;

  /// 🔹 현재 "한 사이클" 기준 XP 변화 (xpSinceLastCheck 기준)
  final int totalXpBefore; // 세션 전 xpSinceLastCheck
  final int totalXpAfter;  // 세션 후 xpSinceLastCheck

  /// 게이지 목표값 (한 사이클에 필요한 XP, = cycleSize)
  final int xpTargetPerCheck;

  /// 게이지 전/후 비율 (0.0 ~ 1.0 사이라고 가정)
  final double gaugeBeforeRatio;
  final double gaugeAfterRatio;

  /// 현재 티어 (이 세션을 기록할 때의 DAO 트레이닝 티어)
  final DaoTrainingTier currentTier;

  /// 예: "XP +24 상승!", "히트율 12% 향상", "3D AVG +3.4 증가" 등
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
///
/// UI에서 아이콘 + 텍스트 형태로 변환됨
class TrainingHighlight {
  final String label; // 예: "히트율"
  final String value; // 예: "+13%"
  final String? subLabel; // 예: "이전 대비", optional
  final HighlightType type;

  const TrainingHighlight({
    required this.label,
    required this.value,
    this.subLabel,
    this.type = HighlightType.neutral,
  });
}

/// 하이라이트 항목의 의미적 색상
enum HighlightType {
  gain, // 상승(초록/네온)
  loss, // 감소(빨강)
  neutral, // 변화 없음 or 안내성
}

/// Report Builder
///
/// Session + Progress 데이터를 받아
/// TrainingReportModel 로 변환하는 helper
class TrainingReportBuilder {
  static TrainingReportModel build({
    required TrainingSessionModel session,
    required TrainingProgressModel progressBefore, // 세션 전
    required TrainingProgressModel progressAfter, // 세션 후
  }) {
    // 🔹 이번 "사이클" 기준 XP (xpSinceLastCheck)
    final int beforeXp = progressBefore.xpSinceLastCheck;
    final int afterXp = progressAfter.xpSinceLastCheck;

    // 🔹 한 사이클 목표값 (= cycleSize)
    final int target = progressAfter.cycleSize;

    // 🔹 게이지 비율 (0.0 ~ 1.0)
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
      // 🔥 티어는 세션 찍을 때 기록된 값 사용
      currentTier: session.tierAtThatTime,
      highlights: _generateHighlights(session),
    );
  }

  /// 세션 데이터 기반으로 변화 포인트 생성
  static List<TrainingHighlight> _generateHighlights(
      TrainingSessionModel s,
      ) {
    final List<TrainingHighlight> list = [];

    if (s.hitRate != null) {
      final hr = (s.hitRate! * 100).toStringAsFixed(1);
      list.add(
        TrainingHighlight(
          label: "명중률",
          value: "$hr%",
          type: s.hitRate! >= 0.5 ? HighlightType.gain : HighlightType.neutral,
        ),
      );
    }

    if (s.ppd != null) {
      list.add(
        TrainingHighlight(
          label: "PPD",
          value: s.ppd!.toStringAsFixed(2),
          type: HighlightType.neutral,
        ),
      );
    }

    if (s.mpr != null) {
      list.add(
        TrainingHighlight(
          label: "MPR",
          value: s.mpr!.toStringAsFixed(2),
          type: HighlightType.neutral,
        ),
      );
    }

    list.add(
      TrainingHighlight(
        label: "던진 다트 수",
        value: s.totalAttempts.toString(),
        type: HighlightType.neutral,
      ),
    );

    return list;
  }
}
