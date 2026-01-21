// lib/presentation/screens/training/grip_lab/widgets/grip_metric_card.dart
import 'package:flutter/material.dart';

/// 그립 연구소 - 수치 카드(2열 그리드에서 쓰는 카드)
///
/// 사용 예)
/// GripMetricCard(
///   title: "Pinch Gap",
///   value: "14.2%",
///   sub: "엄지-검지 간격",
///   color: Colors.cyan,
/// )
class GripMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String sub;
  final Color color;

  const GripMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
