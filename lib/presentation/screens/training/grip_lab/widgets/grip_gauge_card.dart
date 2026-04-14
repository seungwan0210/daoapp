import 'package:flutter/material.dart';

class GripGaugeCard extends StatelessWidget {
  final String title;
  final String valueText; // 예: "12%"
  final double normalizedValue; // 0.0 ~ 1.0 (게이지 위치)
  final String labelLeft;
  final String labelRight;
  final Color color;

  const GripGaugeCard({
    super.key,
    required this.title,
    required this.valueText,
    required this.normalizedValue,
    required this.labelLeft,
    required this.labelRight,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // 값 범위 제한 (0~1)
    final double safeProgress = normalizedValue.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀 + 값
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
              Text(valueText, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),

          // 게이지 바 (Custom Slider 느낌)
          SizedBox(
            height: 8,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // 배경 선
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // 채워지는 선 (선택 사항, 여기선 점만 표시하는게 더 분석적일 수 있음)
                /*
                FractionallySizedBox(
                  widthFactor: safeProgress,
                  child: Container(
                    decoration: BoxDecoration(color: color.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                */
                // 현재 위치 점 (Indicator)
                Align(
                  alignment: Alignment(safeProgress * 2 - 1, 0), // -1 ~ 1 범위로 변환
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: color, width: 3),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 좌우 라벨
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(labelLeft, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              Text(labelRight, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}