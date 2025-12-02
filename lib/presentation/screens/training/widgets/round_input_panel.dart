// lib/presentation/screens/training/widgets/round_input_panel.dart

import 'package:flutter/material.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class RoundInputPanel extends StatelessWidget {
  final String title;
  final int currentRound;
  final int totalRounds;
  final String valueLabel;
  final int currentValue;
  final void Function(int value) onChanged;
  final Future<void> Function()? onConfirm;

  const RoundInputPanel({
    super.key,
    required this.title,
    required this.currentRound,
    required this.totalRounds,
    required this.valueLabel,
    required this.currentValue,
    required this.onChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),

            // 라운드 진행 표시
            Text(
              'ROUND $currentRound / $totalRounds',
              style: TextStyle(
                fontSize: 14,
                color: Colors.cyan[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 값 라벨
            Text(
              valueLabel,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // 값 증감 컨트롤
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    final next = (currentValue - 1).clamp(0, 999);
                    onChanged(next);
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$currentValue',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final next = (currentValue + 1).clamp(0, 999);
                    onChanged(next);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 확정 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onConfirm,
                child: const Text(
                  '이번 라운드 확정',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
