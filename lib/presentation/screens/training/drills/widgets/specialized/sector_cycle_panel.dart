// lib/presentation/screens/training/drills/widgets/specialized/sector_cycle_panel.dart

import 'package:flutter/material.dart';

/// 여러 타겟을 순서대로 돌면서 던지는 공용 패널
/// - title: 상단에 표시할 드릴 이름 (예: "20 / 19 스위치")
/// - targets: 순환할 타겟 리스트 (예: ['T20', 'T19'])
/// - loopSize: targets 리스트 길이와 다르게 반복하고 싶을 때 (보통 targets.length 와 동일)
class SectorCyclePanel extends StatefulWidget {
  final String title;                     // ← 추가
  final List<String> targets;
  final int loopSize;                     // ← 추가 (targets.length 와 같아도 됨)
  final int totalDarts;
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;
  final bool isBusy;

  const SectorCyclePanel({
    super.key,
    required this.title,                  // ← 필수
    required this.targets,
    this.loopSize = 0,                    // 0이면 targets.length 사용
    required this.totalDarts,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<SectorCyclePanel> createState() => _SectorCyclePanelState();
}

class _SectorCyclePanelState extends State<SectorCyclePanel> {
  int _thrown = 0;
  int _successCount = 0;

  int get _effectiveLoopSize => widget.loopSize > 0 ? widget.loopSize : widget.targets.length;

  bool get _isFinished => _thrown >= widget.totalDarts || widget.targets.isEmpty;

  String get _currentTarget {
    if (widget.targets.isEmpty) return '-';
    final index = _thrown % _effectiveLoopSize;
    return widget.targets[index.clamp(0, widget.targets.length - 1)];
  }

  void _record(bool success) {
    if (widget.isBusy || _isFinished || widget.targets.isEmpty) return;

    setState(() {
      _thrown++;
      if (success) _successCount++;
    });

    if (success) {
      widget.onHitSuccess?.call();
    } else {
      widget.onHitFail?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double successRate = _thrown == 0 ? 0 : (_successCount / _thrown) * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),

          // 상단 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 드릴 제목
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // 타겟 칩들
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.targets
                      .asMap()
                      .entries
                      .map((e) => _TargetChip(
                    label: e.value,
                    isActive: e.value == _currentTarget,
                  ))
                      .toList(),
                ),

                const SizedBox(height: 20),

                // 현재 타겟 크게 표시
                Center(
                  child: Column(
                    children: [
                      Text(
                        '현재 타겟',
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.75)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentTarget,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.cyan,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 진행 정보
                _buildInfoRow('진행 다트', '$_thrown / ${widget.totalDarts} 다트'),
                _buildInfoRow('성공', '$_successCount / $_thrown'),
                _buildInfoRow(
                  '성공률',
                  _thrown == 0 ? '--' : '${successRate.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 성공 / 실패 버튼
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy || _isFinished ? null : () => _record(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 10,
                  ),
                  child: const Text('성공', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy || _isFinished ? null : () => _record(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 10,
                  ),
                  child: const Text('실패', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 종료 버튼
          if (_isFinished)
            ElevatedButton(
              onPressed: widget.onFinishPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade600,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 12,
              ),
              child: const Text('결과 확인하기', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            )
          else
            TextButton(
              onPressed: widget.isBusy ? null : widget.onFinishPressed,
              child: Text(
                '드릴 종료하고 결과 저장',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.cyan.shade400),
              ),
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _TargetChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.cyan.shade600 : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive
            ? [BoxShadow(color: Colors.cyan.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)]
            : null,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}