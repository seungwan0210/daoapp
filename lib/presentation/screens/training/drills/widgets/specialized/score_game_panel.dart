// lib/presentation/screens/training/drills/widgets/specialized/score_game_panel.dart

import 'package:flutter/material.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 임포트 경로 수정

class ScoreGamePanel extends StatefulWidget {
  final String title;
  final String valueLabel;
  final int minValue;
  final int maxValue;
  final int initialValue;
  final String helperText;
  final bool isBusy;

  final ValueChanged<int> onSubmit;
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
  String _prevText = '';

  bool get _canUndo =>
      !widget.isBusy &&
          _prevText.isNotEmpty &&
          _prevText != _controller.text;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _prevText = _controller.text;
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    if (widget.isBusy) return;
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

  void _stashPrev() {
    _prevText = _controller.text;
  }

  void _undoInput() {
    if (!_canUndo) return;
    final String current = _controller.text;
    setState(() {
      _controller.text = _prevText;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
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
      setState(() => _errorText = s.profile_err_input);
      return;
    }

    final value = int.tryParse(raw);
    if (value == null) {
      setState(() => _errorText = s.drill_err_only_number);
      return;
    }

    if (value < widget.minValue || value > widget.maxValue) {
      setState(() {
        _errorText = s.drill_err_score_range;
      });
      return;
    }

    setState(() => _errorText = null);
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    // 🔹 {min}, {max}, {unit} 인자를 받는 함수형 호출로 수정
    final rangeText = s.drill_hint_range(
        widget.minValue.toString(),
        widget.maxValue.toString(),
        widget.valueLabel
    );

    // 🔹 힌트 텍스트 분기 처리
    final hint = widget.valueLabel == s.drill_stat_darts
        ? 'ex: 18'
        : 'ex: ${widget.initialValue}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 안내 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.helperText,
                  style: TextStyle(fontSize: 12, height: 1.4, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  rangeText, // 🔹 "범위: N ~ M" (다국어 함수 결과값)
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 입력 필드
          TextField(
            controller: _controller,
            enabled: !widget.isBusy,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              labelText: widget.valueLabel,
              labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.cyan, width: 1.4)),
              errorText: _errorText,
            ),
            onTap: _stashPrev,
            onSubmitted: (_) => _submit(),
          ),

          const SizedBox(height: 14),

          // 확인 / 되돌리기 버튼
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
                    elevation: 3,
                  ),
                  child: Text(
                    s.common_confirm, // 🔹 "확인"
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: _canUndo ? Colors.grey.shade400 : Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.undo, size: 20),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: widget.isBusy ? null : widget.onFinishPressed,
            child: Text(
              s.drill_btn_finish_save,
              style: const TextStyle(fontSize: 13, color: Colors.cyan, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}