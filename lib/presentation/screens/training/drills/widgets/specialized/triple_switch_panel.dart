// lib/presentation/screens/training/drills/widgets/specialized/triple_switch_panel.dart

import 'package:flutter/material.dart';
import '../core/generic_hit_panel.dart';

class TripleSwitchPanel extends StatefulWidget {
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;
  final bool isBusy;

  const TripleSwitchPanel({
    super.key,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<TripleSwitchPanel> createState() => _TripleSwitchPanelState();
}

class _TripleSwitchPanelState extends State<TripleSwitchPanel> {
  int currentSet = 1;
  final int totalSets = 30;
  int currentDartInSet = 1;

  final List<String> pattern = ['T20', 'T20', 'T19'];

  String get currentTarget => pattern[currentDartInSet - 1];
  String? get subTarget => currentDartInSet == 3 ? "마지막 다트!" : null;

  void _record(bool success) {
    if (widget.isBusy) return;

    if (success) widget.onHitSuccess?.call();
    else widget.onHitFail?.call();

    setState(() {
      if (currentDartInSet < 3) {
        currentDartInSet++;
      } else {
        if (currentSet < totalSets) {
          currentSet++;
          currentDartInSet = 1;
        } else {
          widget.onFinishPressed?.call();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 세트 + 다트 정보 (한 줄로!)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade800, Colors.indigo.shade900],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.7), blurRadius: 20)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "세트 $currentSet / $totalSets",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: currentDartInSet == 3 ? Colors.red.shade600 : Colors.cyan.shade600,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "다트 $currentDartInSet",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                Text(
                  "${(currentSet - 1) * 3 + currentDartInSet} / ${totalSets * 3} 다트",
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 2. 현재 타겟 (진짜 크게!)
          Container(
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
                  currentTarget,
                  style: const TextStyle(
                    fontSize: 84,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -2,
                  ),
                ),
                if (subTarget != null)
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
            ),
          ),

          const SizedBox(height: 40),

          // 3. 성공 / 실패 버튼 (적당한 크기!)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isBusy ? null : () => _record(true),
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
                  onPressed: widget.isBusy ? null : () => _record(false),
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
            onPressed: widget.isBusy ? null : widget.onFinishPressed,
            child: const Text("드릴 종료하고 결과 저장", style: TextStyle(fontSize: 16, color: Colors.cyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}