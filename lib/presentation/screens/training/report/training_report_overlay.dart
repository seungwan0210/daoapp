// lib/presentation/screens/training/report/training_report_overlay.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/data/models/training_progress_model.dart';
import 'package:daoapp/presentation/screens/training/widgets/report/training_report_viewmodel.dart';

// 🔹 티어 타입 import
import 'package:daoapp/core/utils/dao_training_rating_utils.dart'
    show DaoTrainingTier;

// 🔹 공용 리포트 위젯들
import 'package:daoapp/presentation/screens/training/widgets/report/report_action_buttons.dart';
import 'package:daoapp/presentation/screens/training/widgets/report/report_neon_separator.dart';
import 'package:daoapp/presentation/screens/training/widgets/report/report_stat_item.dart';
import 'package:daoapp/presentation/screens/training/widgets/report/training_report_animator.dart';

/// 🔹 티어 → 게이지 색상 매핑
Color gaugeColorForTier(DaoTrainingTier tier) {
  switch (tier) {
    case DaoTrainingTier.master:
      return Colors.deepPurpleAccent;
    case DaoTrainingTier.pro:
      return Colors.redAccent;
    case DaoTrainingTier.elite:
      return Colors.orange;
    case DaoTrainingTier.challenger:
      return Colors.green;
    case DaoTrainingTier.competitor:
      return Colors.teal;
    case DaoTrainingTier.learner:
      return Colors.blue;
    case DaoTrainingTier.beginner:
    default:
    // 비기너: 너무 어둡지 않게 살짝 튀는 핑크톤
      return const Color(0xFFFF8EC7);
  }
}

/// ✅ 리포트 오버레이 전체 위젯
class TrainingReportOverlay extends StatelessWidget {
  final TrainingReportViewModel report;

  /// ✅ DrillResultScreen 쪽에서 넘겨준 현재 티어
  final DaoTrainingTier tier;

  /// 닫기만 할 때
  final VoidCallback onClose;

  /// (선택) 히스토리로 이동
  final VoidCallback? onGoHistory;

  /// (선택) 다른 드릴/추천 연습으로 이동
  final VoidCallback? onGoNextDrill;

  /// (선택) 레이팅/레벨 체크 화면으로 이동
  final VoidCallback? onGoRatingCheck;

  const TrainingReportOverlay({
    super.key,
    required this.report,
    required this.tier,      // ✅ 추가
    required this.onClose,
    this.onGoHistory,
    this.onGoNextDrill,
    this.onGoRatingCheck,
  });

  @override
  Widget build(BuildContext context) {
    final TrainingSessionModel current = report.currentSession;
    final TrainingSessionModel? previous = report.previousBestSession;
    final TrainingProgressModel? prevProgress = report.previousProgress;
    final TrainingProgressModel updatedProgress = report.updatedProgress;

    final theme = Theme.of(context);
    final dateText = DateFormat('yyyy.MM.dd HH:mm').format(current.endedAt);

    // === 티어 기반 게이지 색상 ===
    // ✅ 더 이상 Progress에서 currentTier를 뽑지 않고,
    // DrillResultScreen에서 넘겨준 tier를 사용
    final DaoTrainingTier currentTier = tier;
    final Color tierGaugeColor = gaugeColorForTier(currentTier);
    const Color fullGaugeColor = Colors.deepPurpleAccent;

    // === 메인 지표 계산 (이번 / 이전 최고 비교) ===
    final String mainMetricLabel;
    final String mainMetricUnit;
    final double? currentMetric;
    final double? previousMetric;

    switch (current.inputModeString) {
      case 'cricketMarks':
        mainMetricLabel = 'MPR';
        mainMetricUnit = '';
        currentMetric = _calcMpr(current);
        previousMetric = previous == null ? null : _calcMpr(previous);
        break;
      case 'scoreOnly':
        mainMetricLabel = 'PPD';
        mainMetricUnit = '';
        currentMetric = _calcPpd(current);
        previousMetric = previous == null ? null : _calcPpd(previous);
        break;
      case 'hitCount':
      default:
        mainMetricLabel = '명중률';
        mainMetricUnit = '%';
        currentMetric = _calcHitRate(current) != null
            ? _calcHitRate(current)! * 100
            : null;
        previousMetric = (previous == null || _calcHitRate(previous) == null)
            ? null
            : _calcHitRate(previous)! * 100;
        break;
    }

    final double? diffMetric = (currentMetric != null && previousMetric != null)
        ? (currentMetric - previousMetric)
        : null;

    // === XP 게이지 전/후 ===
    final double beforeRatio = prevProgress != null
        ? prevProgress.progressRatio
        : _estimateBeforeRatio(updatedProgress, current.xpEarned);
    final double afterRatio = updatedProgress.progressRatio;

    final int xpGained = current.xpEarned;
    final int cycleSize = updatedProgress.cycleSize;
    final int xpBefore = (beforeRatio * cycleSize).round();
    final int xpAfter = updatedProgress.xpSinceLastCheck;

    final bool isGaugeFull = afterRatio >= 1.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 480,
          minWidth: 320,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Colors.cyan.withOpacity(0.3),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ===== 헤더 =====
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 아이콘 + 작은 태그 느낌
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_graph,
                        color: Colors.cyan,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 타이틀 / 날짜
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DAO TRAINING REPORT",
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 2,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            current.drillTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            dateText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 닫기 버튼
                    GestureDetector(
                      onTap: onClose,
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const ReportNeonSeparator(),

                // ===== 메인 지표 / 이전 최고 비교 =====
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ReportStatItem(
                        label: "이번 결과 ($mainMetricLabel)",
                        value: _formatMetric(currentMetric, mainMetricUnit),
                        highlight: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: previousMetric == null
                          ? const ReportStatItem(
                        label: "이전 기록",
                        value: "—",
                        description: "첫 기록입니다!",
                      )
                          : ReportStatItem(
                        label: "이전 최고 ($mainMetricLabel)",
                        value: _formatMetric(
                          previousMetric,
                          mainMetricUnit,
                        ),
                        delta: diffMetric,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ===== XP 지표 (핵심) =====
                ReportStatItem(
                  label: "이번 세션으로 획득한 XP",
                  value: "+$xpGained XP",
                  description: cycleSize > 0
                      ? "이번 회차 목표: $cycleSize XP 기준"
                      : null,
                  highlight: xpGained > 0,
                ),

                const SizedBox(height: 16),
                const ReportNeonSeparator(opacity: 0.25),
                const SizedBox(height: 10),

                // ===== 성장 게이지 =====
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "성장 게이지 변화",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                _GaugeDiffRow(
                  beforeRatio: beforeRatio,
                  afterRatio: afterRatio,
                  xpBefore: xpBefore,
                  xpAfter: xpAfter,
                  cycleSize: cycleSize,
                  isFull: isGaugeFull,
                  gaugeColor: tierGaugeColor, // 🔹 티어 컬러
                  fullColor: fullGaugeColor, // 🔹 MAX 시 컬러
                ),

                const SizedBox(height: 12),

                // ===== 요약 + 다음 미션 느낌 메시지 =====
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _buildSummaryText(
                      context: context,
                      mainMetricLabel: mainMetricLabel,
                      diffMetric: diffMetric,
                      isGaugeFull: isGaugeFull,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const ReportNeonSeparator(opacity: 0.22),
                const SizedBox(height: 10),

                // ===== 하단 버튼들 =====
                ReportActionButtons(
                  onClose: onClose,
                  onGoHistory: onGoHistory,
                  onGoNextDrill: onGoNextDrill,
                  onGoRatingCheck: isGaugeFull ? onGoRatingCheck : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildSummaryText({
    required BuildContext context,
    required String mainMetricLabel,
    required double? diffMetric,
    required bool isGaugeFull,
  }) {
    // 🔹 이전 기록이 없는 첫 저장
    if (diffMetric == null) {
      if (isGaugeFull) {
        return "DAO 트레이닝 첫 기록과 함께 성장 게이지가 가득 찼어요.\n"
            "이제 한 번, 레이팅/레벨 테스트로 현재 실력을 다시 확인해볼까요?\n"
            "👉 오늘 미션: 레이팅 체크 후, 이 드릴을 기준으로 루틴을 만들어보세요.";
      } else {
        return "DAO 트레이닝 첫 기록이 저장되었습니다.\n"
            "앞으로의 모든 연습이 성장 게이지에 쌓이면서 당신의 티어를 만들어갈 거예요.\n"
            "👉 오늘 미션: 같은 드릴을 한 번 더 반복해서 '내 기준 기록'을 만들어보세요.";
      }
    }

    final bool improved = diffMetric > 0;
    final double absDiff = diffMetric.abs();

    String diffText;
    if (mainMetricLabel == '명중률') {
      diffText = "${absDiff.toStringAsFixed(1)}%";
    } else {
      diffText = absDiff.toStringAsFixed(2);
    }

    // 🔹 게이지가 꽉 찼을 때: 레벨 재평가 미션
    if (isGaugeFull) {
      if (improved) {
        return "이전보다 $diffText 만큼 $mainMetricLabel이 좋아졌고,\n"
            "이번 회차 성장 게이지가 가득 찼습니다.\n"
            "👉 지금이 레이팅/레벨 재평가 딱 좋은 타이밍이에요.\n"
            "레이팅/레벨 테스트로 현재 티어를 다시 점검해보고,\n"
            "새로운 목표 티어를 하나 정해볼까요?";
      } else {
        return "이번 회차 성장 게이지가 가득 찼습니다.\n"
            "조금 기복이 있더라도 누적 실력은 분명히 올라가고 있어요.\n"
            "👉 지금 레이팅/레벨을 한 번 정리하고,\n"
            "다음 회차는 새 목표 티어를 향한 시즌 2처럼 시작해볼까요?";
      }
    }

    // 🔹 게이지가 아직 덜 찼을 때: 연습 지속 미션
    if (improved) {
      return "이전 기록보다 $diffText 만큼 $mainMetricLabel이 상승했습니다.\n"
          "페이스가 아주 좋아요.\n"
          "👉 오늘 미션: 같은 드릴을 한 번 더 진행해서\n"
          "방금 기록을 한 번 더 넘겨보는 '연속 성공'에 도전해볼까요?";
    } else if (absDiff < 0.01) {
      return "이번 연습은 이전과 거의 비슷한 수준의 결과였어요.\n"
          "이건 '내 안정적인 평균'을 잡아가는 과정입니다.\n"
          "👉 오늘 미션: 같은 드릴을 한 번 더 빠르게 진행해 보면서\n"
          "리듬과 템포를 바꾸는 실험을 해보는 건 어떨까요?";
    } else {
      return "이번 결과는 이전보다 조금 낮았지만,\n"
          "누적 연습량과 XP는 계속 쌓이고 있습니다.\n"
          "👉 오늘 미션: 이 드릴은 여기까지, 다른 유형의 드릴로\n"
          "마무리 한 번 더 해주고 내일 다시 리프레시하는 느낌으로 도전해봐요.";
    }
  }

  static double? _calcHitRate(TrainingSessionModel s) {
    if (s.hitRate != null) return s.hitRate;
    if (s.totalAttempts <= 0) return null;
    return s.successCount / s.totalAttempts;
  }

  static double? _calcMpr(TrainingSessionModel s) {
    return s.mpr;
  }

  static double? _calcPpd(TrainingSessionModel s) {
    if (s.ppd != null) return s.ppd;
    final int? totalScore = s.totalScoreExtra;
    if (totalScore == null || s.totalAttempts <= 0) return null;
    final double darts = s.totalAttempts.toDouble();
    return (totalScore / darts) * 3.0;
  }

  static String _formatMetric(double? value, String unit) {
    if (value == null) return "—";
    final String text;
    if (unit == '%') {
      text = value.toStringAsFixed(1);
    } else {
      text = value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return unit.isEmpty ? text : "$text$unit";
  }

  static double _estimateBeforeRatio(
      TrainingProgressModel after,
      int xpEarned,
      ) {
    if (after.cycleSize <= 0) return 0;
    final int before =
    (after.xpSinceLastCheck - xpEarned).clamp(0, after.cycleSize);
    return before / after.cycleSize;
  }
}

class _GaugeDiffRow extends StatelessWidget {
  final double beforeRatio;
  final double afterRatio;
  final int xpBefore;
  final int xpAfter;
  final int cycleSize;
  final bool isFull;

  /// 🔹 티어 기반 게이지 색상
  final Color gaugeColor;
  final Color fullColor;

  const _GaugeDiffRow({
    required this.beforeRatio,
    required this.afterRatio,
    required this.xpBefore,
    required this.xpAfter,
    required this.cycleSize,
    required this.isFull,
    required this.gaugeColor,
    required this.fullColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final beforePercent = (beforeRatio * 100).clamp(0, 100).toStringAsFixed(0);
    final afterPercent = (afterRatio * 100).clamp(0, 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 전/후 숫자
        Row(
          children: [
            Expanded(
              child: Text(
                "이전: $beforePercent%  ($xpBefore / $cycleSize XP)",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "현재: $afterPercent%  ($xpAfter / $cycleSize XP)",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isFull ? fullColor : gaugeColor,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // 이전 게이지 (고정)
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: beforeRatio.clamp(0, 1),
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.grey.shade400,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // 이후 게이지 (애니메이션 적용)
        TrainingReportAnimator(
          from: beforeRatio,
          to: afterRatio,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value.clamp(0, 1),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isFull ? fullColor : gaugeColor,
                ),
              ),
            );
          },
        ),

        if (isFull) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 16,
                color: fullColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "이번 회차 성장 게이지 MAX! 레벨 재평가 시점이에요.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: fullColor,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// 🔹 리포트를 다이얼로그로 띄우기 위한 헬퍼 함수
Future<void> showTrainingReportOverlayDialog({
  required BuildContext context,
  required TrainingReportViewModel report,
  required DaoTrainingTier tier,      // ✅ tier 파라미터 추가
  required VoidCallback onClose,
  VoidCallback? onGoHistory,
  VoidCallback? onGoNextDrill,
  VoidCallback? onGoRatingCheck,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (_) {
      return TrainingReportOverlay(
        report: report,
        tier: tier,                  // ✅ Overlay에 전달
        onClose: onClose,
        onGoHistory: onGoHistory,
        onGoNextDrill: onGoNextDrill,
        onGoRatingCheck: onGoRatingCheck,
      );
    },
  );
}
