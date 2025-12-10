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
      return Colors.grey;
  }
}

/// ✅ 리포트 오버레이 전체 위젯
class TrainingReportOverlay extends StatelessWidget {
  final TrainingReportViewModel report;

  /// 현재 세션의 티어 (게이지 색상에 사용)
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
    required this.tier, // 🔹 티어 전달
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
    final Color tierGaugeColor = gaugeColorForTier(tier);
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
        mainMetricLabel = '명중률';
        mainMetricUnit = '%';
        currentMetric =
        _calcHitRate(current) != null ? _calcHitRate(current)! * 100 : null;
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
                            previousMetric, mainMetricUnit),
                        delta: diffMetric,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ===== 보조 지표 (다트 수, 라운드 수) =====
                Row(
                  children: [
                    Expanded(
                      child: ReportStatItem(
                        label: "던진 다트 수",
                        value: "${current.totalAttempts} darts",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ReportStatItem(
                        label: "라운드 수",
                        value: "${current.totalRounds} R",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ===== XP 지표 =====
                ReportStatItem(
                  label: "이번 세션으로 획득한 XP",
                  value: "+$xpGained XP",
                  description:
                  cycleSize > 0 ? "현재 회차 목표: $cycleSize XP" : null,
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
                const SizedBox(height: 8),

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

                // ===== 요약 메시지 =====
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
                      color: Colors.grey[700],
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
    if (diffMetric == null) {
      // 이전 기록 없음 = 첫 기록
      return isGaugeFull
          ? "DAO 트레이닝 첫 기록과 함께 성장 게이지가 가득 찼어요.\n레이팅/레벨 테스트로 현재 실력을 다시 확인해보세요."
          : "DAO 트레이닝 첫 기록이 저장되었습니다.\n앞으로의 연습이 모두 성장 게이지에 쌓입니다.";
    }

    final bool improved = diffMetric > 0;
    final double absDiff = diffMetric.abs();

    String diffText;
    if (mainMetricLabel == '명중률') {
      diffText = "${absDiff.toStringAsFixed(1)}%";
    } else {
      diffText = absDiff.toStringAsFixed(2);
    }

    if (isGaugeFull) {
      return improved
          ? "이전보다 $diffText 만큼 $mainMetricLabel이 좋아졌고,\n이번 회차 성장 게이지가 가득 찼습니다.\n레이팅/레벨 테스트로 현재 티어를 다시 점검해보세요!"
          : "이번 회차 성장 게이지가 가득 찼습니다.\n레이팅/레벨 테스트로 현재 티어를 다시 점검해보세요.";
    }

    if (improved) {
      return "이전 기록보다 $diffText 만큼 $mainMetricLabel이 상승했습니다.\n이 페이스로 계속 연습하면 곧 레벨업을 기대할 수 있어요.";
    } else if (absDiff < 0.01) {
      return "이번 연습은 이전과 비슷한 수준의 결과였어요.\n조금 더 집중해서 같은 드릴을 한 번 더 반복해볼까요?";
    } else {
      return "이번 결과는 이전보다 조금 낮았지만,\n누적 연습량은 계속 쌓이고 있습니다.\n내일 다시 리프레시하는 느낌으로 도전해봐요.";
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
  required DaoTrainingTier tier, // 🔹 티어 추가
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
        tier: tier, // 🔹 여기서 전달
        onClose: onClose,
        onGoHistory: onGoHistory,
        onGoNextDrill: onGoNextDrill,
        onGoRatingCheck: onGoRatingCheck,
      );
    },
  );
}
