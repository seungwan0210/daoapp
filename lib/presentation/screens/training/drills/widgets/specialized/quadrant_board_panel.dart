// lib/presentation/screens/training/drills/widgets/specialized/quadrant_board_panel.dart

import 'package:flutter/material.dart';

class QuadrantBoardPanel extends StatelessWidget {
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;

  /// ✅ Undo 지원 (선택)
  final bool canUndo;
  final VoidCallback? onUndo;

  final bool isBusy;

  /// 전체 계획 다트 수 (기본 60 = 15다트 × 4분면)
  final int totalDarts;

  /// ✅ RunScreen의 thrownDarts를 그대로 받아서 UI 표시까지 동기화
  /// (Undo가 있어도 표시가 같이 내려감)
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

  /// 분면당 다트 수 (60 / 4 = 15)
  static const int dartsPerQuadrant = 15;

  // 각 분면 색상
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
                  Text(
                    '이번 구역 진행: $dartsDoneInQuadrant / $dartsPerQuadrant 다트',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '전체 진행: $thrown / $totalDarts 다트',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '현재 하이라이트된 색 구역에 집중해서 던져주세요!',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ✅ Undo (선택)
            if (onUndo != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: (isBusy || !canUndo) ? null : onUndo,
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text(
                    'UNDO',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                    child: const Text(
                      '성공',
                      style: TextStyle(
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
                    child: const Text(
                      '실패',
                      style: TextStyle(
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
                child: const Text(
                  '결과 확인하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: isBusy ? null : onFinishPressed,
                child: const Text(
                  '드릴 종료하고 결과 저장',
                  style: TextStyle(
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

    // ✅ notifier가 있으면 그걸로 UI를 완전 동기화
    if (thrownDartsNotifier != null) {
      return ValueListenableBuilder<int>(
        valueListenable: thrownDartsNotifier!,
        builder: (_, thrown, __) => content(thrown),
      );
    }

    // ✅ notifier가 없으면(구버전 호환) 내부적으로는 0으로 표시
    // (권장: RunScreen에서 notifier를 꼭 넘겨줘)
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

    const double quarter = 1.57079632679; // 90도(PI/2)

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
