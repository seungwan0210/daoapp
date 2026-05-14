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

// 🔹 다국어 임포트
import 'package:daoapp/l10n/app_localizations.dart';

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
      return const Color(0xFFFF8EC7);
  }
}

/// ✅ 리포트 오버레이 전체 위젯
class TrainingReportOverlay extends StatelessWidget {
  final TrainingReportViewModel report;
  final DaoTrainingTier tier;
  final VoidCallback onClose;
  final VoidCallback? onGoHistory;
  final VoidCallback? onGoNextDrill;
  final VoidCallback? onGoRatingCheck;

  const TrainingReportOverlay({
    super.key,
    required this.report,
    required this.tier,
    required this.onClose,
    this.onGoHistory,
    this.onGoNextDrill,
    this.onGoRatingCheck,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final TrainingSessionModel current = report.currentSession;
    final TrainingSessionModel? previous = report.previousBestSession;
    final TrainingProgressModel? prevProgress = report.previousProgress;
    final TrainingProgressModel updatedProgress = report.updatedProgress;

    final theme = Theme.of(context);
    final dateText = DateFormat('yyyy.MM.dd HH:mm').format(current.endedAt);

    final DaoTrainingTier currentTier = tier;
    final Color tierGaugeColor = gaugeColorForTier(currentTier);
    const Color fullGaugeColor = Colors.deepPurpleAccent;

    // === 메인 지표 계산 ===
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
        mainMetricLabel = s.drill_stat_hit_rate;
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
        constraints: const BoxConstraints(maxWidth: 480, minWidth: 320),
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
              border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 1.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.auto_graph, color: Colors.cyan, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.report_header_title.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 2,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            current.drillTitle,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(dateText, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onClose,
                      child: Icon(Icons.close_rounded, color: Colors.grey[500]),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const ReportNeonSeparator(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ReportStatItem(
                        label: s.report_current_result(mainMetricLabel),
                        value: _formatMetric(currentMetric, mainMetricUnit),
                        highlight: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: previousMetric == null
                          ? ReportStatItem(
                        label: s.report_previous_record,
                        value: "—",
                        description: s.report_first_record_msg,
                      )
                          : ReportStatItem(
                        label: s.report_previous_best(mainMetricLabel),
                        value: _formatMetric(previousMetric, mainMetricUnit),
                        delta: diffMetric,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                ReportStatItem(
                  label: s.report_xp_earned,
                  value: "+$xpGained XP",
                  description: cycleSize > 0 ? s.report_xp_goal_msg(cycleSize.toString()) : null,
                  highlight: xpGained > 0,
                ),

                const SizedBox(height: 16),
                const ReportNeonSeparator(opacity: 0.25),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    s.report_growth_gauge,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
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
                  gaugeColor: tierGaugeColor,
                  fullColor: fullGaugeColor,
                ),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _buildSummaryText(
                      context: context,
                      mainMetricLabel: mainMetricLabel,
                      diffMetric: diffMetric,
                      isGaugeFull: isGaugeFull,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[800], height: 1.4),
                  ),
                ),

                const SizedBox(height: 16),
                const ReportNeonSeparator(opacity: 0.22),
                const SizedBox(height: 10),

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
    final s = AppLocalizations.of(context)!;
    if (diffMetric == null) {
      return isGaugeFull ? s.report_summary_first_max : s.report_summary_first_save;
    }
    final bool improved = diffMetric > 0;
    final double absDiff = diffMetric.abs();
    final String diffText = (mainMetricLabel == s.drill_stat_hit_rate)
        ? "${absDiff.toStringAsFixed(1)}%"
        : absDiff.toStringAsFixed(2);

    if (isGaugeFull) {
      return improved ? s.report_summary_improved(diffText, mainMetricLabel) : s.report_summary_encouragement;
    }
    if (improved) {
      return s.report_summary_improved(diffText, mainMetricLabel);
    } else if (absDiff < 0.01) {
      return s.report_summary_steady;
    } else {
      return s.report_summary_encouragement;
    }
  }

  static double? _calcHitRate(TrainingSessionModel s) {
    if (s.hitRate != null) return s.hitRate;
    if (s.totalAttempts <= 0) return null;
    return s.successCount / s.totalAttempts;
  }
  static double? _calcMpr(TrainingSessionModel s) => s.mpr;
  static double? _calcPpd(TrainingSessionModel s) {
    if (s.ppd != null) return s.ppd;
    final int? totalScore = s.totalScoreExtra;
    if (totalScore == null || s.totalAttempts <= 0) return null;
    return (totalScore / s.totalAttempts) * 3.0;
  }
  static String _formatMetric(double? value, String unit) {
    if (value == null) return "—";
    final text = (unit == '%') ? value.toStringAsFixed(1) : value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    return unit.isEmpty ? text : "$text$unit";
  }
  static double _estimateBeforeRatio(TrainingProgressModel after, int xpEarned) {
    if (after.cycleSize <= 0) return 0;
    return (after.xpSinceLastCheck - xpEarned).clamp(0, after.cycleSize) / after.cycleSize;
  }
}

class _GaugeDiffRow extends StatelessWidget {
  final double beforeRatio;
  final double afterRatio;
  final int xpBefore;
  final int xpAfter;
  final int cycleSize;
  final bool isFull;
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
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final beforePercent = (beforeRatio * 100).clamp(0, 100).toStringAsFixed(0);
    final afterPercent = (afterRatio * 100).clamp(0, 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "${s.report_gauge_before}: $beforePercent%  ($xpBefore / $cycleSize XP)",
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "${s.report_gauge_current}: $afterPercent%  ($xpAfter / $cycleSize XP)",
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
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: beforeRatio.clamp(0, 1),
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
          ),
        ),
        const SizedBox(height: 4),
        TrainingReportAnimator(
          from: beforeRatio,
          to: afterRatio,
          builder: (context, value) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value.clamp(0, 1),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(isFull ? fullColor : gaugeColor),
              ),
            );
          },
        ),
        if (isFull) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: fullColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  s.report_gauge_max_msg,
                  style: theme.textTheme.bodySmall?.copyWith(color: fullColor, fontWeight: FontWeight.w700),
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

// 🔹 [오류 해결 포인트] 헬퍼 함수를 외부에서 접근 가능하도록 파일 하단에 배치
Future<void> showTrainingReportOverlayDialog({
  required BuildContext context,
  required TrainingReportViewModel report,
  required DaoTrainingTier tier,
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
        tier: tier,
        onClose: onClose,
        onGoHistory: onGoHistory,
        onGoNextDrill: onGoNextDrill,
        onGoRatingCheck: onGoRatingCheck,
      );
    },
  );
}