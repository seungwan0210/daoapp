import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
// ReleasePoint 클래스 경로 확인 (파일 위치에 따라 수정 필요)
import 'package:daoapp/presentation/screens/training/pose_analysis/screens/pose_analysis_result_screen.dart';

class PosePainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final Color poseColor;

  final Map<PoseLandmarkType, List<Offset>> multiPaths;
  final Map<PoseLandmarkType, Color> activeTrackColors;
  final Map<PoseLandmarkType, Color> allPartColors;

  final bool showTrackingLines;
  final bool showReleasePoints; // ✅ [NEW] 릴리즈 포인트 토글 변수 추가
  final String referenceMode;

  final Map<PoseLandmarkType, double> setupHeights;
  final List<ReleasePoint> releasePoints;
  final int currentFrameIndex;

  PosePainter({
    required this.pose,
    required this.imageSize,
    this.poseColor = Colors.white,
    this.multiPaths = const {},
    this.activeTrackColors = const {},
    this.allPartColors = const {},
    this.showTrackingLines = true,
    this.showReleasePoints = true, // ✅ 기본값 true
    this.referenceMode = 'NONE',
    this.setupHeights = const {},
    this.releasePoints = const [],
    this.currentFrameIndex = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {

    // 1. 트래킹 궤적 (showTrackingLines 체크)
    if (showTrackingLines) {
      activeTrackColors.forEach((part, color) {
        if (!multiPaths.containsKey(part)) return;
        final pathPoints = multiPaths[part]!;
        if (pathPoints.isEmpty) return;

        final trackingPaint = Paint()
          ..color = color
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        Path path = Path();
        if (pathPoints.isNotEmpty) {
          Offset start = _transformPoint(pathPoints.first, size);
          path.moveTo(start.dx, start.dy);
          for (int i = 1; i < pathPoints.length; i++) {
            Offset p = _transformPoint(pathPoints[i], size);
            path.lineTo(p.dx, p.dy);
          }
        }
        canvas.drawPath(path, trackingPaint);
      });
    }

    // 2. 뼈대 그리기
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = poseColor;

    final landmarkPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0
      ..color = poseColor;

    void drawLine(PoseLandmarkType t1, PoseLandmarkType t2) {
      final PoseLandmark? joint1 = pose.landmarks[t1];
      final PoseLandmark? joint2 = pose.landmarks[t2];
      if (joint1 != null && joint2 != null && joint1.likelihood > 0.5 && joint2.likelihood > 0.5) {
        final p1 = _transformPoint(Offset(joint1.x, joint1.y), size);
        final p2 = _transformPoint(Offset(joint2.x, joint2.y), size);
        canvas.drawLine(p1, p2, paint);
      }
    }

    pose.landmarks.forEach((type, landmark) {
      if (!_isKeyJoint(type)) return;
      final offset = _transformPoint(Offset(landmark.x, landmark.y), size);
      canvas.drawCircle(offset, 3.0, landmarkPaint);
    });

    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    drawLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    drawLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    drawLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);

    // 3. 셋업 기준선
    if (referenceMode != 'NONE') {
      List<PoseLandmarkType> targets = [];
      if (referenceMode == 'RIGHT') {
        targets = [PoseLandmarkType.rightWrist, PoseLandmarkType.rightElbow];
      } else if (referenceMode == 'LEFT') {
        targets = [PoseLandmarkType.leftWrist, PoseLandmarkType.leftElbow];
      }

      for (var partType in targets) {
        if (!setupHeights.containsKey(partType)) continue;

        double targetY = setupHeights[partType]!;
        Color displayColor = activeTrackColors[partType] ?? allPartColors[partType] ?? Colors.white;

        Offset screenPoint = _transformPoint(Offset(0, targetY), size);
        double screenY = screenPoint.dy;

        final shadowPaint = Paint()
          ..color = Colors.black.withOpacity(0.5)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

        final guidePaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

        double dashWidth = 8, dashSpace = 4, startX = 0;
        while (startX < size.width) {
          canvas.drawLine(Offset(startX, screenY + 1), Offset(startX + dashWidth, screenY + 1), shadowPaint);
          canvas.drawLine(Offset(startX, screenY), Offset(startX + dashWidth, screenY), guidePaint);
          startX += dashWidth + dashSpace;
        }

        String label = _getPartLabel(partType);
        final textSpan = TextSpan(
          text: ' $label SET ',
          style: TextStyle(color: displayColor, fontSize: 11, fontWeight: FontWeight.bold, backgroundColor: Colors.black54),
        );
        final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        textPainter.layout();
        textPainter.paint(canvas, Offset(5, screenY - 18));
      }
    }

    // 4. 릴리즈 포인트 (시간 순서 표시 + 토글 제어)
    // 🔥 [수정됨] showReleasePoints가 true일 때만 그림
    if (showReleasePoints && releasePoints.isNotEmpty) {

      final pointPaint = Paint()
        ..color = Colors.redAccent
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final textStyle = TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)]
      );

      for (int i = 0; i < releasePoints.length; i++) {
        final data = releasePoints[i];

        // 시간차 공격: 미래의 점은 그리지 않음
        if (data.frameIndex > currentFrameIndex) continue;

        Offset start = _transformPoint(data.point, size);

        // 점 그리기
        canvas.drawCircle(start, 5.0, pointPaint);
        canvas.drawCircle(start, 5.0, borderPaint);

        // 번호 표시 (1, 2, 3...)
        final textSpan = TextSpan(text: '${i + 1}', style: textStyle);
        final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        textPainter.layout();
        textPainter.paint(canvas, Offset(start.dx - 4, start.dy - 18));
      }
    }
  }

  // Helper Functions
  bool _isKeyJoint(PoseLandmarkType type) {
    return [
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle,
      PoseLandmarkType.nose
    ].contains(type);
  }

  String _getPartLabel(PoseLandmarkType type) {
    switch (type) {
      case PoseLandmarkType.rightElbow: return "R-ELBOW";
      case PoseLandmarkType.leftElbow: return "L-ELBOW";
      case PoseLandmarkType.rightWrist: return "R-WRIST";
      case PoseLandmarkType.leftWrist: return "L-WRIST";
      default: return "";
    }
  }

  Offset _transformPoint(Offset point, Size size) {
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    final double offsetX = (size.width - imageSize.width * scale) / 2;
    final double offsetY = (size.height - imageSize.height * scale) / 2;

    return Offset(point.dx * scale + offsetX, point.dy * scale + offsetY);
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) => true;
}