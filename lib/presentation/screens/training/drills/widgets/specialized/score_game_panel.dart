// lib/presentation/screens/training/drills/widgets/specialized/score_game_panel.dart

import 'package:flutter/material.dart';

/// scoreOnly 전용 패널
///
/// - Count-Up: 최종 점수 입력
/// - 501 Double-Out: 사용 다트 수 입력
///
/// 부모(DrillRunScreen)에서:
///   - title, valueLabel, min/max 설정
///   - onSubmit에서 점수(or 다트 수)를 받아서
///     _currentScore 또는 _totalAttempts 등에 반영 후 finish 호출
class ScoreGamePanel extends StatefulWidget {
  final String title;              // 예: "Count-Up 최종 점수 입력", "501 사용 다트 수"
  final String valueLabel;         // 예: "최종 점수", "사용 다트 수"
  final int minValue;              // 예: Count-Up 0, 501 다트수 9 등
  final int maxValue;              // 예: Count-Up 1500, 501 다트수 30 등
  final int step;                  // 기본 1
  final int initialValue;          // 기본값
  final String? helperText;        // 아래 안내 텍스트
  final ValueChanged<int> onSubmit; // 값 확정 시 호출
  final VoidCallback? onFinishPressed; // "드릴 종료하고 결과 저장" 용
  final bool isBusy;

  const ScoreGamePanel({
    super.key,
    required this.title,
    required this.valueLabel,
    required this.minValue,
    required this.maxValue,
    this.step = 1,
    required this.initialValue,
    this.helperText,
    required this.onSubmit,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<ScoreGamePanel> createState() => _ScoreGamePanelState();
}

class _ScoreGamePanelState extends State<ScoreGamePanel> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.clamp(widget.minValue, widget.maxValue);
  }

  void _changeValue(int delta) {
    if (widget.isBusy) return;
    setState(() {
      _value = (_value + delta * widget.step)
          .clamp(widget.minValue, widget.maxValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 제목
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            widget.valueLabel,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          // 2. 현재 값 크게 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.cyan.shade400, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '$_value',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.valueLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.cyan.shade200,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.helperText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.helperText!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. - / + 버튼 (좌우)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy
                      ? null
                      : () => _changeValue(-1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade700,
                    padding:
                    const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Icon(Icons.remove, size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy
                      ? null
                      : () => _changeValue(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade100,
                    foregroundColor: Colors.green.shade700,
                    padding:
                    const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Icon(Icons.add, size: 28),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 4. 확정 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.isBusy
                  ? null
                  : () => widget.onSubmit(_value),
              icon: const Icon(Icons.check_circle, size: 28),
              label: const Text(
                "결과 확정",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade600,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ),

          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.isBusy ? null : widget.onFinishPressed,
            child: const Text(
              "드릴 종료하고 결과 저장",
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
