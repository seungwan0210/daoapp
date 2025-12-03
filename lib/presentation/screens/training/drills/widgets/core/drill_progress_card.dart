// lib/presentation/screens/training/drills/widgets/core/drill_progress_card.dart

import 'package:flutter/material.dart';

class DrillProgressCard extends StatelessWidget {
  final double progress;
  final int thrownDarts;
  final int? totalDarts;
  final double successRate;
  final int? currentRound;
  final int? totalRounds;

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
    final String dartsText = hasTotal ? "$thrownDarts/$totalDarts" : "$thrownDarts";
    final String rateText = "${(successRate * 100).toStringAsFixed(1)}%";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          // 1. 다트 카운트
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(Icons.sports_handball, size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  dartsText,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(" 다트", style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),

          // 2. 프로그레스 바 (얇고 깔끔)
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan.shade600),
              ),
            ),
          ),

          // 3. 성공률
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  successRate >= 0.7 ? Icons.trending_up : Icons.trending_flat,
                  size: 20,
                  color: _rateColor(successRate),
                ),
                const SizedBox(width: 6),
                Text(
                  rateText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _rateColor(successRate),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}