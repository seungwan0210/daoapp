import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final Color poseColor;

  // ✅ [수정] 다중 경로 지원
  // 부위별 경로: {RightWrist: [p1, p2...], LeftElbow: [p1, p2...]}
  final Map<PoseLandmarkType, List<Offset>> multiPaths;
  // 부위별 색상: {RightWrist: Yellow, ...}
  final Map<PoseLandmarkType, Color> trackColors;

  PosePainter(
      this.poses,
      this.imageSize, {
        this.poseColor = Colors.white,
        this.multiPaths = const {},
        this.trackColors = const {},
      });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 다중 트래킹 경로 그리기
    multiPaths.forEach((part, pathPoints) {
      if (pathPoints.isEmpty) return;

      final color = trackColors[part] ?? Colors.yellow;
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

    // 2. 뼈대 그리기 (기존 동일)
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = poseColor;

    final landmarkPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0
      ..color = poseColor;

    final Set<PoseLandmarkType> visibleLandmarks = {
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle,
    };

    for (final pose in poses) {
      pose.landmarks.forEach((type, landmark) {
        if (!visibleLandmarks.contains(type)) return;
        final offset = _transformPoint(Offset(landmark.x, landmark.y), size);
        if (offset.dx < 0 || offset.dx > size.width || offset.dy < 0 || offset.dy > size.height) return;
        canvas.drawCircle(offset, 2.5, landmarkPaint);
      });

      void paintLine(PoseLandmarkType type1, PoseLandmarkType type2) {
        final PoseLandmark? joint1 = pose.landmarks[type1];
        final PoseLandmark? joint2 = pose.landmarks[type2];
        if (joint1 != null && joint2 != null && joint1.likelihood > 0.5 && joint2.likelihood > 0.5) {
          final p1 = _transformPoint(Offset(joint1.x, joint1.y), size);
          final p2 = _transformPoint(Offset(joint2.x, joint2.y), size);
          canvas.drawLine(p1, p2, paint);
        }
      }

      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);

      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
      paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);

      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
      paintLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
      paintLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
      paintLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
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