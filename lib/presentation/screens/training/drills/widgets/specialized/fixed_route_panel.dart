// lib/presentation/screens/training/drills/widgets/specialized/fixed_route_panel.dart

import 'package:flutter/material.dart';
import '../effects/neon_glow_effect.dart';
import '../effects/confetti_effect.dart';
import '../effects/fireworks_effect.dart';

class FixedRoutePanel extends StatefulWidget {
  final List<String> route;        // 예: ['T20', 'T20', 'Bull']
  final String targetScore;        // 예: "170"
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;
  final bool isBusy;

  const FixedRoutePanel({
    super.key,
    required this.route,
    required this.targetScore,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<FixedRoutePanel> createState() => _FixedRoutePanelState();
}

class _FixedRoutePanelState extends State<FixedRoutePanel> {
  int currentDartIndex = 0;
  bool justSuccess = false;
  bool justFinished = false;

  String get currentTarget => widget.route[currentDartIndex];
  int get currentDart => currentDartIndex + 1;
  int get totalDarts => widget.route.length;

  void _record(bool success) {
    if (widget.isBusy) return;

    setState(() => justSuccess = success);

    if (success) {
      widget.onHitSuccess?.call();

      if (currentDartIndex < totalDarts - 1) {
        setState(() => currentDartIndex++);
      } else {
        // 170 성공!!!
        setState(() => justFinished = true);
        Future.delayed(const Duration(seconds: 6), () {
          if (mounted) setState(() => justFinished = false);
        });
        widget.onFinishPressed?.call();
      }
    } else {
      widget.onHitFail?.call();
    }

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => justSuccess = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiEffect(
      trigger: justFinished,
      duration: const Duration(seconds: 6),
      child: FireworksEffect(
        trigger: justFinished,
        duration: const Duration(seconds: 6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 목표 점수 (강렬하지만 작게!)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade700, Colors.orange.shade800],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.red.withOpacity(0.6), blurRadius: 20),
                  ],
                ),
                child: Text(
                  "${widget.targetScore} 체크아웃!",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 2. 현재 타겟 + 다트 번호
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "다트 $currentDart/$totalDarts",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 24),
                  NeonGlowEffect(
                    trigger: justSuccess,
                    glowColor: Colors.green,
                    maxGlowSize: 50,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.green, width: 3),
                      ),
                      child: Text(
                        currentTarget,
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 3. 루트 전체 보기 (작고 깔끔한 칩!)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.route.asMap().entries.map((entry) {
                  final index = entry.key;
                  final segment = entry.value;
                  final isCurrent = index == currentDartIndex;
                  final isDone = index < currentDartIndex;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDone
                          ? Colors.green.shade600
                          : isCurrent
                          ? Colors.orange.shade600
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrent ? Colors.orange.shade800 : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      segment,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDone || isCurrent ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // 4. 성공 / 실패 버튼 (적당한 크기!)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.isBusy ? null : () => _record(true),
                      icon: const Icon(Icons.check_circle, size: 32),
                      label: const Text("성공", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                      onPressed: widget.isBusy ? null : () => _record(false),
                      icon: const Icon(Icons.cancel, size: 32),
                      label: const Text("실패", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                child: const Text(
                  "드릴 종료하고 결과 저장",
                  style: TextStyle(fontSize: 16, color: Colors.cyan, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}