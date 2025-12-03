// lib/presentation/screens/training/drills/widgets/core/generic_hit_panel.dart

import 'package:flutter/material.dart';
import '../effects/neon_glow_effect.dart';

class GenericHitPanel extends StatelessWidget {
  final String? targetLabel;
  final String? subTarget;
  final int currentRound;
  final int totalRounds;
  final int thrownDarts;
  final int totalDarts;
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;
  final bool isBusy;

  const GenericHitPanel({
    super.key,
    this.targetLabel,
    this.subTarget,
    required this.currentRound,
    required this.totalRounds,
    required this.thrownDarts,
    required this.totalDarts,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 현재 타겟 (진짜 크게!)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.cyan.shade700, Colors.indigo.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.cyan.withOpacity(0.6), blurRadius: 30, spreadRadius: 10),
              ],
            ),
            child: Column(
              children: [
                Text(
                  targetLabel ?? "타겟",
                  style: const TextStyle(
                    fontSize: 84,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -2,
                  ),
                ),
                if (subTarget != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    subTarget!,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow.shade300,
                      shadows: const [Shadow(color: Colors.yellow, blurRadius: 20)],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 2. 진행 정보 (한 줄로!)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("ROUND $currentRound/$totalRounds", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("$thrownDarts/$totalDarts 다트", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // 3. 성공 / 실패 버튼
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isBusy ? null : onHitSuccess,
                  icon: const Icon(Icons.check_circle, size: 36),
                  label: const Text("성공", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isBusy ? null : onHitFail,
                  icon: const Icon(Icons.cancel, size: 36),
                  label: const Text("실패", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          TextButton(
            onPressed: isBusy ? null : onFinishPressed,
            child: const Text("드릴 종료하고 결과 저장", style: TextStyle(fontSize: 16, color: Colors.cyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}