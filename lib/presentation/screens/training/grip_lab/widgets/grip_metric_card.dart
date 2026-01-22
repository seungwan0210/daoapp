import 'package:flutter/material.dart';

/// 그립 연구소 - 수치 카드
/// (아이콘 지원 추가됨)
class GripMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String sub;
  final Color color;
  final IconData? icon; // ✅ [Fix] 아이콘 파라미터 추가

  const GripMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.sub,
    required this.color,
    this.icon, // ✅ [Fix] 생성자 추가
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
            // 타이틀 행 (아이콘 + 텍스트)
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                ],
                Text(
                  title,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                ),
              ],
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