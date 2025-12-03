// lib/presentation/screens/training/drills/widgets/specialized/full_cricket_panel.dart

import 'package:flutter/material.dart';
import '../effects/neon_glow_effect.dart';

class FullCricketPanel extends StatefulWidget {
  final Function(int marks) onMarksRecorded;
  final VoidCallback? onFinishPressed;
  final bool isBusy;

  const FullCricketPanel({
    super.key,
    required this.onMarksRecorded,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<FullCricketPanel> createState() => _FullCricketPanelState();
}

class _FullCricketPanelState extends State<FullCricketPanel> {
  int currentRound = 1;
  final int totalRounds = 15;
  int currentMarks = 0;
  bool justScored = false;

  final List<String> numbers = ['20', '19', '18', '17', '16', '15', 'Bull'];

  void _addMark(int value) {
    if (widget.isBusy) return;

    setState(() {
      currentMarks += value;
      justScored = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => justScored = false);
    });
  }

  void _confirmRound() {
    widget.onMarksRecorded(currentMarks);

    if (currentRound < totalRounds) {
      setState(() {
        currentRound++;
        currentMarks = 0;
      });
    } else {
      widget.onFinishPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double mpr = currentRound == 1 ? 0 : (currentMarks / (currentRound - 1));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. MPR + 라운드 (한 줄로!)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.purple.shade700, Colors.indigo.shade800]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.6), blurRadius: 20)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ROUND $currentRound/$totalRounds",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Row(
                  children: [
                    const Text("MPR ", style: TextStyle(fontSize: 18, color: Colors.white70)),
                    Text(
                      mpr.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.yellowAccent,
                        shadows: [Shadow(color: Colors.yellowAccent, blurRadius: 20)],
                      ),
                    ),
                  ],
                ),
                Text(
                  "$currentMarks 마크",
                  style: const TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 2. 마크 입력 버튼 (4x2 그리드 → 작고 깔끔!)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: numbers.length,
            itemBuilder: (context, index) {
              final number = numbers[index];
              final isBull = number == 'Bull';

              return NeonGlowEffect(
                trigger: justScored && currentMarks > 0,
                glowColor: isBull ? Colors.red : Colors.cyan,
                child: ElevatedButton(
                  onPressed: widget.isBusy ? null : () => _addMark(isBull ? 3 : 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBull ? Colors.red.shade700 : Colors.cyan.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.all(8),
                    elevation: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        number,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isBull ? "+3" : "+1",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // 3. 확정 버튼 (적당한 크기!)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.isBusy || currentMarks == 0 ? null : _confirmRound,
              icon: const Icon(Icons.check_circle, size: 32),
              label: Text(
                "이번 라운드 확정 ($currentMarks 마크)",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentMarks >= 6 ? Colors.green.shade600 : Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
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
    );
  }
}