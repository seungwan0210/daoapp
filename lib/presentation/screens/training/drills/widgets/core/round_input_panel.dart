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

  const RoundInputPanel({
    super.key,
    required this.title,
    required this.currentRound,
    required this.totalRounds,
    required this.currentValue,
    required this.onValueChanged,
    this.onConfirm,
    this.isBusy = false,
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

          const SizedBox(height: 20),

          // + / - 버튼 (0 ~ 9 마크 기준)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isBusy
                      ? null
                      : () => onValueChanged(
                    (currentValue - 1).clamp(0, 9),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                  onPressed: isBusy
                      ? null
                      : () => onValueChanged(
                    (currentValue + 1).clamp(0, 9),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade100,
                    foregroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

          // 확정 버튼 (0 마크도 허용)
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
                "이번 라운드 확정 ($currentValue 마크)",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
