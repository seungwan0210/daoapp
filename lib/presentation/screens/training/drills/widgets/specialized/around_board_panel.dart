// lib/presentation/screens/training/drills/widgets/specialized/around_board_panel.dart

import 'package:flutter/material.dart';

class AroundBoardPanel extends StatefulWidget {
  final List<String> sequence;
  final ValueNotifier<int> thrownDartsNotifier; // 사용은 안 하지만 시그니처 유지
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;
  final VoidCallback? onCompleted;
  final bool isBusy;

  const AroundBoardPanel({
    super.key,
    required this.sequence,
    required this.thrownDartsNotifier,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.onCompleted,
    this.isBusy = false,
  });

  @override
  State<AroundBoardPanel> createState() => _AroundBoardPanelState();
}

class _AroundBoardPanelState extends State<AroundBoardPanel> {
  int currentIndex = 0;

  String get currentTarget => widget.sequence[currentIndex];
  int get totalTargets => widget.sequence.length;
  double get progress => currentIndex / totalTargets;

  void _record(bool success) {
    if (widget.isBusy) return;

    if (success) {
      widget.onHitSuccess?.call();

      if (currentIndex < totalTargets - 1) {
        setState(() => currentIndex++);
      } else {
        // 마지막 타겟까지 성공
        if (widget.onCompleted != null) {
          widget.onCompleted!.call();
        } else if (widget.onFinishPressed != null) {
          widget.onFinishPressed!.call();
        }
      }
    } else {
      widget.onHitFail?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBull = currentTarget == 'SB' || currentTarget == 'DBull';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 진행 정보 (더블 시계 스타일)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            "싱글 한 바퀴: $currentIndex / $totalTargets 완료",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. 원형 진행 + 현재 타겟
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isBull ? Colors.purple.shade600 : Colors.cyan.shade600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(
                    color: isBull ? Colors.purpleAccent : Colors.cyan,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentTarget,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isBull ? "BULL" : "싱글",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 3. 버튼 (더블 시계와 동일 패턴)
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.isBusy ? null : () => _record(true),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  "성공",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.isBusy ? null : () => _record(false),
                icon: const Icon(Icons.close),
                label: const Text(
                  "실패",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        TextButton(
          onPressed: widget.isBusy ? null : widget.onFinishPressed,
          child: const Text(
            "드릴 종료하고 결과 저장",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.cyan,
            ),
          ),
        ),
      ],
    );
  }
}
