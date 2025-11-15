import 'package:flutter/material.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class RemainingScoreDisplay extends StatelessWidget {
  final int remainingScore;
  final List<String> currentDarts;

  const RemainingScoreDisplay({
    super.key,
    required this.remainingScore,
    required this.currentDarts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "현재 남은 점수",
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "$remainingScore",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "이번 턴",
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentDarts.isEmpty ? "-" : currentDarts.join(", "),
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
