import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
// ✅ ReleasePointInfo 클래스를 인식하기 위해 import 필요 (같은 파일에 넣거나 import)
import 'package:daoapp/presentation/providers/training/pose_analysis_provider.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final InputImageRotation rotation;
  final Color poseColor;
  final List<Offset> trackingPath;
  final Color trackingColor;
  // ✅ [수정] 단순 Offset이 아니라 정보(좌표+텍스트)가 담긴 객체 리스트
  final List<ReleasePointInfo> releasePoints;

  PosePainter(
      this.poses,
      this.imageSize,
      this.rotation, {
        this.poseColor = Colors.white,
        this.trackingPath = const [],
        this.trackingColor = Colors.yellow,
        this.releasePoints = const [],
      });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 트래킹 경로 (이제 잘라진 경로가 들어오므로 그려지는 효과 남)
    if (trackingPath.isNotEmpty) {
      final trackingPaint = Paint()
        ..color = trackingColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      Path path = Path();
      if (trackingPath.isNotEmpty) {
        Offset start = _transformPoint(trackingPath.first, size);
        path.moveTo(start.dx, start.dy);
        for (int i = 1; i < trackingPath.length; i++) {
          Offset p = _transformPoint(trackingPath[i], size);
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, trackingPaint);
    }

    // 2. 릴리즈 포인트 + 각도 텍스트 그리기
    final releasePaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    final releaseBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final info in releasePoints) {
      Offset p = _transformPoint(info.point, size);

      // 점 그리기
      canvas.drawCircle(p, 5.0, releasePaint);
      canvas.drawCircle(p, 5.0, releaseBorderPaint);

      // 텍스트 그리기 (각도)
      final textSpan = TextSpan(
        text: info.angleText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 2, color: Colors.black)],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      // 점 바로 위에 글씨 표시
      textPainter.paint(canvas, Offset(p.dx - 10, p.dy - 20));
    }

    // 3. 뼈대 그리기 (기존과 동일)
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = poseColor;

    final landmarkPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.5
      ..color = poseColor;

    final Set<PoseLandmarkType> visibleLandmarks = {
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftIndex, PoseLandmarkType.rightIndex,
      PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
    };

    for (final pose in poses) {
      pose.landmarks.forEach((type, landmark) {
        if (!visibleLandmarks.contains(type)) return;
        final offset = _transformPoint(Offset(landmark.x, landmark.y), size);
        if (offset.dx < 0 || offset.dx > size.width || offset.dy < 0 || offset.dy > size.height) return;
        canvas.drawCircle(offset, 2.0, landmarkPaint);
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
      paintLine(PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex);

      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
      paintLine(PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex);
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
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return true; // 실시간 애니메이션을 위해 항상 다시 그리기 허용
  }
}