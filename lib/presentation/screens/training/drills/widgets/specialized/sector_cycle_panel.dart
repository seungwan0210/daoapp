// lib/presentation/screens/training/drills/widgets/specialized/sector_cycle_panel.dart

import 'package:flutter/material.dart';

/// 여러 타겟을 순서대로 돌면서 던지는 공용 패널
class SectorCyclePanel extends StatefulWidget {
  final String title;
  final List<String> targets;
  final int loopSize;
  final int totalDarts;

  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;

  /// ✅ RunScreen 기준 단일 소스
  final ValueNotifier<int> thrownDartsNotifier;

  /// ✅ Undo
  final bool canUndo;
  final VoidCallback? onUndo;

  final bool isBusy;

  const SectorCyclePanel({
    super.key,
    required this.title,
    required this.targets,
    this.loopSize = 0,
    required this.totalDarts,
    required this.thrownDartsNotifier,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.canUndo = false,
    this.onUndo,
    this.isBusy = false,
  });

  @override
  State<SectorCyclePanel> createState() => _SectorCyclePanelState();
}

class _SectorCyclePanelState extends State<SectorCyclePanel> {
  /// ✅ 패널 내부 성공/실패 히스토리
  final List<_SectorHitRecord> _hitHistory = [];

  int get _effectiveLoopSize =>
      widget.loopSize > 0 ? widget.loopSize : widget.targets.length;

  String _currentTarget(int thrown) {
    if (widget.targets.isEmpty) return '-';
    final index = thrown % _effectiveLoopSize;
    return widget.targets[index.clamp(0, widget.targets.length - 1)];
  }

  bool _isFinished(int thrown) =>
      thrown >= widget.totalDarts || widget.targets.isEmpty;

  int _successCount() =>
      _hitHistory.where((e) => e.isHit).length;

  double _successRate(int thrown) {
    if (thrown == 0) return 0;
    return (_successCount() / thrown) * 100;
  }

  void _record(bool success, int thrown) {
    if (widget.isBusy || _isFinished(thrown) || widget.targets.isEmpty) return;

    setState(() {
      _hitHistory.add(
        _SectorHitRecord(
          target: _currentTarget(thrown),
          isHit: success,
        ),
      );
    });

    if (success) {
      widget.onHitSuccess?.call();
    } else {
      widget.onHitFail?.call();
    }
  }

  void _undo(int thrown) {
    if (widget.isBusy) return;
    if (!widget.canUndo) return;
    if (_hitHistory.isEmpty || thrown <= 0) return;

    setState(() {
      _hitHistory.removeLast();
    });

    widget.onUndo?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.thrownDartsNotifier,
      builder: (_, thrown, __) {
        final successRate = _successRate(thrown);
        final isFinished = _isFinished(thrown);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),

              // ================= 상단 카드 =================
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
                    // 제목 + Undo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.onUndo != null)
                          IconButton(
                            icon: const Icon(Icons.undo, color: Colors.white),
                            onPressed: widget.canUndo
                                ? () => _undo(thrown)
                                : null,
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 타겟 칩
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: widget.targets
                          .map(
                            (t) => _TargetChip(
                          label: t,
                          isActive: t == _currentTarget(thrown),
                        ),
                      )
                          .toList(),
                    ),

                    const SizedBox(height: 20),

                    // 현재 타겟
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '현재 타겟',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentTarget(thrown),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.cyan,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildInfoRow(
                        '진행 다트', '$thrown / ${widget.totalDarts}'),
                    _buildInfoRow(
                        '성공', '${_successCount()} / $thrown'),
                    _buildInfoRow(
                      '성공률',
                      thrown == 0
                          ? '--'
                          : '${successRate.toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ================= 버튼 =================
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.isBusy || isFinished
                          ? null
                          : () => _record(true, thrown),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        '성공',
                        style: TextStyle(
                          fontSize: 22,
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
                          : () => _record(false, thrown),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        '실패',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (isFinished)
                ElevatedButton(
                  onPressed: widget.onFinishPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    '결과 확인하기',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed:
                  widget.isBusy ? null : widget.onFinishPressed,
                  child: Text(
                    '드릴 종료하고 결과 저장',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyan.shade400,
                    ),
                  ),
                ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.75))),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
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
            ? [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 2,
          )
        ]
            : null,
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white),
      ),
    );
  }
}

class _SectorHitRecord {
  final String target;
  final bool isHit;

  const _SectorHitRecord({
    required this.target,
    required this.isHit,
  });
}
