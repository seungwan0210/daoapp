// lib/presentation/screens/training/drills/widgets/specialized/double_clock_panel.dart

import 'package:flutter/material.dart';

class DoubleClockPanel extends StatefulWidget {
  final int startFrom;
  final bool reverse;
  final bool includeBull;

  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;

  /// ✅ Undo(1단계) - 부모(DrillRunScreen) attempts/success 되돌림용
  /// - wasSuccess=true면 successCount도 1 감소 처리하면 됨
  final void Function(bool wasSuccess)? onUndoResult;

  final VoidCallback? onFinishPressed;
  final bool isBusy;

  const DoubleClockPanel({
    super.key,
    this.startFrom = 1,
    this.reverse = false,
    this.includeBull = true,
    this.onHitSuccess,
    this.onHitFail,
    this.onUndoResult,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<DoubleClockPanel> createState() => _DoubleClockPanelState();
}

class _DoubleClockPanelState extends State<DoubleClockPanel> {
  late List<String> _targets;

  int _currentIndex = 0; // 현재 타겟 인덱스 (0-based)
  bool _finished = false;

  /// ✅ 로컬 Undo용 입력 히스토리 (성공/실패)
  final List<bool> _history = <bool>[];

  @override
  void initState() {
    super.initState();
    _buildTargetList();
  }

  void _buildTargetList() {
    final List<String> doubles = [];

    if (widget.reverse) {
      for (int i = 20; i >= 1; i--) {
        if (i >= widget.startFrom) doubles.add('D$i');
      }
    } else {
      for (int i = widget.startFrom; i <= 20; i++) {
        doubles.add('D$i');
      }
    }

    if (widget.includeBull) {
      doubles.add('DBull');
    }

    _targets = doubles;
  }

  int get totalTargets => _targets.length;

  String get currentTarget {
    if (_targets.isEmpty) return '-';
    final clamped = _currentIndex.clamp(0, totalTargets - 1);
    return _targets[clamped];
  }

  bool get isFinished => _finished;

  bool get _canUndo =>
      !widget.isBusy && _history.isNotEmpty && totalTargets > 0;

  /// 1-based 표시용
  int get displayStep {
    if (totalTargets == 0) return 0;
    if (_finished) return totalTargets;
    return (_currentIndex.clamp(0, totalTargets - 1)) + 1;
  }

  /// 진행도 (0.0~1.0)
  double get progress {
    if (totalTargets == 0) return 0.0;

    final completedCount = _finished ? totalTargets : _currentIndex;
    return (completedCount / totalTargets).clamp(0.0, 1.0);
  }

  void _record(bool success) {
    if (widget.isBusy || _finished || totalTargets == 0) return;

    // ✅ 히스토리 기록 (Undo 가능)
    _history.add(success);

    if (success) {
      widget.onHitSuccess?.call();

      setState(() {
        if (_currentIndex < totalTargets - 1) {
          _currentIndex++;
        } else {
          _finished = true;
        }
      });
    } else {
      widget.onHitFail?.call();
      // 실패해도 인덱스 변화 없음
      setState(() {}); // 버튼 비활성/상태 등 갱신 필요할 때 대비
    }
  }

  void _undoLast() {
    if (!_canUndo) return;

    final bool last = _history.removeLast();

    setState(() {
      if (last) {
        // ✅ 성공을 되돌릴 때
        if (_finished) {
          // 마지막 성공으로 finished=true가 된 케이스
          // (현재Index는 이미 마지막 타겟 인덱스 상태)
          _finished = false;
          // _currentIndex는 그대로(마지막 타겟 다시 도전)
        } else {
          // 중간 성공으로 인덱스가 +1 되었던 케이스
          if (_currentIndex > 0) _currentIndex--;
        }
      } else {
        // ✅ 실패 Undo는 UI 진행엔 변화 없음 (같은 타겟 유지)
        // 단, 부모 attempts는 1 감소해야 하므로 콜백은 호출
      }
    });

    // ✅ 부모(DrillRunScreen)에도 되돌렸다고 알려서
    // attempts/successCount를 같이 되돌리게 함
    widget.onUndoResult?.call(last);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),

          // 상단 진행 정보
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              "더블 시계${widget.startFrom > 1 ? " (뒤 절반)" : ""} · $displayStep / $totalTargets",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // 원형 프로그레스 + 타겟
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 9,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.cyan.shade600,
                    ),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(color: Colors.cyan, width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    currentTarget,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ✅ Undo 버튼 (1단계)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: _canUndo ? _undoLast : null,
              icon: const Icon(Icons.undo),
              tooltip: '되돌리기',
            ),
          ),

          const SizedBox(height: 8),

          // 성공 / 실패 버튼
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy || isFinished
                      ? null
                      : () => _record(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "성공",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy || isFinished
                      ? null
                      : () => _record(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "실패",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 종료 버튼
          if (isFinished)
            ElevatedButton(
              onPressed: widget.onFinishPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "결과 확인하기",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            TextButton(
              onPressed: widget.isBusy ? null : widget.onFinishPressed,
              child: const Text(
                "드릴 종료하고 결과 저장",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
