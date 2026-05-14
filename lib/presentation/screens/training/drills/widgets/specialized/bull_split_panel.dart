// lib/presentation/screens/training/drills/widgets/specialized/bull_split_panel.dart

import 'package:flutter/material.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 임포트 경로 수정

class BullSplitPanel extends StatefulWidget {
  final String title;
  final int totalDarts;
  final int? targetSbPlusDb;
  final int? targetDb;
  final bool isBusy;

  final void Function(int sBullHits, int dBullHits, int thrownDarts)? onProgress;
  final void Function(int sBullHits, int dBullHits, int thrownDarts)? onCompleted;
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

  final List<_BullThrowType> _history = <_BullThrowType>[];

  double get _hitRate =>
      _thrownDarts == 0 ? 0 : (_sBullHits + _dBullHits) / _thrownDarts;

  bool get _isLimitReached => _thrownDarts >= widget.totalDarts;
  bool get _canUndo => !widget.isBusy && _history.isNotEmpty;

  void _notifyProgress() {
    widget.onProgress?.call(_sBullHits, _dBullHits, _thrownDarts);
  }

  void _showAllUsedSnack() {
    final s = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.drill_msg_limit_reached)),
    );
  }

  void _showNoUndoSnack() {
    final s = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.drill_msg_no_undo)),
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
    if (_isLimitReached) _showAllUsedSnack();
  }

  // 🔹 누락되었던 탭 메서드들 추가
  void _onTapSBull() => _handleThrow(_BullThrowType.sbull);
  void _onTapDBull() => _handleThrow(_BullThrowType.dbull);
  void _onTapMiss() => _handleThrow(_BullThrowType.miss);

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
    if (_thrownDarts == 0) {
      widget.onFinishPressed?.call();
      return;
    }
    widget.onCompleted?.call(_sBullHits, _dBullHits, _thrownDarts);
    widget.onFinishPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 S 대신 AppLocalizations 사용
    final hitRatePercent = (_hitRate * 100).toStringAsFixed(1);

    // 🔹 목표 텍스트 다국어화 (함수형 호출로 수정)
    final totalTargetText = widget.targetSbPlusDb != null
        ? s.drill_target_bull(widget.targetSbPlusDb.toString(), widget.totalDarts.toString())
        : null;

    final dbTargetText = widget.targetDb != null
        ? 'Target DBull: ${widget.targetDb} / ${widget.totalDarts}'
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
          // 🔹 상단 제목 (함수형 호출로 수정)
          Text(
            widget.title.isNotEmpty
                ? widget.title
                : s.drill_bull_title(widget.totalDarts.toString()),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${s.drill_stat_darts}: $_thrownDarts / ${widget.totalDarts}',
            style: TextStyle(fontSize: 13, color: Colors.cyan.shade700, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: widget.totalDarts == 0 ? 0 : (_thrownDarts / widget.totalDarts).clamp(0, 1),
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan.shade600),
            ),
          ),

          const SizedBox(height: 10),

          // 목표치 안내
          if (totalTargetText != null || dbTargetText != null) ...[
            if (totalTargetText != null)
              Text(totalTargetText, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
            if (dbTargetText != null)
              Text(dbTargetText, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
          ],

          // 통계 칩
          Row(
            children: [
              Expanded(child: _StatChip(label: 'SBull', value: _sBullHits.toString())),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(label: 'DBull', value: _dBullHits.toString())),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(label: s.drill_stat_bull_rate, value: '$hitRatePercent%')),
            ],
          ),

          const SizedBox(height: 14),

          // ✅ Undo 버튼
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _canUndo ? _onTapUndo : null,
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: Text(s.drill_btn_undo_last, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          ),

          const SizedBox(height: 6),

          // 입력 버튼
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy ? null : _onTapSBull,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('SBULL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('DBULL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('MISS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: widget.isBusy ? null : _onTapSaveAndFinish,
            child: Text(s.drill_btn_finish_save, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.cyan)),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

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
            Text('$label: ', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}