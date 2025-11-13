// lib/presentation/screens/community/checkout/practice/widgets/remaining_score_display.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoapp/presentation/providers/checkout_provider.dart';

class RemainingScoreDisplay extends StatelessWidget {
  const RemainingScoreDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutProvider>(
      builder: (context, p, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        color: p.remainingScore <= 50 ? Colors.red[50] : Theme.of(context).primaryColor,
        child: Column(
          children: [
            Text(
              "남은 점수",
              style: TextStyle(
                color: p.remainingScore <= 50 ? Colors.red[700] : Colors.white70,
                fontSize: 16,
              ),
            ),
            Text(
              "${p.remainingScore}",
              style: TextStyle(
                color: p.remainingScore <= 50 ? Colors.red[800] : Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}