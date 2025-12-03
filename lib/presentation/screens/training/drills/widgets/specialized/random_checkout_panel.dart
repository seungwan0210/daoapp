// lib/presentation/screens/training/drills/widgets/specialized/random_checkout_panel.dart

import 'package:flutter/material.dart';
import 'dart:math';
import '../effects/neon_glow_effect.dart';
import '../effects/confetti_effect.dart';

class RandomCheckoutPanel extends StatefulWidget {
  final int minScore;
  final int maxScore;
  final int maxDarts;
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;
  final bool isBusy;

  const RandomCheckoutPanel({
    super.key,
    this.minScore = 60,
    this.maxScore = 100,
    this.maxDarts = 6,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<RandomCheckoutPanel> createState() => _RandomCheckoutPanelState();
}

class _RandomCheckoutPanelState extends State<RandomCheckoutPanel> {
  int? currentScore;
  int dartsUsed = 0;
  bool justSuccess = false;
  bool justFinished = false;

  final Map<int, List<String>> popularRoutes = {
    60: ['D30'],
    70: ['T10→D20', 'D20→D15'],
    80: ['T20→D10', 'T16→D16'],
    90: ['T18→D18', 'T20→D15'],
    100: ['T20→D20', 'T18→D23'],
    110: ['T20→D25', 'T18→D28'],
    120: ['T20→T20→D0', 'T20→D50'],
  };

  @override
  void initState() {
    super.initState();
    _generateNewScore();
  }

  void _generateNewScore() {
    final random = Random();
    currentScore = widget.minScore + random.nextInt(widget.maxScore - widget.minScore + 1);
    dartsUsed = 0;
    setState(() {});
  }

  void _record(bool success) {
    if (widget.isBusy || currentScore == null) return;

    setState(() {
      dartsUsed++;
      justSuccess = success;
    });

    if (success) {
      widget.onHitSuccess?.call();
      setState(() => justFinished = true);
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => justFinished = false);
          _generateNewScore();
        }
      });
    } else {
      widget.onHitFail?.call();
      if (dartsUsed >= widget.maxDarts) {
        Future.delayed(const Duration(seconds: 1), _generateNewScore);
      }
    }

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => justSuccess = false);
    });
  }

  List<String> get recommendedRoutes {
    return popularRoutes[currentScore] ?? ['자유롭게 마무리하세요!'];
  }

  @override
  Widget build(BuildContext context) {
    if (currentScore == null) return const SizedBox.shrink();

    return ConfettiEffect(
      trigger: justFinished,
      duration: const Duration(seconds: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 남은 점수 (진짜 크게 + 네온!)
            NeonGlowEffect(
              trigger: justSuccess,
              glowColor: Colors.green,
              maxGlowSize: 70,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade700, Colors.orange.shade900],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.7), blurRadius: 30)],
                ),
                child: Column(
                  children: [
                    Text(
                      "남은 점수",
                      style: const TextStyle(fontSize: 22, color: Colors.white70),
                    ),
                    Text(
                      "$currentScore",
                      style: const TextStyle(
                        fontSize: 84,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    Text(
                      "$dartsUsed / ${widget.maxDarts} 다트",
                      style: const TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // 2. 추천 루트 (작고 한 줄!)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("추천 루트", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...recommendedRoutes.take(2).map((route) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb, size: 18, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(route, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  )),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // 3. 성공 / 실패 버튼 (적당한 크기!)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.isBusy || dartsUsed >= widget.maxDarts ? null : () => _record(true),
                    icon: const Icon(Icons.check_circle, size: 32),
                    label: const Text("체크아웃 성공!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.isBusy || dartsUsed >= widget.maxDarts ? null : () => _record(false),
                    icon: const Icon(Icons.cancel, size: 32),
                    label: const Text("실패", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            TextButton(
              onPressed: widget.isBusy ? null : widget.onFinishPressed,
              child: const Text("드릴 종료하고 결과 저장", style: TextStyle(fontSize: 16, color: Colors.cyan, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}