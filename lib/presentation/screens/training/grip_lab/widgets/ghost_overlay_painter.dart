// lib/presentation/screens/training/grip_lab/widgets/ghost_overlay_painter.dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class GhostOverlayPainter extends CustomPainter {
  /// 0.0~1.0 정규화 좌표(네이티브 기준)
  final List<Offset> landmarks;

  /// 네이티브 프레임 실제 w/h (회전 반영)
  final int imageWidth;
  final int imageHeight;

  /// true: FILL_CENTER(max scale), false: CONTAIN(min scale)
  final bool fillCenter;

  GhostOverlayPainter(
      this.landmarks, {
        required this.imageWidth,
        required this.imageHeight,
        this.fillCenter = true,
      });

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.length < 21) return;
    if (imageWidth <= 0 || imageHeight <= 0) return;

    final paintLine = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final paintPoint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final points = _mapToView(size);

    canvas.drawPoints(ui.PointMode.points, points, paintPoint);

    _drawFinger(canvas, points, const [0, 1, 2, 3, 4], paintLine);
    _drawFinger(canvas, points, const [0, 5, 6, 7, 8], paintLine);
    _drawFinger(canvas, points, const [0, 9, 10, 11, 12], paintLine);
    _drawFinger(canvas, points, const [0, 13, 14, 15, 16], paintLine);
    _drawFinger(canvas, points, const [0, 17, 18, 19, 20], paintLine);

    // 손바닥 연결
    canvas.drawLine(points[5], points[9], paintLine);
    canvas.drawLine(points[9], points[13], paintLine);
    canvas.drawLine(points[13], points[17], paintLine);
    canvas.drawLine(points[5], points[17], paintLine);
  }

  /// 네이티브 landmark(0~1)를 화면 좌표로 변환
  /// - fillCenter=true  => PreviewView.ScaleType.FILL_CENTER에 맞춤 (크롭 발생)
  /// - fillCenter=false => CONTAIN 방식 (레터박스 발생)
  List<Offset> _mapToView(Size viewSize) {
    final vw = viewSize.width;
    final vh = viewSize.height;

    final iw = imageWidth.toDouble();
    final ih = imageHeight.toDouble();

    final scaleX = vw / iw;
    final scaleY = vh / ih;

    // ✅ PreviewView의 ScaleType에 맞춰 선택
    final scale = fillCenter
        ? (scaleX > scaleY ? scaleX : scaleY) // max scale (크롭)
        : (scaleX < scaleY ? scaleX : scaleY); // min scale (여백)

    final scaledW = iw * scale;
    final scaledH = ih * scale;

    // ✅ 중앙 정렬 오프셋
    final dx = (scaledW - vw) / 2.0;
    final dy = (scaledH - vh) / 2.0;

    return landmarks.map((p) {
      final x = (p.dx * iw * scale) - dx;
      final y = (p.dy * ih * scale) - dy;
      return Offset(x, y);
    }).toList(growable: false);
  }

  void _drawFinger(
      Canvas canvas,
      List<Offset> points,
      List<int> indices,
      Paint paint,
      ) {
    for (int i = 0; i < indices.length - 1; i++) {
      canvas.drawLine(points[indices[i]], points[indices[i + 1]], paint);
    }
  }

  @override
  bool shouldRepaint(covariant GhostOverlayPainter old) {
    // ✅ provider가 매 프레임 새 List를 만들기 때문에 사실상 항상 repaint됨.
    // 여기서 리스트 deep compare 하면 오히려 비용만 커져서,
    // 프레임 기반 오버레이는 단순 true가 더 안정적임.
    return true;
  }
}
