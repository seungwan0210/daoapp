// lib/presentation/screens/training/drills/widgets/core/round_input_panel.dart

import 'package:flutter/material.dart';

class RoundInputPanel extends StatelessWidget {
  final String title;
  final int currentRound;
  final int totalRounds;
  final int currentValue;
  final ValueChanged<int> onValueChanged;
  final VoidCallback? onConfirm;
  final bool isBusy;

  /// 🔹 값 범위 & 단위(label) 설정
  final int minValue;
  final int maxValue;
  final String unitLabel;

  /// ✅ 추가: "이전 라운드 되돌리기" (확정 후 오입력 복구용)
  final VoidCallback? onUndo;
  final bool canUndo;

  const RoundInputPanel({
    super.key,
    required this.title,
    required this.currentRound,
    required this.totalRounds,
    required this.currentValue,
    required this.onValueChanged,
    this.onConfirm,
    this.isBusy = false,
    this.minValue = 0, // 기본: 마크 0 ~ 9
    this.maxValue = 9,
    this.unitLabel = '마크', // 기본 단위 텍스트
    this.onUndo,
    this.canUndo = false,
  });

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
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 제목 + 라운드
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            "ROUND $currentRound / $totalRounds",
            style: TextStyle(
              fontSize: 13,
              color: Colors.cyan.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          // 현재 값 표시
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.cyan.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.cyan.shade400,
                width: 2,
              ),
            ),
            child: Text(
              "$currentValue",
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.cyan,
                letterSpacing: -1,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 범위 안내
          Text(
            "$minValue ~ $maxValue $unitLabel",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // + / - 버튼
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isBusy
                      ? null
                      : () => onValueChanged(
                    (currentValue - 1)
                        .clamp(minValue, maxValue)
                        .toInt(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Icon(Icons.remove, size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isBusy
                      ? null
                      : () => onValueChanged(
                    (currentValue + 1)
                        .clamp(minValue, maxValue)
                        .toInt(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade100,
                    foregroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Icon(Icons.add, size: 28),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 확정 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isBusy || onConfirm == null ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Text(
                "이번 라운드 확정 ($currentValue $unitLabel)",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ✅ Undo 버튼 (확정 후 오입력 복구)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: (isBusy || !canUndo || onUndo == null) ? null : onUndo,
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: const Text(
                '이전 라운드 되돌리기',
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
        ],
      ),
    );
  }
}
