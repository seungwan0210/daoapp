import 'dart:math' as math;
import 'package:flutter/material.dart';

class GhostOverlayPainter extends CustomPainter {
  final List<Offset>? liveLandmarks;
  final List<Offset>? baselineLandmarks;
  final int imageWidth;
  final int imageHeight;
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

    List<Offset>? normLive;
    if (liveLandmarks != null && liveLandmarks!.isNotEmpty) {
      normLive = _normalizeIfNeeded(liveLandmarks!);
    }

    List<Offset>? normBase;
    if (baselineLandmarks != null && baselineLandmarks!.isNotEmpty) {
      normBase = _normalizeIfNeeded(baselineLandmarks!);
    }

    if (normLive != null && normLive.length >= 21) {
      final screenPts = _mapNormalizedToView(size, normLive);
      _drawHand(canvas, screenPts, isGhost: false);

      if (normBase != null && normBase.length >= 21) {
        List<Offset> processedBase = List.from(normBase);
        if (mirrorBaseline) {
          processedBase = processedBase.map((p) => Offset(1.0 - p.dx, p.dy)).toList();
        }
        final alignedBase = _alignBaselineToCurrent(processedBase, normLive);
        final ghostPts = _mapNormalizedToView(size, alignedBase);
        _drawHand(canvas, ghostPts, isGhost: true);
      }
    } else {
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

  List<Offset> _normalizeIfNeeded(List<Offset> points) {
    if (points.isEmpty) return points;
    if (points[0].dx > 2.0 || points[0].dy > 2.0) {
      return points.map((p) => Offset(p.dx / imageWidth, p.dy / imageHeight)).toList();
    }
    return points;
  }

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

  List<Offset> _mapNormalizedToView(Size viewSize, List<Offset> normalizedPts) {
    final double screenRatio = viewSize.width / viewSize.height;
    final double imageRatio = imageWidth / imageHeight;

    double displayedW, displayedH;

    if (screenRatio > imageRatio) {
      displayedW = viewSize.width;
      displayedH = viewSize.width / imageRatio;
    } else {
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