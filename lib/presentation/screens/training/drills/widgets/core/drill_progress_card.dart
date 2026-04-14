// lib/presentation/screens/training/drills/widgets/core/drill_progress_card.dart

import 'package:flutter/material.dart';

class DrillProgressCard extends StatelessWidget {
  final double progress;      // 0.0 ~ 1.0
  final int thrownDarts;      // 던진 다트 수
  final int? totalDarts;      // 전체 예정 다트 수 (없으면 null)
  final double successRate;   // 0.0 ~ 1.0
  final int? currentRound;    // 현재 라운드
  final int? totalRounds;     // 전체 라운드

  const DrillProgressCard({
    super.key,
    required this.progress,
    required this.thrownDarts,
    this.totalDarts,
    required this.successRate,
    this.currentRound,
    this.totalRounds,
  });

  Color _rateColor(double rate) {
    if (rate >= 0.8) return Colors.cyan.shade600;
    if (rate >= 0.6) return Colors.green.shade600;
    if (rate >= 0.4) return Colors.amber.shade700;
    return Colors.orange.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasTotal = totalDarts != null && totalDarts! > 0;
    final int progressPercent = (progress.clamp(0.0, 1.0) * 100).round();

    final String dartsText =
    hasTotal ? "$thrownDarts / $totalDarts 다트" : "$thrownDarts 다트";

    final String roundText = (currentRound != null && totalRounds != null)
        ? "ROUND $currentRound / $totalRounds"
        : "ROUND -";

    final String successText = thrownDarts == 0
        ? "--"
        : "${(successRate * 100).toStringAsFixed(1)}%";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === 상단: 진행률 타이틀 + 퍼센트 ===
          Row(
            children: [
              const Text(
                "진행률",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "$progressPercent%",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // === 프로그레스 바 ===
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.cyan.shade600,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // === 하단: 다트 수 / 라운드 / 성공률 3칸 ===
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  label: "다트 수",
                  value: dartsText,
                  alignRight: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStat(
                  label: "라운드",
                  value: roundText,
                  alignRight: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStat(
                  label: "성공률",
                  value: successText,
                  color: thrownDarts == 0
                      ? Colors.grey.shade500
                      : _rateColor(successRate),
                  alignRight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    Color? color,
    bool alignRight = false,
  }) {
    final textAlign = alignRight ? TextAlign.end : TextAlign.start;

    return Column(
      crossAxisAlignment:
      alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
          textAlign: textAlign,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color ?? Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
        ),
      ],
    );
  }
}
