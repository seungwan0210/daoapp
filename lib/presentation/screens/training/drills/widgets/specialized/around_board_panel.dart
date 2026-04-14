// lib/presentation/screens/training/drills/widgets/specialized/around_board_panel.dart

import 'package:flutter/material.dart';

enum _AroundThrowResult { success, fail }

class AroundBoardPanel extends StatefulWidget {
  final List<String> sequence;
  final ValueNotifier<int> thrownDartsNotifier; // 시그니처 유지
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;
  final VoidCallback? onCompleted;
  final bool isBusy;

  // ✅ 외부(DrillRunScreen) Undo 연결용
  final bool canUndo;
  final VoidCallback? onUndo;

  const AroundBoardPanel({
    super.key,
    required this.sequence,
    required this.thrownDartsNotifier,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.onCompleted,
    this.isBusy = false,

    // ✅ 추가
    this.canUndo = false,
    this.onUndo,
  });

  @override
  State<AroundBoardPanel> createState() => _AroundBoardPanelState();
}

class _AroundBoardPanelState extends State<AroundBoardPanel> {
  int currentIndex = 0;

  /// ✅ 패널 내부 진행도 Undo용 히스토리
  final List<_AroundThrowResult> _history = [];

  String get currentTarget => widget.sequence[currentIndex];
  int get totalTargets => widget.sequence.length;

  bool get _canUndo =>
      !widget.isBusy && widget.canUndo && _history.isNotEmpty;

  /// 🔹 진행률 보정
  double get progress {
    if (totalTargets <= 1) return 0;
    return currentIndex / (totalTargets - 1);
  }

  void _record(bool success) {
    if (widget.isBusy) return;

    // ✅ "다트를 던졌다"는 카운트는 DrillRunScreen에서 처리(_recordHit)
    // 여기서는 패널 내부 진행도 + 완료 트리거를 관리
    setState(() {
      _history.add(success ? _AroundThrowResult.success : _AroundThrowResult.fail);

      if (success) {
        widget.onHitSuccess?.call();

        if (currentIndex < totalTargets - 1) {
          currentIndex++;
        } else {
          // 마지막 타겟까지 성공
          if (widget.onCompleted != null) {
            widget.onCompleted!.call();
          } else {
            widget.onFinishPressed?.call();
          }
        }
      } else {
        widget.onHitFail?.call();
      }
    });
  }

  /// ✅ Undo: 직전 시도 1회 되돌리기
  void _onUndo() {
    if (!_canUndo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('되돌릴 기록이 없습니다.')),
      );
      return;
    }

    setState(() {
      final last = _history.removeLast();

      // ✅ (중요) 패널 내부 진행도만 되돌림
      // 성공을 되돌릴 때만 인덱스 -1
      if (last == _AroundThrowResult.success && currentIndex > 0) {
        currentIndex--;
      }
    });

    // ✅ (중요) 카운트/성공률은 DrillRunScreen의 Undo로 정확히 -1 처리
    widget.onUndo?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bool isBull = currentTarget == 'SB' || currentTarget == 'DBull';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 진행 정보
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            "싱글 한 바퀴: ${currentIndex + 1} / $totalTargets 타겟",
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

        const SizedBox(height: 18),

        // ✅ Undo 버튼
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _canUndo ? _onUndo : null,
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: const Text(
              '1회 되돌리기',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
          ),
        ),

        const SizedBox(height: 6),

        // 3. 성공 / 실패 버튼
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
