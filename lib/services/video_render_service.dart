import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

// 렌더링용 릴리즈 포인트 모델
class RenderReleasePoint {
  final Offset point;
  final int frameIndex;
  RenderReleasePoint(this.point, this.frameIndex);
}

class VideoRenderService {

  Future<String?> renderExportVideo({
    required String originalVideoPath,
    required Map<int, List<Pose>> analysisResults,
    required Map<PoseLandmarkType, Color> activeTracks,
    required String referenceMode,
    required bool showTrackingLines, // ✅ 토글: 궤적 표시 여부
    required bool showReleasePoints, // ✅ 토글: 릴리즈 포인트 표시 여부
    required Function(double) onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final String rawFramesDir = '${tempDir.path}/raw_frames_${DateTime.now().millisecondsSinceEpoch}';
    final String processedFramesDir = '${tempDir.path}/proc_frames_${DateTime.now().millisecondsSinceEpoch}';
    final String outputVideoPath = '${tempDir.path}/output_${DateTime.now().millisecondsSinceEpoch}.mp4';

    await Directory(rawFramesDir).create();
    await Directory(processedFramesDir).create();

    try {
      // 1️⃣ 분석 (미리보기 화면과 로직 100% 일치)
      final analysisData = _analyzeKeyMoments(analysisResults, referenceMode);
      Map<PoseLandmarkType, double> referenceHeights = analysisData['heights'];
      List<RenderReleasePoint> releasePoints = analysisData['releasePoints'];

      // 2️⃣ 프레임 추출
      // -q:v 2로 설정하여 추출 화질을 높임 (1~31, 낮을수록 고화질)
      String extractCmd = '-i "$originalVideoPath" -vf fps=30 -q:v 2 "$rawFramesDir/frame_%04d.jpg"';
      await FFmpegKit.execute(extractCmd);

      final List<FileSystemEntity> frameFiles = Directory(rawFramesDir).listSync()
        ..sort((a, b) => a.path.compareTo(b.path));

      int totalFrames = frameFiles.length;

      Map<PoseLandmarkType, List<Offset>> accumulatedPaths = {};
      for (var key in activeTracks.keys) {
        accumulatedPaths[key] = [];
      }

      // 3️⃣ 그리기 루프
      for (int i = 0; i < totalFrames; i++) {
        File frameFile = frameFiles[i] as File;
        final Uint8List bytes = await frameFile.readAsBytes();
        img.Image? originalImage = img.decodeJpg(bytes);

        if (originalImage != null) {
          _drawSkeletonAndTracks(
            image: originalImage,
            frameIndex: i,
            analysisResults: analysisResults,
            activeTracks: activeTracks,
            accumulatedPaths: accumulatedPaths,
            referenceHeights: referenceHeights,
            referenceMode: referenceMode,
            releasePoints: releasePoints,
            showTrackingLines: showTrackingLines, // 전달
            showReleasePoints: showReleasePoints, // 전달
          );

          String outPath = '$processedFramesDir/frame_${i.toString().padLeft(4, '0')}.jpg';
          await File(outPath).writeAsBytes(img.encodeJpg(originalImage, quality: 90));
        }

        // 🔥 [중요] UI 스레드가 숨을 쉴 수 있게 해주어 병렬 처리(광고 표시 등)가 끊기지 않게 함
        await Future.delayed(Duration.zero);

        onProgress((i / totalFrames) * 0.8);
      }

      // 4️⃣ 인코딩
      // ultrafast: 인코딩 속도 최우선 / crf 23: 화질 적당히 유지
      String encodeCmd = '-framerate 30 -i "$processedFramesDir/frame_%04d.jpg" -c:v libx264 -preset ultrafast -crf 23 -pix_fmt yuv420p "$outputVideoPath"';
      await FFmpegKit.execute(encodeCmd).then((session) async {
        final returnCode = await session.getReturnCode();
        if (!ReturnCode.isSuccess(returnCode)) {
          throw Exception("FFmpeg Encoding Failed");
        }
      });

      onProgress(1.0);
      return outputVideoPath;

    } catch (e) {
      debugPrint("렌더링 오류: $e");
      return null;
    } finally {
      // 임시 파일 정리
      if (await Directory(rawFramesDir).exists()) await Directory(rawFramesDir).delete(recursive: true);
      if (await Directory(processedFramesDir).exists()) await Directory(processedFramesDir).delete(recursive: true);
    }
  }

  // 🧠 [분석 로직] 결과 화면과 동일하게 수정됨
  Map<String, dynamic> _analyzeKeyMoments(Map<int, List<Pose>> analysisResults, String mode) {
    Map<PoseLandmarkType, double> heights = {};
    List<RenderReleasePoint> releasePoints = [];

    // 모드가 없으면 분석하지 않고 빈 값 반환
    if (mode == 'NONE') return {'heights': heights, 'releasePoints': releasePoints};

    bool isRight = mode == 'RIGHT';
    // 만약 자동 감지 로직이 필요하다면 여기서 추가 가능하지만,
    // 보통 렌더링 시점엔 사용자가 선택한 모드('RIGHT' or 'LEFT')가 확실하므로 그대로 진행

    PoseLandmarkType wrist = isRight ? PoseLandmarkType.rightWrist : PoseLandmarkType.leftWrist;
    PoseLandmarkType elbow = isRight ? PoseLandmarkType.rightElbow : PoseLandmarkType.leftElbow;
    PoseLandmarkType shoulder = isRight ? PoseLandmarkType.rightShoulder : PoseLandmarkType.leftShoulder;
    PoseLandmarkType hip = isRight ? PoseLandmarkType.rightHip : PoseLandmarkType.leftHip;

    List<int> sortedFrames = analysisResults.keys.toList()..sort();

    // 1. 스탠스 식별 (8.0 기준)
    Set<int> stanceFrames = {};
    List<double> validElbowYs = [];
    List<double> validWristYs = [];
    int window = 5;

    for (int i = window; i < sortedFrames.length - window; i++) {
      int currFrame = sortedFrames[i];
      int prevFrame = sortedFrames[i - window];

      final currPose = analysisResults[currFrame]?.firstOrNull;
      final prevPose = analysisResults[prevFrame]?.firstOrNull;
      if (currPose == null || prevPose == null) continue;

      final currHip = currPose.landmarks[hip];
      final prevHip = prevPose.landmarks[hip];
      if (currHip == null || prevHip == null) continue;

      double movement = (currHip.x - prevHip.x).abs();

      if (movement < 8.0) {
        stanceFrames.add(currFrame);
        final e = currPose.landmarks[elbow];
        final w = currPose.landmarks[wrist];
        if (e != null && e.y > 0) validElbowYs.add(e.y);
        if (w != null && w.y > 0) validWristYs.add(w.y);
      }
    }

    if (validElbowYs.isNotEmpty) {
      validElbowYs.sort();
      heights[elbow] = validElbowYs[(validElbowYs.length * 0.3).toInt()];
    }
    if (validWristYs.isNotEmpty) {
      validWristYs.sort();
      heights[wrist] = validWristYs[(validWristYs.length * 0.3).toInt()];
    }

    // 2. 릴리즈 포인트 (결과 화면과 100% 동일 로직 적용)
    int lastReleaseFrame = -999;

    for (int i = 1; i < sortedFrames.length; i++) {
      int currF = sortedFrames[i];
      int prevF = sortedFrames[i - 1];

      // 스탠스 상태가 아니면 무시
      if (!stanceFrames.contains(currF)) continue;

      final currPose = analysisResults[currF]?.firstOrNull;
      final prevPose = analysisResults[prevF]?.firstOrNull;
      if (currPose == null || prevPose == null) continue;

      final w = currPose.landmarks[wrist];
      final e = currPose.landmarks[elbow];

      if (w == null || e == null) continue;

      // 🔥 [조건 1] 높이 체크: 손목이 팔꿈치보다 높아야 함 (화면 좌표계상 y가 작아야 함)
      bool isHigherThanElbow = w.y < e.y;
      if (!isHigherThanElbow) continue;

      // 각도 계산
      double currAngle = _calculateAngle(currPose, shoulder, elbow, wrist);
      double prevAngle = _calculateAngle(prevPose, shoulder, elbow, wrist);

      // 🔥 [조건 2] 교차 검증: 90도를 통과하는 순간
      bool isCrossing = (prevAngle < 90.0) && (currAngle >= 90.0);

      if (isCrossing) {
        // 중복 방지 (15프레임 내 재감지 금지)
        if (currF - lastReleaseFrame > 15) {
          releasePoints.add(RenderReleasePoint(Offset(w.x, w.y), currF));
          lastReleaseFrame = currF;
        }
      }
    }

    return {'heights': heights, 'releasePoints': releasePoints};
  }

  double _calculateAngle(Pose pose, PoseLandmarkType a, PoseLandmarkType b, PoseLandmarkType c) {
    final la = pose.landmarks[a]; final lb = pose.landmarks[b]; final lc = pose.landmarks[c];
    if (la == null || lb == null || lc == null) return 180;
    double radians = math.atan2(lc.y - lb.y, lc.x - lb.x) - math.atan2(la.y - lb.y, la.x - lb.x);
    double angle = (radians * 180.0 / math.pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  // 🖌️ 그리기 로직 (토글 적용)
  void _drawSkeletonAndTracks({
    required img.Image image,
    required int frameIndex,
    required Map<int, List<Pose>> analysisResults,
    required Map<PoseLandmarkType, Color> activeTracks,
    required Map<PoseLandmarkType, List<Offset>> accumulatedPaths,
    required Map<PoseLandmarkType, double> referenceHeights,
    required String referenceMode,
    required List<RenderReleasePoint> releasePoints,
    required bool showTrackingLines,
    required bool showReleasePoints,
  }) {
    Pose? smoothedPose = _getSmoothedPose(frameIndex, analysisResults);
    if (smoothedPose == null) return;

    double baseWidth = 720.0;
    double scale = image.width / baseWidth;
    if (scale < 1.0) scale = 1.0;

    // 1️⃣ 트래킹 라인 (showTrackingLines 체크)
    if (showTrackingLines) {
      activeTracks.forEach((partType, color) {
        final landmark = smoothedPose.landmarks[partType];
        if (landmark != null && landmark.likelihood > 0.6) {
          accumulatedPaths[partType]!.add(Offset(landmark.x, landmark.y));
        }

        List<Offset> path = _applySmoothing(accumulatedPaths[partType]!, windowSize: 4);

        if (path.length > 1) {
          img.Color drawColor = _convertColor(color);
          int thickness = (3.0 * scale).toInt();

          for (int k = 0; k < path.length - 1; k++) {
            img.drawLine(image,
                x1: path[k].dx.toInt(), y1: path[k].dy.toInt(),
                x2: path[k+1].dx.toInt(), y2: path[k+1].dy.toInt(),
                color: drawColor, thickness: thickness
            );
          }
        }
      });
    }
    // 꺼져있을 때는 accumulatedPaths에 추가하지 않음 (또는 추가만 하고 그리지 않게 할 수도 있으나, 여기선 아예 안 그림)

    // 2️⃣ 뼈대 그리기 (항상 그림)
    img.Color boneColor = img.ColorRgba8(255, 255, 255, 255);
    img.Color jointColor = img.ColorRgba8(255, 255, 255, 255);
    int boneThickness = (2.0 * scale).toInt();
    int jointRadius = (4.0 * scale).toInt();

    void drawLine(PoseLandmarkType t1, PoseLandmarkType t2) {
      final l1 = smoothedPose.landmarks[t1];
      final l2 = smoothedPose.landmarks[t2];
      if (l1 != null && l2 != null && l1.likelihood > 0.5 && l2.likelihood > 0.5) {
        img.drawLine(image, x1: l1.x.toInt(), y1: l1.y.toInt(), x2: l2.x.toInt(), y2: l2.y.toInt(), color: boneColor, thickness: boneThickness);
      }
    }
    void drawPoint(PoseLandmarkType t) {
      final l = smoothedPose.landmarks[t];
      if (l != null && l.likelihood > 0.5) {
        img.fillCircle(image, x: l.x.toInt(), y: l.y.toInt(), radius: jointRadius, color: jointColor);
      }
    }

    // 상체 위주 그리기
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    drawLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);

    drawPoint(PoseLandmarkType.leftShoulder);
    drawPoint(PoseLandmarkType.rightShoulder);
    drawPoint(PoseLandmarkType.leftElbow);
    drawPoint(PoseLandmarkType.rightElbow);
    drawPoint(PoseLandmarkType.leftWrist);
    drawPoint(PoseLandmarkType.rightWrist);


    // 3️⃣ 기준선 그리기 (항상 그림 - 모드에 따라)
    if (referenceMode != 'NONE') {
      img.Color guideColor = img.ColorRgba8(255, 255, 255, 255);
      img.Color shadowColor = img.ColorRgba8(0, 0, 0, 128);

      referenceHeights.forEach((type, y) {
        int lineY = y.toInt();
        int lineThickness = (1.5 * scale).toInt();
        int dashWidth = (15 * scale).toInt();
        int dashSpace = (8 * scale).toInt();

        for (int x = 0; x < image.width; x += dashWidth + dashSpace) {
          int endX = x + dashWidth;
          if (endX > image.width) endX = image.width;
          img.drawLine(image, x1: x, y1: lineY + 1, x2: endX, y2: lineY + 1, color: shadowColor, thickness: lineThickness + 1);
          img.drawLine(image, x1: x, y1: lineY, x2: endX, y2: lineY, color: guideColor, thickness: lineThickness);
        }
      });
    }

    // 4️⃣ 릴리즈 포인트 (showReleasePoints 체크)
    if (showReleasePoints && releasePoints.isNotEmpty) {
      for (int k = 0; k < releasePoints.length; k++) {
        final pointData = releasePoints[k];

        // 현재 프레임 이전에 발생한 릴리즈 포인트만 그림
        if (pointData.frameIndex <= frameIndex) {
          int cx = pointData.point.dx.toInt();
          int cy = pointData.point.dy.toInt();
          int radius = (12 * scale).toInt();

          img.fillCircle(image, x: cx, y: cy, radius: radius + 2, color: img.ColorRgba8(255, 255, 255, 255));
          img.fillCircle(image, x: cx, y: cy, radius: radius, color: img.ColorRgba8(255, 50, 50, 255));
          // 번호 표시 (1, 2, 3...)
          img.drawString(image, '${k + 1}', font: img.arial24, x: cx - 6, y: cy - 35, color: img.ColorRgba8(255, 255, 255, 255));
        }
      }
    }
  }

  Pose? _getSmoothedPose(int currentIndex, Map<int, List<Pose>> analysisResults) {
    if (!analysisResults.containsKey(currentIndex) || analysisResults[currentIndex]!.isEmpty) return null;
    int window = 2;
    Pose basePose = analysisResults[currentIndex]!.first;
    Map<PoseLandmarkType, PoseLandmark> newLandmarks = {};

    basePose.landmarks.forEach((type, landmark) {
      double sumX = 0; double sumY = 0; int count = 0;
      for (int i = currentIndex - window; i <= currentIndex + window; i++) {
        if (analysisResults.containsKey(i) && analysisResults[i]!.isNotEmpty) {
          Pose p = analysisResults[i]!.first;
          if (p.landmarks.containsKey(type) && p.landmarks[type]!.likelihood > 0.5) {
            sumX += p.landmarks[type]!.x; sumY += p.landmarks[type]!.y; count++;
          }
        }
      }
      if (count > 0) {
        newLandmarks[type] = PoseLandmark(type: type, x: sumX / count, y: sumY / count, z: landmark.z, likelihood: landmark.likelihood);
      } else {
        newLandmarks[type] = landmark;
      }
    });
    return Pose(landmarks: newLandmarks);
  }

  List<Offset> _applySmoothing(List<Offset> points, {int windowSize = 4}) {
    if (points.length < windowSize) return points;
    List<Offset> smoothedPoints = [];
    for (int i = 0; i < points.length; i++) {
      double sumX = 0; double sumY = 0; int count = 0;
      for (int j = 0; j < windowSize; j++) {
        if (i - j >= 0) { sumX += points[i - j].dx; sumY += points[i - j].dy; count++; }
      }
      smoothedPoints.add(Offset(sumX / count, sumY / count));
    }
    return smoothedPoints;
  }

  img.Color _convertColor(Color c) {
    return img.ColorRgba8(c.red, c.green, c.blue, 255);
  }
}