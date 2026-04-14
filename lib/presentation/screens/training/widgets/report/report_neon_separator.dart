// lib/presentation/screens/training/widgets/report/report_neon_separator.dart
import 'package:flutter/material.dart';

/// DAO 리포트에서 쓰는 얇은 네온 라인 구분선
class ReportNeonSeparator extends StatelessWidget {
  final double opacity;

  const ReportNeonSeparator({
    super.key,
    this.opacity = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan.withOpacity(opacity),
            Colors.deepPurpleAccent.withOpacity(opacity),
          ],
        ),
      ),
    );
  }
}
