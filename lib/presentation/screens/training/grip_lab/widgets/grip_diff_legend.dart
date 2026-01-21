// lib/presentation/screens/training/grip_lab/widgets/grip_diff_legend.dart
import 'package:flutter/material.dart';

/// 그립 연구소 - 차이(비교) 범례 UI
///
/// 앞으로 "기준(고스트)" vs "현재" vs "차이 강조"를 표시할 때 쓰는 작은 레전드.
/// - 기준(고스트): 흰색/회색 계열
/// - 현재: 파란색
/// - 차이(불일치): 빨간색
///
/// 사용 예)
/// const GripDiffLegend();
class GripDiffLegend extends StatelessWidget {
  final Color baselineColor;
  final Color currentColor;
  final Color diffColor;

  const GripDiffLegend({
    super.key,
    this.baselineColor = const Color(0xFFFFFFFF),
    this.currentColor = const Color(0xFF3F8CFF),
    this.diffColor = const Color(0xFFFF3B30),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(
            color: baselineColor.withOpacity(0.85),
            label: "기준(고스트)",
          ),
          const SizedBox(width: 10),
          _LegendItem(
            color: currentColor,
            label: "현재",
          ),
          const SizedBox(width: 10),
          _LegendItem(
            color: diffColor,
            label: "차이",
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
