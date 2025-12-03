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
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 제목 + 라운드 (작고 깔끔)
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "ROUND $currentRound / $totalRounds",
            style: TextStyle(fontSize: 16, color: Colors.cyan.shade700, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 28),

          // 현재 값 (크지만 적당히!)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.cyan.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.cyan.shade400, width: 3),
            ),
            child: Text(
              "$currentValue",
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: Colors.cyan,
                letterSpacing: -2,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // + / - 버튼 (손가락에 딱 맞는 크기)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isBusy ? null : () => onValueChanged((currentValue - 1).clamp(0, 999)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Icon(Icons.remove, size: 36),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: isBusy ? null : () => onValueChanged(currentValue + 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade100,
                    foregroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Icon(Icons.add, size: 36),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 확정 버튼 (풀사이즈, 강조!)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isBusy || currentValue == 0 ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 8,
              ),
              child: Text(
                "이번 라운드 확정 ($currentValue 마크)",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}