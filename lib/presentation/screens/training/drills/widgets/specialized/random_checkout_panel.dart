// lib/presentation/screens/training/drills/widgets/specialized/random_checkout_panel.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../effects/neon_glow_effect.dart';
import '../effects/confetti_effect.dart';

class RandomCheckoutPanel extends StatefulWidget {
  final int minScore;
  final int maxScore;
  final int maxDartsPerScore;   // 안내용: "최대 몇 다트 안에"
  final int totalSets;          // 예: 30세트
  final int maxDarts;
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;
  final bool isBusy;

  const RandomCheckoutPanel({
    super.key,
    this.minScore = 60,
    this.maxScore = 100,
    this.maxDartsPerScore = 6,
    this.totalSets = 30,
    this.onHitSuccess,
    this.maxDarts = 6,
    this.onHitFail,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<RandomCheckoutPanel> createState() => _RandomCheckoutPanelState();
}

class _RandomCheckoutPanelState extends State<RandomCheckoutPanel> {
  int? currentScore;
  int currentSet = 1;
  bool justSuccess = false;
  bool justFinished = false;

  // 간단하고 실제 가능한 루트 몇 개만 예시로
  final Map<int, List<String>> popularRoutes = {
    60: ['20 → D20', 'S20 → D20'],
    70: ['T18 → D8', 'T10 → D20'],
    80: ['T20 → D10', 'T16 → D16'],
    90: ['T20 → D15', 'T18 → D18'],
    100: ['T20 → D20'],
  };

  @override
  void initState() {
    super.initState();
    _generateNewScore();
  }

  void _generateNewScore() {
    final random = Random();
    currentScore = widget.minScore +
        random.nextInt(widget.maxScore - widget.minScore + 1);
    setState(() {});
  }

  void _record(bool success) {
    if (widget.isBusy || currentScore == null) return;

    setState(() {
      justSuccess = success;
    });

    // 세트 결과를 상위로 전달 (성공/실패 1번씩만)
    if (success) {
      widget.onHitSuccess?.call();
      setState(() => justFinished = true);
    } else {
      widget.onHitFail?.call();
    }

    // 애니메이션 조금 보여주고 다음 세트로
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;

      setState(() => justSuccess = false);

      // 마지막 세트였으면 종료
      if (currentSet >= widget.totalSets) {
        setState(() => justFinished = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => justFinished = false);
            widget.onFinishPressed?.call();
          }
        });
      } else {
        // 다음 세트로 진행
        setState(() {
          currentSet++;
          justFinished = false;
        });
        _generateNewScore();
      }
    });
  }

  List<String> get recommendedRoutes {
    if (currentScore == null) return const [];
    return popularRoutes[currentScore] ??
        [
          '자신 있는 루트로 마무리하세요!',
        ];
  }

  @override
  Widget build(BuildContext context) {
    if (currentScore == null) {
      return const SizedBox.shrink();
    }

    return ConfettiEffect(
      trigger: justFinished,
      duration: const Duration(seconds: 3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 세트 정보 + 남은 점수
            NeonGlowEffect(
              trigger: justSuccess,
              glowColor: Colors.green,
              maxGlowSize: 70,
              child: Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade700, Colors.orange.shade900],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.7),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "세트 $currentSet / ${widget.totalSets}",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "남은 점수",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      "$currentScore",
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "최대 ${widget.maxDartsPerScore}다트 안에 더블 아웃!",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. 추천 루트
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "추천 루트",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...recommendedRoutes.take(2).map(
                        (route) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb,
                            size: 18,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              route,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 3. 성공 / 실패 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.isBusy
                        ? null
                        : () => _record(true),
                    icon: const Icon(Icons.check_circle, size: 30),
                    label: const Text(
                      "체크아웃 성공!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.isBusy
                        ? null
                        : () => _record(false),
                    icon: const Icon(Icons.cancel, size: 30),
                    label: const Text(
                      "실패",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            TextButton(
              onPressed: widget.isBusy ? null : widget.onFinishPressed,
              child: const Text(
                "드릴 종료하고 결과 저장",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
