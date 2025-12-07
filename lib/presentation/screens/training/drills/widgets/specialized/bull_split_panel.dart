// lib/presentation/screens/training/drills/widgets/specialized/bull_split_panel.dart

import 'package:flutter/material.dart';

/// Bull N발 – SBull / DBull / MISS를 나눠서 기록하는 패널
class BullSplitPanel extends StatefulWidget {
  final int totalDarts;

  /// 저장/네트워크 작업 중 비활성화 용
  final bool isBusy;

  /// 진행 중에 매 다트마다 호출 (상단 진행 카드 갱신용)
  /// sBullHits, dBullHits, thrownDarts
  final void Function(int sBullHits, int dBullHits, int thrownDarts)?
  onProgress;

  /// 사용자가 "드릴 종료하고 결과 저장"을 눌렀을 때 최종 값 전달
  final void Function(int sBullHits, int dBullHits, int thrownDarts)?
  onCompleted;

  /// 런 스크린 쪽에서 실제 finish 처리할 때 사용
  final VoidCallback? onFinishPressed;

  const BullSplitPanel({
    super.key,
    required this.totalDarts,
    this.isBusy = false,
    this.onProgress,
    this.onCompleted,
    this.onFinishPressed,
  });

  @override
  State<BullSplitPanel> createState() => _BullSplitPanelState();
}

class _BullSplitPanelState extends State<BullSplitPanel> {
  int _thrownDarts = 0;
  int _sBullHits = 0;
  int _dBullHits = 0;

  double get _hitRate =>
      _thrownDarts == 0 ? 0 : (_sBullHits + _dBullHits) / _thrownDarts;

  void _notifyProgress() {
    widget.onProgress?.call(_sBullHits, _dBullHits, _thrownDarts);
  }

  bool get _isLimitReached => _thrownDarts >= widget.totalDarts;

  void _showAllUsedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('설정된 총 다트 수를 모두 사용했습니다.')),
    );
  }

  void _handleThrow({required bool isSBull, required bool isDBull}) {
    if (widget.isBusy) return;
    if (_isLimitReached) {
      _showAllUsedSnack();
      return;
    }

    setState(() {
      _thrownDarts++;
      if (isSBull) _sBullHits++;
      if (isDBull) _dBullHits++;
    });

    _notifyProgress();
  }

  void _onTapSBull() => _handleThrow(isSBull: true, isDBull: false);
  void _onTapDBull() => _handleThrow(isSBull: false, isDBull: true);
  void _onTapMiss() => _handleThrow(isSBull: false, isDBull: false);

  void _onTapSaveAndFinish() {
    if (widget.isBusy) return;

    // 한 발도 안 던진 상태면 그냥 종료
    if (_thrownDarts == 0) {
      widget.onFinishPressed?.call();
      return;
    }

    widget.onCompleted?.call(_sBullHits, _dBullHits, _thrownDarts);
    widget.onFinishPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hitRatePercent = (_hitRate * 100).toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Bull 60발 – SBull / DBull 분리 기록',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '던진 다트: $_thrownDarts / ${widget.totalDarts}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.cyan.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: widget.totalDarts == 0
                  ? 0
                  : (_thrownDarts / widget.totalDarts).clamp(0, 1),
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.cyan.shade600,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ✅ 통계 칩 – Row + Expanded 로 폭 고정해서 출렁임 최소화
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'SBull',
                  value: _sBullHits.toString(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'DBull',
                  value: _dBullHits.toString(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'Bull 적중률',
                  value: '$hitRatePercent%',
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // SBull / DBull / MISS 버튼 – Expanded로 3등분
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy ? null : _onTapSBull,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'SBULL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy ? null : _onTapDBull,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'DBULL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy ? null : _onTapMiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'MISS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: widget.isBusy ? null : _onTapSaveAndFinish,
            child: const Text(
              '드릴 종료하고 결과 저장',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.cyan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown, // ✅ 텍스트 길어져도 칩 안에서만 줄어듦
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
