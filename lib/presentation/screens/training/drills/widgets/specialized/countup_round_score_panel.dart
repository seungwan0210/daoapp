// lib/presentation/screens/training/drills/widgets/specialized/countup_round_score_panel.dart

import 'package:flutter/material.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 임포트 경로 수정

class CountUpRoundScorePanel extends StatefulWidget {
  final int currentRound;
  final int totalRounds;
  final int accumulatedScore;
  final ValueChanged<int> onRoundSubmitted;
  final VoidCallback? onUndoLastRound;
  final VoidCallback? onFinishPressed;
  final bool isBusy;

  const CountUpRoundScorePanel({
    super.key,
    required this.currentRound,
    required this.totalRounds,
    required this.accumulatedScore,
    required this.onRoundSubmitted,
    this.onUndoLastRound,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<CountUpRoundScorePanel> createState() => _CountUpRoundScorePanelState();
}

class _CountUpRoundScorePanelState extends State<CountUpRoundScorePanel> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;
  String _prevText = '';

  bool get _canUndoInput =>
      !widget.isBusy &&
          _prevText.isNotEmpty &&
          _prevText != _controller.text;

  bool get _canUndoRound =>
      !widget.isBusy &&
          widget.onUndoLastRound != null &&
          widget.currentRound > 1;

  @override
  void initState() {
    super.initState();
    _prevText = _controller.text;

    _controller.addListener(() {
      if (_errorText != null) {
        setState(() => _errorText = null);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _stashPrev() {
    _prevText = _controller.text;
  }

  void _undoInput() {
    if (!_canUndoInput) return;
    final String current = _controller.text;
    setState(() {
      _controller.text = _prevText;
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
      _prevText = current;
      _errorText = null;
    });
  }

  void _submit() {
    if (widget.isBusy) return;
    _stashPrev();

    final s = AppLocalizations.of(context)!; // 🔹 S 대신 AppLocalizations 사용
    final raw = _controller.text.trim();

    if (raw.isEmpty) {
      setState(() => _errorText = s.drill_hint_round_score);
      return;
    }

    final value = int.tryParse(raw);
    if (value == null) {
      setState(() => _errorText = s.drill_err_only_number);
      return;
    }

    if (value < 0 || value > 180) {
      setState(() => _errorText = s.drill_err_score_range);
      return;
    }

    setState(() => _errorText = null);
    widget.onRoundSubmitted(value);
    _controller.clear();
    _prevText = '';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 다국어 인스턴스

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 제목 + 라운드 정보
          Text(
            s.drill_confirm_score,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            "ROUND ${widget.currentRound} / ${widget.totalRounds}",
            style: TextStyle(
              fontSize: 13,
              color: Colors.cyan.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          // 누적 총점 표시
          Text(
            // 🔹 함수형 인자 호출로 수정 ({score} 값 전달)
            s.drill_current_score(widget.accumulatedScore.toString()),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          // 점수 입력 필드
          TextField(
            controller: _controller,
            enabled: !widget.isBusy,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              hintText: s.drill_hint_round_score,
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.cyan.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.cyan, width: 2),
              ),
              errorText: _errorText,
            ),
            onTap: _stashPrev,
            onSubmitted: (_) => _submit(),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: Text(
                    s.drill_confirm_score,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 54,
                height: 48,
                child: OutlinedButton(
                  onPressed: _canUndoInput ? _undoInput : null,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: _canUndoInput ? Colors.grey.shade400 : Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.undo, size: 20),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 직전 라운드 Undo
          if (widget.onUndoLastRound != null) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _canUndoRound ? widget.onUndoLastRound : null,
                icon: const Icon(Icons.undo),
                label: Text(
                  s.calc_undo, // 🔹 좀 더 범용적인 '되돌리기' 키 사용
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 종료 버튼
          TextButton(
            onPressed: widget.isBusy ? null : widget.onFinishPressed,
            child: Text(
              s.drill_btn_finish_save,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.cyan),
            ),
          ),
        ],
      ),
    );
  }
}