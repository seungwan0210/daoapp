// lib/presentation/screens/training/drills/widgets/specialized/countup_round_score_panel.dart

import 'package:flutter/material.dart';

class CountUpRoundScorePanel extends StatefulWidget {
  final int currentRound;
  final int totalRounds;

  /// 지금까지 누적된 총점 (부모에서 내려줌)
  final int accumulatedScore;

  /// 라운드 점수가 확정되면 호출 (예: 1R 45점, 2R 60점 등)
  final ValueChanged<int> onRoundSubmitted;

  /// ✅ Undo(1단계): 직전 라운드 확정을 취소(부모가 점수/라운드 되돌림 처리)
  final VoidCallback? onUndoLastRound;

  /// 유저가 중간에 그만두고 싶을 때
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

  /// ✅ 입력값 Undo(텍스트 입력 1단계)용
  String _prevText = '';

  bool get _canUndoInput =>
      !widget.isBusy &&
          _prevText.isNotEmpty &&
          _prevText != _controller.text;

  /// ✅ 라운드 Undo 가능 여부(직전 라운드가 존재할 때)
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

      // 1단계 Undo 느낌 유지
      _prevText = current;

      _errorText = null;
    });
  }

  void _submit() {
    if (widget.isBusy) return;

    // ✅ 제출 직전 값을 입력 Undo 후보로 저장
    _stashPrev();

    final raw = _controller.text.trim();

    if (raw.isEmpty) {
      setState(() => _errorText = '이번 라운드 점수를 입력해 주세요.');
      return;
    }

    final value = int.tryParse(raw);
    if (value == null) {
      setState(() => _errorText = '숫자만 입력할 수 있습니다.');
      return;
    }

    if (value < 0 || value > 180) {
      setState(() => _errorText = '0 ~ 180점 사이로 입력해 주세요.');
      return;
    }

    setState(() => _errorText = null);

    widget.onRoundSubmitted(value);

    // ✅ 다음 라운드 준비
    _controller.clear();
    _prevText = ''; // 다음 라운드에서는 입력 Undo 기준을 새로 시작
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 제목 + 라운드 정보
          const Text(
            '이번 라운드 점수 입력',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'ROUND ${widget.currentRound} / ${widget.totalRounds}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.cyan.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          // 지금까지 누적된 총점 표시
          Text(
            '현재까지 총점: ${widget.accumulatedScore}점',
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
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: '이번 라운드 점수 (0~180)',
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
              filled: true,
              fillColor: Colors.cyan.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.cyan.shade400,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.cyan.shade200,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.cyan.shade600,
                  width: 2,
                ),
              ),
              errorText: _errorText,
            ),
            onTap: _stashPrev,
            onSubmitted: (_) => _submit(),
          ),

          const SizedBox(height: 14),

          // ✅ 확정 + 입력 Undo
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    '이번 라운드 점수 확정',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: _canUndoInput
                          ? Colors.grey.shade400
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: const Icon(Icons.undo, size: 20),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ✅ 직전 라운드 Undo (부모가 라운드/누적점 되돌림)
          if (widget.onUndoLastRound != null) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _canUndoRound ? widget.onUndoLastRound : null,
                icon: const Icon(Icons.undo),
                label: const Text(
                  '직전 라운드 되돌리기',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 드릴 중단 버튼
          TextButton(
            onPressed: widget.isBusy ? null : widget.onFinishPressed,
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
