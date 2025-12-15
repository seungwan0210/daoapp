// lib/presentation/screens/training/drills/widgets/specialized/score_game_panel.dart

import 'package:flutter/material.dart';

class ScoreGamePanel extends StatefulWidget {
  final String title;          // 예: '501 Double-Out'
  final String valueLabel;     // 예: '사용한 다트 수', '최종 점수'
  final int minValue;          // 허용 최소값
  final int maxValue;          // 허용 최대값
  final int initialValue;      // 기본 제안값 (예: 18, 700) -> ✅ "예시(hint)"로만 사용
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

  /// ✅ 입력값 Undo(1단계)용: 직전 텍스트 저장
  String _prevText = '';

  bool get _canUndo =>
      !widget.isBusy &&
          _prevText.isNotEmpty &&
          _prevText != _controller.text;

  @override
  void initState() {
    super.initState();

    // ✅ 핵심: 초기값을 controller에 넣지 않는다 (700이 박혀 보이는 문제 해결)
    _controller = TextEditingController();

    // 초기 prevText는 빈 값
    _prevText = _controller.text;

    // 입력이 바뀔 때마다 "직전 값"을 관리하기 위해 리스너 등록
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    // Busy 중에는 기록하지 않음 (불필요한 변경 방지)
    if (widget.isBusy) return;

    // 너무 공격적으로 prevText를 덮어쓰면 Undo가 무력해지니까,
    // "에러 초기화"와 함께, 이전값은 외부에서 갱신(_stashPrev)로만 관리
    // 여기서는 에러만 정리
    if (_errorText != null) {
      setState(() => _errorText = null);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    super.dispose();
  }

  /// ✅ 현재 값을 "Undo용 직전값"으로 저장
  void _stashPrev() {
    _prevText = _controller.text;
  }

  /// ✅ 입력값 되돌리기(1단계)
  void _undoInput() {
    if (!_canUndo) return;

    final String current = _controller.text;
    setState(() {
      _controller.text = _prevText;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);

      // 한번 되돌렸으면, 다시 누르면 또 되돌리는 느낌 방지:
      // 되돌리기 전 값은 prevText에 넣어둬서 "한 번 더"는 안 되게 함(1단계 Undo)
      _prevText = current;

      _errorText = null;
    });
  }

  void _submit() {
    if (widget.isBusy) return;

    final raw = _controller.text.trim();

    // ✅ 제출 직전 값을 Undo 후보로 저장
    _stashPrev();

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
        _errorText = '${widget.minValue} ~ ${widget.maxValue} 사이의 값만 입력할 수 있습니다.';
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

    // ✅ label이 '사용한 다트 수'면 18 예시, 아니면 initialValue를 예시로
    final hint = widget.valueLabel == '사용한 다트 수'
        ? '예: 18'
        : '예: ${widget.initialValue}';

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
              hintText: hint, // ✅ 예시만 보여주고 값은 비움
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
            onTap: () {
              // ✅ 사용자가 입력 시작하기 전 "현재값"을 prev로 저장
              // (빈칸->입력)도 Undo가 의미 있게 동작
              _stashPrev();
            },
            onSubmitted: (_) => _submit(),
          ),

          const SizedBox(height: 14),

          // ===================== 확인 / 되돌리기 =====================
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
              const SizedBox(width: 10),
              SizedBox(
                width: 54,
                height: 48,
                child: OutlinedButton(
                  onPressed: _canUndo ? _undoInput : null,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: _canUndo ? Colors.grey.shade400 : Colors.grey.shade300,
                    ),
                  ),
                  child: const Icon(Icons.undo, size: 20),
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
