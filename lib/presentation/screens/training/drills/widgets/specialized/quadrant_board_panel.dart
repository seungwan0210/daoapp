// lib/presentation/screens/training/drills/widgets/specialized/quadrant_board_panel.dart

import 'package:flutter/material.dart';

class QuadrantBoardPanel extends StatefulWidget {
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;
  final bool isBusy;

  /// 전체 계획 다트 수 (기본 60 = 15다트 × 4분면)
  final int totalDarts;

  const QuadrantBoardPanel({
    super.key,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.isBusy = false,
    this.totalDarts = 60, // ✅ 기본값 60으로 고정
  });

  @override
  State<QuadrantBoardPanel> createState() => _QuadrantBoardPanelState();
}

class _QuadrantBoardPanelState extends State<QuadrantBoardPanel> {
  int thrown = 0;       // 던진 다트 수
  int successCount = 0; // 성공한 다트 수

  /// 분면당 다트 수 (60 / 4 = 15)
  static const int dartsPerQuadrant = 15;

  // 각 분면 색상 (이름은 UI에서 따로 쓰지 않음)
  static const List<Color> quadrantColors = [
    Color(0xFFE91E63), // 우상단
    Color(0xFFFF9800), // 우하단
    Color(0xFF2196F3), // 좌하단
    Color(0xFF4CAF50), // 좌상단
  ];

  /// 현재 분면 index (0~3)
  int get currentQuadrantIndex =>
      (thrown ~/ dartsPerQuadrant).clamp(0, quadrantColors.length - 1);

  /// 현재 분면에서 이미 던진 다트 수 (0~15)
  int get dartsDoneInQuadrant => (thrown % dartsPerQuadrant);

  bool get isFinished => thrown >= widget.totalDarts;

  void _record(bool success) {
    if (widget.isBusy || isFinished) return;

    setState(() {
      thrown++;
      if (success) successCount++;
    });

    if (success) {
      widget.onHitSuccess?.call();
    } else {
      widget.onHitFail?.call();
    }
    // 🔹 여기서는 "결과 화면으로 이동"까지는 하지 않고,
    //    RunScreen 쪽(onFinishPressed)에서만 결정하도록 유지.
  }

  @override
  Widget build(BuildContext context) {
    final totalDarts = widget.totalDarts;

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

          const SizedBox(height: 32),

          // 2) 성공 / 실패 버튼
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy || isFinished
                      ? null
                      : () => _record(true),
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
                  onPressed: widget.isBusy || isFinished
                      ? null
                      : () => _record(false),
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
              onPressed: widget.onFinishPressed,
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
              onPressed: widget.isBusy ? null : widget.onFinishPressed,
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
