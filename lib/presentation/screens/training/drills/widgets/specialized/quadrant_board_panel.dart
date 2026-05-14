// lib/presentation/screens/training/drills/widgets/specialized/quadrant_board_panel.dart

import 'package:flutter/material.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 임포트 경로 수정

class QuadrantBoardPanel extends StatelessWidget {
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;

  final bool canUndo;
  final VoidCallback? onUndo;

  final bool isBusy;
  final int totalDarts;
  final ValueNotifier<int>? thrownDartsNotifier;

  const QuadrantBoardPanel({
    super.key,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.canUndo = false,
    this.onUndo,
    this.isBusy = false,
    this.totalDarts = 60,
    this.thrownDartsNotifier,
  });

  static const int dartsPerQuadrant = 15;

  static const List<Color> quadrantColors = [
    Color(0xFFE91E63), // 우상단
    Color(0xFFFF9800), // 우하단
    Color(0xFF2196F3), // 좌하단
    Color(0xFF4CAF50), // 좌상단
  ];

  void _record(BuildContext context, bool success, int thrown) {
    if (isBusy) return;
    if (thrown >= totalDarts) return;

    if (success) {
      onHitSuccess?.call();
    } else {
      onHitFail?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 S 대신 AppLocalizations 사용
    final s = AppLocalizations.of(context)!;

    Widget content(int thrown) {
      final int currentQuadrantIndex =
      (thrown ~/ dartsPerQuadrant).clamp(0, quadrantColors.length - 1);
      final int dartsDoneInQuadrant = (thrown % dartsPerQuadrant);
      final bool isFinished = thrown >= totalDarts;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),

            // 1) 보드 + 하이라이트 + 현재 구역 정보
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/images/dartboard.png',
                          width: 260,
                          height: 260,
                          fit: BoxFit.cover,
                        ),
                      ),
                      CustomPaint(
                        size: const Size(260, 260),
                        painter: _QuadrantPainter(
                          index: currentQuadrantIndex,
                          colors: quadrantColors,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 🔹 정보 텍스트 다국어화
                  Text(
                    '${s.drill_quadrant_title}: $dartsDoneInQuadrant / $dartsPerQuadrant ${s.drill_stat_darts}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${s.drill_progress_title}: $thrown / $totalDarts ${s.drill_stat_darts}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.drill_quadrant_guide,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // UNDO 버튼
            if (onUndo != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: (isBusy || !canUndo) ? null : onUndo,
                  icon: const Icon(Icons.undo, size: 18),
                  label: Text(
                    s.calc_undo.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // 2) 성공 / 실패 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (isBusy || isFinished)
                        ? null
                        : () => _record(context, true, thrown),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      s.drill_btn_success,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (isBusy || isFinished)
                        ? null
                        : () => _record(context, false, thrown),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      s.drill_btn_fail,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 3) 종료/저장 버튼
            if (isFinished)
              ElevatedButton(
                onPressed: onFinishPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  s.drill_check_result,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: isBusy ? null : onFinishPressed,
                child: Text(
                  s.drill_btn_finish_save,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      );
    }

    if (thrownDartsNotifier != null) {
      return ValueListenableBuilder<int>(
        valueListenable: thrownDartsNotifier!,
        builder: (_, thrown, __) => content(thrown),
      );
    }

    return content(0);
  }
}

class _QuadrantPainter extends CustomPainter {
  final int index;
  final List<Color> colors;

  const _QuadrantPainter({
    required this.index,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    const double quarter = 1.57079632679;

    for (int i = 0; i < 4; i++) {
      paint.color = colors[i].withOpacity(i == index ? 0.55 : 0.08);
      final startAngle = -quarter / 2 + quarter * i;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        quarter,
        true,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _QuadrantPainter oldDelegate) {
    return index != oldDelegate.index;
  }
}