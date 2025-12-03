// lib/presentation/screens/training/drills/widgets/specialized/double_clock_panel.dart

import 'package:flutter/material.dart';
import '../effects/neon_glow_effect.dart';

class DoubleClockPanel extends StatefulWidget {
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;
  final bool isBusy;

  const DoubleClockPanel({
    super.key,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<DoubleClockPanel> createState() => _DoubleClockPanelState();
}

class _DoubleClockPanelState extends State<DoubleClockPanel> {
  int currentTargetIndex = 0;
  bool justHit = false;

  final List<String> doubles = [
    'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'D8', 'D9', 'D10',
    'D11', 'D12', 'D13', 'D14', 'D15', 'D16', 'D17', 'D18', 'D19', 'D20',
    'DBull',
  ];

  String get currentTarget => doubles[currentTargetIndex];
  int get totalTargets => doubles.length;
  double get progress => currentTargetIndex / totalTargets;

  void _record(bool success) {
    if (widget.isBusy) return;

    setState(() => justHit = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => justHit = false);
    });

    if (success) {
      widget.onHitSuccess?.call();
      if (currentTargetIndex < totalTargets - 1) {
        setState(() => currentTargetIndex++);
      } else {
        widget.onFinishPressed?.call();
      }
    } else {
      widget.onHitFail?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 원형 프로그레스 + 현재 타겟 (크기는 유지하되, 전체 높이 줄임)
          Container(
            width: 180,
            height: 180,
            padding: const EdgeInsets.all(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 원형 진행바
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan.shade600),
                  ),
                ),
                // 현재 타겟 (네온 강조!)
                NeonGlowEffect(
                  trigger: justHit,
                  glowColor: Colors.cyan,
                  maxGlowSize: 40,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                      border: Border.all(color: Colors.cyan, width: 3),
                    ),
                    child: Text(
                      currentTarget,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. 진행 정보 (작고 한 줄!)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              "$currentTargetIndex / $totalTargets 완료",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.cyan.shade700,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 3. 성공 / 실패 버튼 (적당한 크기!)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isBusy ? null : () => _record(true),
                  icon: const Icon(Icons.check_circle, size: 32),
                  label: const Text(
                    "성공",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isBusy ? null : () => _record(false),
                  icon: const Icon(Icons.cancel, size: 32),
                  label: const Text(
                    "실패",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
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
    );
  }
}