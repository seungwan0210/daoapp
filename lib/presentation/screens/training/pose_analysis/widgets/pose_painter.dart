import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final Color poseColor;

  final Map<PoseLandmarkType, List<Offset>> multiPaths;   // 전체 경로 데이터 (기준선용 포함)
  final Map<PoseLandmarkType, Color> activeTrackColors;   // 활성화된 트래킹 색상 (그리기용)
  final Map<PoseLandmarkType, Color> allPartColors;       // 전체 부위 색상표 (라벨용)

  final bool showTrackingLines;
  final String referenceMode;

  PosePainter(
      this.poses,
      this.imageSize, {
        this.poseColor = Colors.white,
        this.multiPaths = const {},
        this.activeTrackColors = const {},
        this.allPartColors = const {},
        this.showTrackingLines = true,
        this.referenceMode = 'NONE',
      });

  @override
  void paint(Canvas canvas, Size size) {

    // 1. 트래킹 라인 그리기 (마스터 토글 ON && 사용자가 칩으로 켠 부위만)
    if (showTrackingLines) {
      // activeTrackColors에 있는 키만 순회해서 그립니다.
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

    // 2. 뼈대 그리기 (기존 동일)
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = poseColor;

    final landmarkPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0
      ..color = poseColor;

    for (final pose in poses) {
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
        if (offset.dx < 0 || offset.dx > size.width || offset.dy < 0 || offset.dy > size.height) return;
        canvas.drawCircle(offset, 2.5, landmarkPaint);
      });

      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
      drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
      drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
      drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
    }

    // ============================================================
    // 3. 스마트 셋업 기준선 (트래킹 켜짐 여부와 상관없이 그리기)
    // ============================================================

    if (referenceMode != 'NONE') {
      // multiPaths에는 기준선용 데이터도 이미 계산되어 들어와 있음
      multiPaths.forEach((partType, points) {
        // 팔꿈치/손목 아니면 패스
        if (!_isReferenceTarget(partType)) return;

        // 모드 체크
        bool isRightPart = partType.name.contains('right');
        bool isLeftPart = partType.name.contains('left');

        if (referenceMode == 'RIGHT' && !isRightPart) return;
        if (referenceMode == 'LEFT' && !isLeftPart) return;

        if (points.isEmpty) return;

        // 색상 결정 (트래킹 켜져있으면 그 색, 아니면 기본 색)
        Color displayColor = activeTrackColors[partType] ?? allPartColors[partType] ?? Colors.white;

        // 셋업 높이 계산
        List<double> validYPoints = [];
        for (var point in points) {
          if (point.dy > 0) validYPoints.add(point.dy);
        }

        if (validYPoints.isNotEmpty) {
          validYPoints.sort();
          int topRangeCount = (validYPoints.length * 0.3).ceil();
          if (topRangeCount == 0) topRangeCount = validYPoints.length;
          List<double> aimingCandidates = validYPoints.sublist(0, topRangeCount);
          double targetY = aimingCandidates[(aimingCandidates.length / 2).floor()];

          Offset screenPoint = _transformPoint(Offset(0, targetY), size);
          double screenY = screenPoint.dy;

          // 선 스타일
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

          // 라벨 표시
          String label = _getPartLabel(partType);
          final textSpan = TextSpan(
            text: ' $label SET ',
            style: TextStyle(
                color: displayColor, // 부위별 고유 색상 사용
                fontSize: 11,
                fontWeight: FontWeight.bold,
                backgroundColor: Colors.black54
            ),
          );
          final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
          textPainter.layout();
          textPainter.paint(canvas, Offset(5, screenY - 18));
        }
      });
    }
  }

  bool _isReferenceTarget(PoseLandmarkType type) {
    return [
      PoseLandmarkType.rightElbow, PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightWrist, PoseLandmarkType.leftWrist,
    ].contains(type);
  }

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