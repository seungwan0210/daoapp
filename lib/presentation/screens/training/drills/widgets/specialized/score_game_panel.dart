// lib/presentation/screens/training/drills/widgets/specialized/score_game_panel.dart

import 'package:flutter/material.dart';

class ScoreGamePanel extends StatefulWidget {
  final String title;          // 예: '501 Double-Out'
  final String valueLabel;     // 예: '사용한 다트 수', '최종 점수'
  final int minValue;          // 허용 최소값
  final int maxValue;          // 허용 최대값
  final int initialValue;      // 기본 제안값 (예: 18, 700)
  final String helperText;     // 하단 설명문
  final bool isBusy;

  /// 사용자가 최종 값을 입력 후 "확인"을 눌렀을 때 호출
  final ValueChanged<int> onSubmit;

  /// "드릴 종료하고 결과 저장" 버튼 등에서 사용하는 종료 콜백
  final VoidCallback? onFinishPressed;

  const ScoreGamePanel({
    super.key,
    required this.title,
    required this.valueLabel,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    required this.helperText,
    required this.isBusy,
    required this.onSubmit,
    this.onFinishPressed,
  });

  @override
  State<ScoreGamePanel> createState() => _ScoreGamePanelState();
}

class _ScoreGamePanelState extends State<ScoreGamePanel> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isBusy) return;

    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _errorText = '값을 입력해 주세요.';
      });
      return;
    }

    final value = int.tryParse(raw);
    if (value == null) {
      setState(() {
        _errorText = '숫자만 입력할 수 있습니다.';
      });
      return;
    }

    if (value < widget.minValue || value > widget.maxValue) {
      setState(() {
        _errorText =
        '${widget.minValue} ~ ${widget.maxValue} 사이의 값만 입력할 수 있습니다.';
      });
      return;
    }

    setState(() => _errorText = null);

    // 실제 저장/계산 로직은 부모에서 처리
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    final rangeText = '${widget.minValue} ~ ${widget.maxValue}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ===================== 상단 카드 =====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 18,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.grey.shade300,
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.helperText,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '입력 범위: $rangeText',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ===================== 숫자 입력 필드 =====================
          TextField(
            controller: _controller,
            enabled: !widget.isBusy,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              labelText: widget.valueLabel,
              labelStyle: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
              hintText: widget.valueLabel == '사용한 다트 수'
                  ? '예: 18'
                  : '예: ${widget.initialValue}',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.cyan,
                  width: 1.4,
                ),
              ),
              errorText: _errorText,
            ),
            onSubmitted: (_) => _submit(),
          ),

          const SizedBox(height: 18),

          // ===================== 확인 / 종료 버튼 =====================
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
                    elevation: 3,
                  ),
                  child: const Text(
                    '값 입력 완료',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: widget.isBusy ? null : widget.onFinishPressed,
            child: const Text(
              '드릴 종료하고 결과 저장',
              style: TextStyle(
                fontSize: 13,
                color: Colors.cyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
