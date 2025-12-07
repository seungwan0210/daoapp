// lib/presentation/screens/training/drills/widgets/specialized/double_clock_panel.dart

import 'package:flutter/material.dart';

class DoubleClockPanel extends StatefulWidget {
  final int startFrom;
  final bool reverse;
  final bool includeBull;

  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;
  final bool isBusy;

  const DoubleClockPanel({
    super.key,
    this.startFrom = 1,
    this.reverse = false,
    this.includeBull = true,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<DoubleClockPanel> createState() => _DoubleClockPanelState();
}

class _DoubleClockPanelState extends State<DoubleClockPanel> {
  late List<String> _targets;
  late int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _buildTargetList();
  }

  void _buildTargetList() {
    List<String> doubles = [];

    if (widget.reverse) {
      for (int i = 20; i >= 1; i--) {
        if (i >= widget.startFrom) doubles.add('D$i');
      }
    } else {
      for (int i = widget.startFrom; i <= 20; i++) {
        doubles.add('D$i');
      }
    }

    if (widget.includeBull) doubles.add('DBull');
    _targets = doubles;
  }

  String get currentTarget => _targets[_currentIndex];
  int get totalTargets => _targets.length;
  double get progress => totalTargets == 0 ? 0.0 : _currentIndex / totalTargets;

  void _record(bool success) {
    if (widget.isBusy || _currentIndex >= totalTargets) return;

    if (success) {
      widget.onHitSuccess?.call();
      if (_currentIndex < totalTargets - 1) {
        setState(() => _currentIndex++);
      } else {
        widget.onFinishPressed?.call();
      }
    } else {
      widget.onHitFail?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFinished = _currentIndex >= totalTargets;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),

          // 상단 진행 정보 (작고 간결)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              "더블 시계${widget.startFrom > 1 ? " (뒤 절반)" : ""} · $_currentIndex / $totalTargets",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // 원형 프로그레스 + 타겟 (크기 대폭 ↓, 기존 패널들과 통일)
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan.shade600),
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

          const SizedBox(height: 28),

          // 성공 / 실패 버튼 (기존과 동일한 크기)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy || isFinished ? null : () => _record(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("성공", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy || isFinished ? null : () => _record(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("실패", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("결과 확인하기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            )
          else
            TextButton(
              onPressed: widget.isBusy ? null : widget.onFinishPressed,
              child: const Text(
                "드릴 종료하고 결과 저장",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.cyan),
              ),
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}