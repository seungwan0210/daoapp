// lib/presentation/screens/community/checkout/practice/widgets/practice_stats_card.dart
import 'package:flutter/material.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class PracticeStatsCard extends StatelessWidget {
  final String title;         // 예: "성공률"
  final String value;         // 예: "68%"
  final String? subtitle;     // 예: "최근 10문제 기준"
  final IconData? icon;       // 예: Icons.check_circle_outline
  final Color? valueColor;    // 값 강조 색
  final VoidCallback? onTap;  // 탭 가능하게 할 때 사용

  const PracticeStatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 28,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
