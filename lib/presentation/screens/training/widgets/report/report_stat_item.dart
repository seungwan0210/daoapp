// lib/presentation/screens/training/widgets/report/report_stat_item.dart
import 'package:flutter/material.dart';

/// 리포트에서 한 줄 지표(라벨 + 값 + Δ)를 보여주는 공용 위젯
class ReportStatItem extends StatelessWidget {
  final String label;
  final String value;
  final double? delta;        // 이전 대비 증가/감소 값 (없으면 표시 안 함)
  final String? description;  // 보조 텍스트
  final bool highlight;       // 메인 지표일 때 강조

  const ReportStatItem({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.description,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color valueColor = Colors.black87;
    FontWeight valueWeight = FontWeight.w700;

    if (highlight) {
      valueColor = Colors.cyan[700]!;
      valueWeight = FontWeight.w800;
    }

    String? deltaText;
    Color? deltaColor;

    if (delta != null && delta!.abs() >= 0.0001) {
      final bool up = delta! > 0;
      final double absDelta = delta!.abs();
      deltaText =
      up ? "+${absDelta.toStringAsFixed(2)}" : "-${absDelta.toStringAsFixed(2)}";
      deltaColor = up ? Colors.redAccent : Colors.blueGrey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: valueColor,
                fontWeight: valueWeight,
              ),
            ),
            if (deltaText != null) ...[
              const SizedBox(width: 6),
              Icon(
                delta! > 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: deltaColor,
              ),
              Text(
                deltaText,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: deltaColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 2),
          Text(
            description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}
