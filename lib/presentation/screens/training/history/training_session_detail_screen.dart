import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/data/models/training_progress_model.dart';

/// 티어 색상 (오버레이와 동일하게 유지)
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
    default:
      return const Color(0xFFFF8EC7);
  }
}

class TrainingSessionDetailScreen extends StatelessWidget {
  final TrainingSessionModel session;
  final TrainingSessionModel? previousBest;     // 🔹 이전 기록 (선택)
  final TrainingProgressModel? progressBefore;  // 🔹 이전 Progress (선택)
  final TrainingProgressModel? progressAfter;   // 🔹 저장된 Progress (선택)

  const TrainingSessionDetailScreen({
    super.key,
    required this.session,
    this.previousBest,
    this.progressBefore,
    this.progressAfter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // === 날짜 ===
    final String dateText =
    DateFormat('yyyy.MM.dd HH:mm').format(session.endedAt);

    // === 메인 지표 계산 ===
    final metric = _calcMainMetric(session);
    final metricLabel = metric.label;
    final metricValue = metric.value;

    final metricPrevValue =
    previousBest == null ? null : _calcMainMetric(previousBest!).value;

    final diffMetric = (metricValue != null && metricPrevValue != null)
        ? metricValue - metricPrevValue
        : null;

    // === XP Progress ===
    final currentTier = session.tierAtThatTime;
    final gaugeColor = gaugeColorForTier(currentTier);

    final beforeRatio = progressBefore?.progressRatio ?? 0;
    final afterRatio = progressAfter?.progressRatio ?? beforeRatio;
    final xpBefore = progressBefore?.xpSinceLastCheck ?? 0;
    final xpAfter = progressAfter?.xpSinceLastCheck ?? session.xpEarned;
    final cycleSize = progressAfter?.cycleSize ?? 1000;
    final isFull = afterRatio >= 1.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          "트레이닝 상세",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade300, height: 1),
        ),
      ),

      /// 전체 스크롤
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          // =========================
          // HEADER
          // =========================
          _buildHeaderCard(context, dateText),

          const SizedBox(height: 20),

          // =========================
          // MAIN METRIC
          // =========================
          _buildMainMetricCard(
            label: metricLabel,
            current: metricValue,
            previous: metricPrevValue,
            diff: diffMetric,
          ),

          const SizedBox(height: 20),

          // =========================
          // SUCCESS RATE (if hit mode)
          // =========================
          if (metricLabel == "명중률")
            _buildSuccessRateCard(
              session.hitRate ?? 0,
              session.successCount,
              session.totalAttempts,
            ),

          const SizedBox(height: 20),

          // =========================
          // XP / 성장 게이지
          // =========================
          _buildXPCard(
            context,
            tier: currentTier,
            xp: session.xpEarned,
            beforeRatio: beforeRatio,
            afterRatio: afterRatio,
            xpBefore: xpBefore,
            xpAfter: xpAfter,
            cycleSize: cycleSize,
            isFull: isFull,
          ),

          const SizedBox(height: 20),

          // =========================
          // 요약 메시지
          // =========================
          _buildSummaryMessage(
            context,
            metricLabel: metricLabel,
            diffMetric: diffMetric,
            isFull: isFull,
          ),

          const SizedBox(height: 20),

          // =========================
          // 드릴 설정 정보 (접기)
          // =========================
          if (session.extra != null && session.extra!.isNotEmpty)
            _buildExtraInfo(),
        ],
      ),
    );
  }

  // ---------------------------------------------
  // HEADER
  // ---------------------------------------------
  Widget _buildHeaderCard(BuildContext context, String dateText) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _box,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.drillTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateText,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------
  // MAIN METRIC
  // ---------------------------------------------
  Widget _buildMainMetricCard({
    required String label,
    required double? current,
    required double? previous,
    required double? diff,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: _box,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "이번 결과 ($label)",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _formatMetric(current, label),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 16),

          // 이전 기록이 있을 때만
          if (previous != null)
            Row(
              children: [
                const Text(
                  "이전 최고:",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatMetric(previous, label),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: diff != null && diff > 0
                        ? Colors.green
                        : Colors.grey[700],
                  ),
                ),
                if (diff != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      diff > 0
                          ? "(+${diff.toStringAsFixed(label == "명중률" ? 1 : 2)})"
                          : "(${diff.toStringAsFixed(label == "명중률" ? 1 : 2)})",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: diff > 0 ? Colors.green : Colors.redAccent,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------
  // SUCCESS RATE CARD
  // ---------------------------------------------
  Widget _buildSuccessRateCard(
      double hitRate, int success, int attempts) {
    final percent = (hitRate * 100).toStringAsFixed(1);
    final color = hitRate >= 0.8
        ? Colors.cyan.shade700
        : hitRate >= 0.6
        ? Colors.green.shade600
        : hitRate >= 0.4
        ? Colors.amber.shade700
        : Colors.orange.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: _box,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text("성공률", style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 12),
                Text(
                  "$percent%",
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1.2, height: 70, color: Colors.grey[300]),
          Expanded(
            child: Column(
              children: [
                Text("성공 / 시도", style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 12),
                Text(
                  "$success / $attempts",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------
  // XP + 게이지
  // ---------------------------------------------
  Widget _buildXPCard(
      BuildContext context, {
        required DaoTrainingTier tier,
        required int xp,
        required double beforeRatio,
        required double afterRatio,
        required int xpBefore,
        required int xpAfter,
        required int cycleSize,
        required bool isFull,
      }) {
    final theme = Theme.of(context);

    // 👇 이 줄 추가
    final Color gaugeColor = Colors.cyan.shade600;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _box,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("성장 게이지", style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),

          // 전/후 텍스트
          Text(
            "획득 XP: +$xp",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          Text(
            "현재 티어: ${tier.name.toUpperCase()}",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // 게이지
          LinearProgressIndicator(
            value: afterRatio.clamp(0, 1),
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              isFull ? Colors.deepPurpleAccent : gaugeColor,
            ),
          ),

          const SizedBox(height: 12),
          Text(
            "${(afterRatio * 100).floor()}%  ($xpAfter / $cycleSize XP)",
            style: TextStyle(
              color: isFull ? Colors.deepPurpleAccent : gaugeColor,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (isFull) ...[
            const SizedBox(height: 10),
            Text(
              "🚀 성장 게이지가 가득 찼습니다! 레베루/레이팅 재확인 시점이에요.",
              style: TextStyle(
                color: Colors.deepPurpleAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------
  // SUMMARY MESSAGE
  // ---------------------------------------------
  Widget _buildSummaryMessage(
      BuildContext context, {
        required String metricLabel,
        required double? diffMetric,
        required bool isFull,
      }) {
    final message = _buildSummaryText(
      metricLabel: metricLabel,
      diffMetric: diffMetric,
      isGaugeFull: isFull,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _box,
      child: Text(
        message,
        style: TextStyle(height: 1.5, color: Colors.grey[800]),
      ),
    );
  }

  // ---------------------------------------------
  // EXTRA INFO (Foldable)
  // ---------------------------------------------
  Widget _buildExtraInfo() {
    return Container(
      decoration: _box,
      child: ExpansionTile(
        title: const Text("드릴 설정 정보"),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: SelectableText(
              session.extra.toString(),
              style: const TextStyle(
                fontFamily: "RobotoMono",
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //---------------------------------------------------------
  // SUMMARY TEXT LOGIC
  //---------------------------------------------------------
  String _buildSummaryText({
    required String metricLabel,
    required double? diffMetric,
    required bool isGaugeFull,
  }) {
    // 처음 기록
    if (diffMetric == null) {
      return isGaugeFull
          ? "DAO 트레이닝 첫 기록과 함께 성장 게이지가 가득 찼어요.\n한 번 레이팅/레벨을 다시 확인해보면 좋겠어요!"
          : "DAO 트레이닝 첫 기록입니다.\n오늘 한 번 더 반복해서 나만의 기준 기록을 만들어보세요.";
    }

    final bool improved = diffMetric > 0;
    final absDiff = diffMetric.abs();

    if (isGaugeFull) {
      return improved
          ? "$metricLabel이 ${absDiff.toStringAsFixed(2)} 만큼 상승했고 성장 게이지가 가득 찼어요.\n지금은 레벨/레이팅 재평가하기 좋은 시점이에요."
          : "오늘 기록은 조금 낮았지만 누적 성장은 분명히 이루어지고 있어요.\n성장 게이지가 가득 찼으니 레벨 확인을 해볼까요?";
    }

    if (improved) {
      return "이전보다 ${absDiff.toStringAsFixed(2)} 만큼 $metricLabel이 좋아졌어요.\n오늘 페이스가 좋네요! 한 번 더 도전해보세요.";
    } else if (absDiff < 0.01) {
      return "이번 기록은 이전과 거의 동일했어요.\n안정적인 평균 실력을 잡아가는 과정입니다.";
    } else {
      return "오늘 기록은 다소 낮았지만, XP는 계속 성장 중이에요.\n다른 드릴로 마무리 후 내일 다시 도전해보세요!";
    }
  }

  //---------------------------------------------------------
  // METRIC CALC LOGIC
  //---------------------------------------------------------
  _MetricResult _calcMainMetric(TrainingSessionModel s) {
    switch (s.inputModeString) {
      case 'cricketMarks':
        return _MetricResult('MPR', s.mpr);
      case 'scoreOnly':
        return _MetricResult('PPD', s.ppd);
      default:
        final rate = s.hitRate != null ? s.hitRate! * 100 : null;
        return _MetricResult('명중률', rate);
    }
  }

  String _formatMetric(double? value, String label) {
    if (value == null) return "—";
    if (label == "명중률") {
      return "${value.toStringAsFixed(1)}%";
    }
    return value.toStringAsFixed(2);
  }

  // 공통 박스 데코
  BoxDecoration get _box => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 12,
      ),
    ],
  );
}

// 메트릭 구조체
class _MetricResult {
  final String label;
  final double? value;
  _MetricResult(this.label, this.value);
}
