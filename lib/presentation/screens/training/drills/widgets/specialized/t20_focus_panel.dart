// lib/presentation/screens/training/drills/widgets/specialized/t20_focus_panel.dart

import 'package:flutter/material.dart';
import '../effects/neon_glow_effect.dart';
import '../effects/confetti_effect.dart';

class T20FocusPanel extends StatefulWidget {
  final int totalDarts;
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;
  final bool isBusy;

  const T20FocusPanel({
    super.key,
    required this.totalDarts,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<T20FocusPanel> createState() => _T20FocusPanelState();
}

class _T20FocusPanelState extends State<T20FocusPanel> {
  int dartsThrown = 0;
  int t20Hits = 0;
  bool justHit = false;

  double get successRate => dartsThrown == 0 ? 0 : t20Hits / dartsThrown;
  int get remainingDarts => widget.totalDarts - dartsThrown;
  bool get isFinished => dartsThrown >= widget.totalDarts;

  void _record(bool isT20) {
    if (widget.isBusy || isFinished) return;

    setState(() {
      dartsThrown++;
      if (isT20) {
        t20Hits++;
        justHit = true;
      }
    });

    if (isT20) widget.onHitSuccess?.call();
    else widget.onHitFail?.call();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => justHit = false);
    });

    if (isFinished) {
      Future.delayed(const Duration(seconds: 1), widget.onFinishPressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiEffect(
      trigger: isFinished && successRate >= 0.5,
      duration: const Duration(seconds: 5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. T20 (진짜 크게!)
            NeonGlowEffect(
              trigger: justHit,
              glowColor: Colors.red,
              maxGlowSize: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.red.shade700, width: 4),
                  boxShadow: [
                    BoxShadow(color: Colors.red.withOpacity(0.8), blurRadius: 40, spreadRadius: 10),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "T20",
                    style: TextStyle(
                      fontSize: 96,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -4,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 2. 핵심 정보 한 줄!
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoChip("던진", "$dartsThrown", Colors.cyan),
                  _infoChip("명중", "$t20Hits", Colors.red),
                  _infoChip("성공률", "${(successRate * 100).toStringAsFixed(1)}%",
                      successRate >= 0.5 ? Colors.green : Colors.orange),
                  if (!isFinished)
                    _infoChip("남은", "$remainingDarts", Colors.white70),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 3. 성공 / 실패 버튼 (적당히!)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.isBusy || isFinished ? null : () => _record(true),
                    icon: const Icon(Icons.whatshot, size: 36),
                    label: const Text("T20 명중!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.isBusy || isFinished ? null : () => _record(false),
                    icon: const Icon(Icons.close, size: 36),
                    label: const Text("미스", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              ],
            ),

            if (isFinished) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: widget.onFinishPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                ),
                child: const Text("결과 확인하기", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ] else
              const SizedBox(height: 20),

            if (!isFinished)
              TextButton(
                onPressed: widget.onFinishPressed,
                child: const Text("드릴 종료하고 결과 저장", style: TextStyle(fontSize: 16, color: Colors.cyan, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}