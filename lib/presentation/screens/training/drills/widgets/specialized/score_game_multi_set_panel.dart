// lib/presentation/screens/training/drills/widgets/specialized/score_game_multi_set_panel.dart

import 'package:flutter/material.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 임포트 경로 수정

class ScoreGameMultiSetPanel extends StatefulWidget {
  final String title;
  final int totalSets;
  final int minDartsPerLeg;
  final int maxDartsPerLeg;
  final int successThresholdDarts;
  final bool isBusy;

  final void Function(List<int> dartsPerSet, int successCount, int playedSets)? onProgress;
  final void Function(List<int> dartsPerSet, int successCount, int playedSets)? onCompleted;
  final VoidCallback? onFinishPressed;

  const ScoreGameMultiSetPanel({
    super.key,
    required this.title,
    required this.totalSets,
    required this.minDartsPerLeg,
    required this.maxDartsPerLeg,
    required this.successThresholdDarts,
    this.isBusy = false,
    this.onProgress,
    this.onCompleted,
    this.onFinishPressed,
  });

  @override
  State<ScoreGameMultiSetPanel> createState() => _ScoreGameMultiSetPanelState();
}

class _ScoreGameMultiSetPanelState extends State<ScoreGameMultiSetPanel> {
  int _currentSet = 1;
  late int _currentDarts;
  late TextEditingController _dartsController;

  final List<int> _dartsPerSet = [];
  int _successCount = 0;
  bool _finishedAllSets = false;

  @override
  void initState() {
    super.initState();
    _currentDarts = widget.successThresholdDarts.clamp(
      widget.minDartsPerLeg,
      widget.maxDartsPerLeg,
    );
    _dartsController = TextEditingController(text: _currentDarts.toString());
  }

  @override
  void dispose() {
    _dartsController.dispose();
    super.dispose();
  }

  int get _playedSets => _dartsPerSet.length;
  int get _totalDartsUsed => _dartsPerSet.fold(0, (sum, v) => sum + v);
  double get _avgDartsPerLeg => _playedSets == 0 ? 0 : _totalDartsUsed / _playedSets;
  double get _successRate => _playedSets == 0 ? 0 : _successCount / _playedSets;
  bool get _isCompleted => _finishedAllSets;
  bool get _canUndo => _dartsPerSet.isNotEmpty && !_isCompleted;

  void _submitCurrentSet() {
    if (widget.isBusy || _isCompleted) return;
    final s = AppLocalizations.of(context)!;

    final raw = _dartsController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.drill_err_only_number)),
      );
      return;
    }

    final parsed = int.tryParse(raw);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.drill_err_only_number)),
      );
      return;
    }

    if (parsed < widget.minDartsPerLeg || parsed > widget.maxDartsPerLeg) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.drill_err_score_range),
        ),
      );
      return;
    }

    setState(() {
      _currentDarts = parsed;
      _dartsPerSet.add(_currentDarts);
      if (_currentDarts <= widget.successThresholdDarts) {
        _successCount++;
      }

      widget.onProgress?.call(List<int>.from(_dartsPerSet), _successCount, _playedSets);

      if (_currentSet >= widget.totalSets) {
        _finishedAllSets = true;
        widget.onCompleted?.call(List<int>.from(_dartsPerSet), _successCount, _playedSets);
      } else {
        _currentSet++;
        _currentDarts = widget.successThresholdDarts.clamp(widget.minDartsPerLeg, widget.maxDartsPerLeg);
        _dartsController.text = _currentDarts.toString();
      }
    });
  }

  void _undoLastSet() {
    if (widget.isBusy || !_canUndo) return;
    // 🔹 S 대신 AppLocalizations 사용
    final s = AppLocalizations.of(context)!;

    setState(() {
      final last = _dartsPerSet.removeLast();
      if (last <= widget.successThresholdDarts) _successCount--;
      _finishedAllSets = false;
      _currentSet = _playedSets + 1;
      _currentDarts = last.clamp(widget.minDartsPerLeg, widget.maxDartsPerLeg);
      _dartsController.text = _currentDarts.toString();
      widget.onProgress?.call(List<int>.from(_dartsPerSet), _successCount, _playedSets);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.calc_undo)),
    );
  }

  void _onTapFinish() {
    widget.onCompleted?.call(List<int>.from(_dartsPerSet), _successCount, _playedSets);
    widget.onFinishPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 다국어 인스턴스
    final successPercent = (_successRate * 100).toStringAsFixed(1);
    final avgDartsText = _playedSets == 0 ? '--' : _avgDartsPerLeg.toStringAsFixed(1);
    final successText = _playedSets == 0 ? '--' : '$successPercent%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),

          // 상단 카드 (타이틀 + 세트 진행)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade900, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.blueGrey.shade800, width: 1.2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.title, style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  "${s.drill_stat_rounds} $_currentSet / ${widget.totalSets}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  // 🔹 함수형 인자 호출로 수정 ({xp} 값을 직접 전달)
                  s.report_goal_standard(widget.successThresholdDarts.toString()),
                  style: const TextStyle(fontSize: 11, color: Colors.cyanAccent, fontWeight: FontWeight.w500),
                ),
                if (_playedSets > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${s.stat_success_attempt}: $_successCount / $_playedSets',
                      style: const TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 통계 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.drill_progress_title, style: TextStyle(fontSize: 12, color: Colors.grey.shade300, fontWeight: FontWeight.w600)),
                    Text("${s.drill_stat_rounds} $_playedSets / ${widget.totalSets}", style: TextStyle(fontSize: 11, color: Colors.cyan.shade300, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: widget.totalSets == 0 ? 0 : (_playedSets / widget.totalSets).clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _StatChip(label: s.common_winner, value: '$_successCount', color: Colors.greenAccent)),
                    const SizedBox(width: 6),
                    Expanded(child: _StatChip(label: s.drill_stat_success, value: successText, color: Colors.lightBlueAccent)),
                    const SizedBox(width: 6),
                    Expanded(child: _StatChip(label: s.finish_stat_avg_darts, value: avgDartsText, color: Colors.orangeAccent)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 입력 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade300)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.drill_stat_darts, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _dartsController,
                  enabled: !widget.isBusy && !_isCompleted,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    hintText: s.drill_hint_score_input,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _submitCurrentSet(),
                ),
                const SizedBox(height: 6),
                Text(
                  // 🔹 함수형 인자 호출로 수정 ({min}, {max}, {unit} 값 전달)
                  s.drill_hint_range(widget.minDartsPerLeg.toString(), widget.maxDartsPerLeg.toString(), s.drill_stat_darts),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.isBusy || _isCompleted ? null : _submitCurrentSet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          _currentSet >= widget.totalSets ? s.drill_btn_finish_save : "${s.drill_stat_rounds} $_currentSet ${s.common_confirm}",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: (widget.isBusy || !_canUndo) ? null : _undoLastSet,
                        icon: const Icon(Icons.undo, size: 18),
                        label: Text(s.calc_undo),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.orangeAccent, side: BorderSide(color: Colors.orangeAccent.withOpacity(0.7)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_isCompleted) ...[
            ElevatedButton(
              onPressed: widget.isBusy ? null : _onTapFinish,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text(s.drill_check_result, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ] else ...[
            TextButton(
              onPressed: widget.isBusy ? null : _onTapFinish,
              child: Text(s.drill_btn_finish_save, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.cyan)),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.25), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10, width: 1)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}