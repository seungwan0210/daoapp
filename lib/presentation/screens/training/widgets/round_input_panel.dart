// lib/presentation/screens/training/widgets/round_input_panel.dart

import 'package:flutter/material.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

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
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 (전달받은 String 사용 - 이미 외부에서 다국어 처리되어 넘어옴)
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),

            // 🔹 라운드 진행 표시 다국어화
            Text(
              s.drill_stat_rounds_count(currentRound.toString(), totalRounds.toString()),
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

            // 🔹 확정 버튼 다국어화
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onConfirm,
                child: Text(
                  s.drill_confirm_round('', ''), // 인자가 필요 없는 키라면 s.common_confirm 등으로 대체 가능
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}