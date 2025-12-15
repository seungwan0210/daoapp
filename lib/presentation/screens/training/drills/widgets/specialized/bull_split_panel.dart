import 'package:flutter/material.dart';

/// Bull N발 – SBull / DBull / MISS를 나눠서 기록하는 패널
class BullSplitPanel extends StatefulWidget {
  /// 상단 제목 (예: "Bull 컨트롤 90발")
  final String title;

  /// 전체 던질 다트 수 (예: 60, 90)
  final int totalDarts;

  /// 목표 SBull+DBull 개수 (없으면 표시 안 함)
  final int? targetSbPlusDb;

  /// 목표 DBull 개수 (없으면 표시 안 함)
  final int? targetDb;

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
    required this.title,
    required this.totalDarts,
    this.targetSbPlusDb,
    this.targetDb,
    this.isBusy = false,
    this.onProgress,
    this.onCompleted,
    this.onFinishPressed,
  });

  @override
  State<BullSplitPanel> createState() => _BullSplitPanelState();
}

enum _BullThrowType { sbull, dbull, miss }

class _BullSplitPanelState extends State<BullSplitPanel> {
  int _thrownDarts = 0;
  int _sBullHits = 0;
  int _dBullHits = 0;

  /// ✅ Undo용 히스토리
  final List<_BullThrowType> _history = <_BullThrowType>[];

  double get _hitRate =>
      _thrownDarts == 0 ? 0 : (_sBullHits + _dBullHits) / _thrownDarts;

  bool get _isLimitReached => _thrownDarts >= widget.totalDarts;

  bool get _canUndo => !widget.isBusy && _history.isNotEmpty;

  void _notifyProgress() {
    widget.onProgress?.call(_sBullHits, _dBullHits, _thrownDarts);
  }

  void _showAllUsedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('설정된 총 다트 수를 모두 사용했습니다.')),
    );
  }

  void _showNoUndoSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('되돌릴 기록이 없습니다.')),
    );
  }

  void _applyThrow(_BullThrowType type) {
    _thrownDarts++;
    _history.add(type);

    if (type == _BullThrowType.sbull) _sBullHits++;
    if (type == _BullThrowType.dbull) _dBullHits++;
  }

  void _revertLastThrow() {
    if (_history.isEmpty || _thrownDarts == 0) return;

    final last = _history.removeLast();
    _thrownDarts--;

    if (last == _BullThrowType.sbull && _sBullHits > 0) _sBullHits--;
    if (last == _BullThrowType.dbull && _dBullHits > 0) _dBullHits--;
    // miss는 카운트 감소 없음
  }

  void _handleThrow(_BullThrowType type) {
    if (widget.isBusy) return;
    if (_isLimitReached) {
      _showAllUsedSnack();
      return;
    }

    setState(() {
      _applyThrow(type);
    });

    _notifyProgress();

    // ✅ 전부 사용했으면 자동 안내(저장은 사용자가 누르게 유지)
    if (_isLimitReached) {
      _showAllUsedSnack();
    }
  }

  void _onTapSBull() => _handleThrow(_BullThrowType.sbull);
  void _onTapDBull() => _handleThrow(_BullThrowType.dbull);
  void _onTapMiss() => _handleThrow(_BullThrowType.miss);

  /// ✅ Undo: 직전 1발 되돌리기
  void _onTapUndo() {
    if (widget.isBusy) return;

    if (_history.isEmpty) {
      _showNoUndoSnack();
      return;
    }

    setState(() {
      _revertLastThrow();
    });

    _notifyProgress();
  }

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
    final totalTargetText = widget.targetSbPlusDb != null
        ? '목표 Bull 적중: ${widget.targetSbPlusDb} / ${widget.totalDarts}'
        : null;
    final dbTargetText = widget.targetDb != null
        ? '목표 DBull: ${widget.targetDb} / ${widget.totalDarts}'
        : null;

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
          // 🔹 상단 제목 + 총 다트 수
          Text(
            widget.title.isNotEmpty
                ? widget.title
                : 'Bull ${widget.totalDarts}발 – SBull / DBull 분리 기록',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '던진 다트: $_thrownDarts / ${widget.totalDarts}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.cyan.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
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

          const SizedBox(height: 10),

          // 🔹 목표치 안내 (있을 때만)
          if (totalTargetText != null || dbTargetText != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (totalTargetText != null)
                  Flexible(
                    child: Text(
                      totalTargetText,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
            if (dbTargetText != null) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      dbTargetText,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
          ],

          // ✅ 통계 칩 – Row + Expanded
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

          const SizedBox(height: 14),

          // ✅ Undo 버튼 (패널 자체)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _canUndo ? _onTapUndo : null,
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: const Text(
                '1발 되돌리기',
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
        fit: BoxFit.scaleDown,
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
