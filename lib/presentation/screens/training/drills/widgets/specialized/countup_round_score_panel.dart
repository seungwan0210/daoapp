// lib/presentation/screens/training/drills/widgets/specialized/countup_round_score_panel.dart

import 'package:flutter/material.dart';

class CountUpRoundScorePanel extends StatefulWidget {
  final int currentRound;
  final int totalRounds;

  /// 지금까지 누적된 총점 (부모에서 내려줌)
  final int accumulatedScore;

  /// 라운드 점수가 확정되면 호출 (예: 1R 45점, 2R 60점 등)
  final ValueChanged<int> onRoundSubmitted;

  /// 유저가 중간에 그만두고 싶을 때
  final VoidCallback? onFinishPressed;

  final bool isBusy;

  const CountUpRoundScorePanel({
    super.key,
    required this.currentRound,
    required this.totalRounds,
    required this.accumulatedScore,
    required this.onRoundSubmitted,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<CountUpRoundScorePanel> createState() => _CountUpRoundScorePanelState();
}

class _CountUpRoundScorePanelState extends State<CountUpRoundScorePanel> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isBusy) return;

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
    _controller.clear(); // 다음 라운드 준비
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

          // 🔹 지금까지 누적된 총점 표시
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
          ),

          const SizedBox(height: 18),

          // 라운드 점수 확정
          SizedBox(
            width: double.infinity,
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

          const SizedBox(height: 10),

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
