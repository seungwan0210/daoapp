import 'dart:math' as math;
import 'package:flutter/material.dart';

class GhostOverlayPainter extends CustomPainter {
  /// 현재 감지된 실시간 손
  final List<Offset>? liveLandmarks;

  /// 저장된 기준 손
  final List<Offset>? baselineLandmarks;

  /// 현재 카메라 이미지의 해상도 (width, height)
  final int imageWidth;
  final int imageHeight;

  /// 기준 뼈대 좌우 반전 여부
  final bool mirrorBaseline;

  GhostOverlayPainter({
    required this.liveLandmarks,
    this.baselineLandmarks,
    required this.imageWidth,
    required this.imageHeight,
    this.mirrorBaseline = false,
    bool fillCenter = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth <= 0 || imageHeight <= 0) return;

    // -------------------------------------------------------------------------
    // [Step 1] 스마트 정규화 (Smart Normalization)
    // 데이터가 0~1(비율)인지, 1080(픽셀)인지 확인해서 무조건 0~1로 맞춤
    // -------------------------------------------------------------------------

    List<Offset>? normLive;
    if (liveLandmarks != null && liveLandmarks!.isNotEmpty) {
      normLive = _normalizeIfNeeded(liveLandmarks!);
    }

    List<Offset>? normBase;
    if (baselineLandmarks != null && baselineLandmarks!.isNotEmpty) {
      normBase = _normalizeIfNeeded(baselineLandmarks!);
    }

    // -------------------------------------------------------------------------
    // [Step 2] 그리기 로직
    // -------------------------------------------------------------------------

    // 1. 실시간(Live) 손 그리기
    if (normLive != null && normLive.length >= 21) {
      final screenPts = _mapNormalizedToView(size, normLive);
      _drawHand(canvas, screenPts, isGhost: false);

      // 2. 기준(Ghost) 손 그리기 (내 손이 보일 때 -> 자석 효과)
      if (normBase != null && normBase.length >= 21) {

        List<Offset> processedBase = List.from(normBase);

        // ✅ [반전] 0.0~1.0 좌표계이므로 (1.0 - x)
        if (mirrorBaseline) {
          processedBase = processedBase.map((p) => Offset(1.0 - p.dx, p.dy)).toList();
        }

        // ✅ [자석] 내 손에 착 붙기
        final alignedBase = _alignBaselineToCurrent(processedBase, normLive);

        final ghostPts = _mapNormalizedToView(size, alignedBase);
        _drawHand(canvas, ghostPts, isGhost: true);
      }
    }
    // 3. 내 손을 놓쳤을 때 (기준만 둥둥 띄우기)
    else {
      if (normBase != null && normBase.length >= 21) {
        List<Offset> processedBase = List.from(normBase);

        if (mirrorBaseline) {
          processedBase = processedBase.map((p) => Offset(1.0 - p.dx, p.dy)).toList();
        }

        final ghostPts = _mapNormalizedToView(size, processedBase);
        _drawHand(canvas, ghostPts, isGhost: true);
      }
    }
  }

  // 🧠 스마트 정규화 함수: 값이 1보다 크면 픽셀로 간주하고 나눔
  List<Offset> _normalizeIfNeeded(List<Offset> points) {
    if (points.isEmpty) return points;

    // 첫 번째 포인트의 x값이 2.0보다 크면 "아, 이건 픽셀 좌표구나"라고 판단
    if (points[0].dx > 2.0 || points[0].dy > 2.0) {
      return points.map((p) => Offset(p.dx / imageWidth, p.dy / imageHeight)).toList();
    }
    // 아니면 이미 0.0~1.0 이므로 그대로 사용
    return points;
  }

  // ---------------------------------------------------------------------------
  // 🖐️ 손 그리기 (스타일)
  // ---------------------------------------------------------------------------
  void _drawHand(Canvas canvas, List<Offset> points, {required bool isGhost}) {
    const fingers = [
      [0, 1, 2, 3, 4], [0, 5, 6, 7, 8], [0, 9, 10, 11, 12],
      [0, 13, 14, 15, 16], [0, 17, 18, 19, 20]
    ];

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = isGhost ? 2.0 : 3.0;

    for (int i = 0; i < fingers.length; i++) {
      if (isGhost) {
        paint.color = Colors.white.withOpacity(0.4);
      } else {
        const colors = [
          Color(0xFF00FF88), Colors.greenAccent, Colors.yellow, Colors.blue, Colors.redAccent
        ];
        paint.color = colors[i];
      }

      final indices = fingers[i];
      for (int j = 0; j < indices.length - 1; j++) {
        final p1 = points[indices[j]];
        final p2 = points[indices[j + 1]];
        if (isGhost) _drawDashedLine(canvas, p1, p2, paint);
        else canvas.drawLine(p1, p2, paint);
      }
    }

    // 손바닥
    final palmPaint = Paint()
      ..color = isGhost ? Colors.white.withOpacity(0.4) : Colors.white30
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final palmConnections = [[0, 5], [0, 17], [5, 9], [9, 13], [13, 17]];
    for (var pair in palmConnections) {
      final p1 = points[pair[0]];
      final p2 = points[pair[1]];
      if(isGhost) _drawDashedLine(canvas, p1, p2, palmPaint);
      else canvas.drawLine(p1, p2, palmPaint);
    }

    // 관절 (라이브만)
    if (!isGhost) {
      final jointPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
      for (var p in points) canvas.drawCircle(p, 2.5, jointPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 6.0;
    const double dashSpace = 4.0;
    double distance = (p2 - p1).distance;
    if (distance == 0) return;

    double startY = 0.0;
    final double dx = (p2.dx - p1.dx) / distance;
    final double dy = (p2.dy - p1.dy) / distance;

    while (startY < distance) {
      final double endY = math.min(startY + dashWidth, distance);
      final start = Offset(p1.dx + dx * startY, p1.dy + dy * startY);
      final end = Offset(p1.dx + dx * endY, p1.dy + dy * endY);
      canvas.drawLine(start, end, paint);
      startY += dashWidth + dashSpace;
    }
  }

  // ---------------------------------------------------------------------------
  // 🧮 좌표 변환 (0.0~1.0 -> Screen Pixel)
  // ---------------------------------------------------------------------------
  List<Offset> _mapNormalizedToView(Size viewSize, List<Offset> normalizedPts) {
    final double screenRatio = viewSize.width / viewSize.height;
    final double imageRatio = imageWidth / imageHeight;

    double scale;
    if (screenRatio > imageRatio) {
      scale = viewSize.width;
    } else {
      scale = viewSize.height * imageRatio;
    }

    // 단순화된 Cover 모드 계산 (Android PreviewView와 일치)
    final double finalScale = math.max(
        viewSize.width / 1.0,
        viewSize.height / (imageHeight / imageWidth) // aspect ratio 보정
    );

    // 하지만 대부분의 경우 정규화된 좌표는 [0,1]이므로 단순히 화면 크기에 스케일링하면 됨
    // 다만 카메라 뷰가 잘리는(Cover) 경우를 대비해 센터 정렬 보정

    // 더 강력하고 간단한 방법:
    // 정규화 좌표는 이미지가 왜곡되지 않았다는 가정하에, 화면을 꽉 채우는 박스를 계산
    final double renderW = viewSize.width;
    final double renderH = viewSize.height;

    // 실제 그려질 이미지 크기 계산 (Cover)
    double displayedW, displayedH;

    if (screenRatio > imageRatio) {
      // 화면이 더 납작함 -> 너비 맞춤, 위아래 잘림
      displayedW = viewSize.width;
      displayedH = viewSize.width / imageRatio;
    } else {
      // 화면이 더 길쭉함 -> 높이 맞춤, 좌우 잘림
      displayedH = viewSize.height;
      displayedW = viewSize.height * imageRatio;
    }

    final double offsetX = (viewSize.width - displayedW) / 2.0;
    final double offsetY = (viewSize.height - displayedH) / 2.0;

    return normalizedPts.map((p) {
      return Offset(
          p.dx * displayedW + offsetX,
          p.dy * displayedH + offsetY
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // 🧲 자석 로직 (Magnetic Alignment)
  // ---------------------------------------------------------------------------
  List<Offset> _alignBaselineToCurrent(List<Offset> base, List<Offset> cur) {
    if (base.length < 21 || cur.length < 21) return base;

    Offset getCenter(List<Offset> pts) => (pts[0] + pts[5] + pts[17]) / 3.0;
    double getSize(List<Offset> pts) => (pts[0] - pts[9]).distance;

    final centerB = getCenter(base);
    final centerC = getCenter(cur);
    final sizeB = getSize(base);
    final sizeC = getSize(cur);

    final scale = (sizeB < 0.001) ? 1.0 : (sizeC / sizeB);

    double getAngle(List<Offset> pts) => math.atan2(pts[9].dy - pts[0].dy, pts[9].dx - pts[0].dx);
    final angleB = getAngle(base);
    final angleC = getAngle(cur);
    final rotation = angleC - angleB;

    final cosR = math.cos(rotation);
    final sinR = math.sin(rotation);

    return base.map((p) {
      final dx = (p.dx - centerB.dx);
      final dy = (p.dy - centerB.dy);
      final rotatedX = (dx * cosR - dy * sinR) * scale;
      final rotatedY = (dx * sinR + dy * cosR) * scale;
      return Offset(rotatedX + centerC.dx, rotatedY + centerC.dy);
    }).toList();
  }

  @override
  bool shouldRepaint(covariant GhostOverlayPainter old) {
    return old.mirrorBaseline != mirrorBaseline ||
        old.liveLandmarks != liveLandmarks ||
        old.baselineLandmarks != baselineLandmarks;
  }
}