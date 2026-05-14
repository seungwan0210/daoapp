import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class RenderReleasePoint {
  final Offset point;
  final int frameIndex;
  RenderReleasePoint(this.point, this.frameIndex);
}

// 📦 [개별 프레임 작업 데이터]
class SingleFrameTask {
  final int frameIndex;
  final Uint8List imageBytes;
  final Map<PoseLandmarkType, Offset> landmarks;
  final Map<PoseLandmarkType, int> activeTrackColors;
  final Map<PoseLandmarkType, List<Offset>> accumulatedPaths;

  SingleFrameTask({
    required this.frameIndex,
    required this.imageBytes,
    required this.landmarks,
    required this.activeTrackColors,
    required this.accumulatedPaths,
  });
}

// 📦 [묶음 배송 가방] 한 번에 여러 프레임을 보낼 데이터 모델
class BatchTaskData {
  final List<SingleFrameTask> tasks; // 여러 프레임의 작업 목록
  final Map<PoseLandmarkType, double> referenceHeights;
  final String referenceMode;
  final List<RenderReleasePoint> releasePoints;
  final bool showTrackingLines;
  final bool showReleasePoints;

  BatchTaskData({
    required this.tasks,
    required this.referenceHeights,
    required this.referenceMode,
    required this.releasePoints,
    required this.showTrackingLines,
    required this.showReleasePoints,
  });
}

// 📤 [결과 데이터] 처리된 이미지 바이트 목록
class BatchResult {
  final Map<int, Uint8List> processedImages; // frameIndex: bytes
  BatchResult(this.processedImages);
}

class VideoRenderService {

  Future<String?> renderExportVideo({
    required String originalVideoPath,
    required Map<int, List<Pose>> analysisResults,
    required Map<PoseLandmarkType, Color> activeTracks,
    required String referenceMode,
    required bool showTrackingLines,
    required bool showReleasePoints,
    required Function(double) onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final String rawFramesDir = '${tempDir.path}/raw_frames_${DateTime.now().millisecondsSinceEpoch}';
    final String processedFramesDir = '${tempDir.path}/proc_frames_${DateTime.now().millisecondsSinceEpoch}';
    final String outputVideoPath = '${tempDir.path}/output_${DateTime.now().millisecondsSinceEpoch}.mp4';

    await Directory(rawFramesDir).create();
    await Directory(processedFramesDir).create();

    try {
      // 1️⃣ 분석
      final analysisData = _analyzeKeyMoments(analysisResults, referenceMode, activeTracks);
      Map<PoseLandmarkType, double> referenceHeights = analysisData['heights'];
      List<RenderReleasePoint> releasePoints = analysisData['releasePoints'];

      // 2️⃣ 프레임 추출
      String extractCmd = '-i "$originalVideoPath" -vf fps=30 -q:v 2 "$rawFramesDir/frame_%04d.jpg"';
      await FFmpegKit.execute(extractCmd);

      final List<FileSystemEntity> frameFiles = Directory(rawFramesDir).listSync()
        ..sort((a, b) => a.path.compareTo(b.path));

      int totalFrames = frameFiles.length;

      // 경로 누적용 변수
      Map<PoseLandmarkType, List<Offset>> accumulatedPaths = {};
      for (var key in activeTracks.keys) {
        accumulatedPaths[key] = [];
      }

      Map<PoseLandmarkType, int> activeTrackColorsInt = activeTracks.map(
              (k, v) => MapEntry(k, v.value)
      );

      // 🔥 [핵심 변경] 배치 사이즈 설정 (한 번에 10장씩 처리)
      // 10장씩 묶으면 Isolate 생성 횟수가 1/10로 줄어들어 속도가 훨씬 빨라집니다.
      int batchSize = 10;

      for (int i = 0; i < totalFrames; i += batchSize) {
        // 이번 배치에 포함될 프레임들 수집
        List<SingleFrameTask> batchTasks = [];

        for (int j = i; j < i + batchSize && j < totalFrames; j++) {
          File frameFile = frameFiles[j] as File;
          final Uint8List bytes = await frameFile.readAsBytes();

          // Pose 데이터 간소화
          Map<PoseLandmarkType, Offset> currentLandmarks = {};
          Pose? pose = _getSmoothedPose(j, analysisResults);
          if (pose != null) {
            pose.landmarks.forEach((type, landmark) {
              currentLandmarks[type] = Offset(landmark.x, landmark.y);
            });
          }

          // 트래킹 경로 업데이트 (메인 스레드에서 관리)
          if (showTrackingLines) {
            activeTracks.forEach((partType, _) {
              if (currentLandmarks.containsKey(partType)) {
                accumulatedPaths[partType]!.add(currentLandmarks[partType]!);
              }
            });
          }

          // 개별 작업 추가 (경로는 복사해서 전달해야 함)
          batchTasks.add(SingleFrameTask(
            frameIndex: j,
            imageBytes: bytes,
            landmarks: currentLandmarks,
            activeTrackColors: activeTrackColorsInt,
            accumulatedPaths: Map.from(accumulatedPaths).map((k, v) => MapEntry(k, List.from(v))),
          ));
        }

        // 📦 배치 가방 싸기
        final batchData = BatchTaskData(
          tasks: batchTasks,
          referenceHeights: referenceHeights,
          referenceMode: referenceMode,
          releasePoints: releasePoints,
          showTrackingLines: showTrackingLines,
          showReleasePoints: showReleasePoints,
        );

        // 🔥 [병렬 처리] 10장을 한 번에 처리하러 보냄 (생성 오버헤드 1/10 감소)
        final BatchResult result = await compute(_processBatchTask, batchData);

        // 결과 저장
        for (var entry in result.processedImages.entries) {
          int frameIdx = entry.key;
          Uint8List processedBytes = entry.value;
          String outPath = '$processedFramesDir/frame_${frameIdx.toString().padLeft(4, '0')}.jpg';
          await File(outPath).writeAsBytes(processedBytes);
        }

        // 진행률 업데이트
        onProgress(((i + batchTasks.length) / totalFrames) * 0.8);
      }

      // 4️⃣ 인코딩
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
      if (await Directory(rawFramesDir).exists()) await Directory(rawFramesDir).delete(recursive: true);
      if (await Directory(processedFramesDir).exists()) await Directory(processedFramesDir).delete(recursive: true);
    }
  }

  // ... (분석 로직들은 기존과 100% 동일하여 생략 가능하지만, 복붙 편의를 위해 유지) ...
  Map<String, dynamic> _analyzeKeyMoments(
      Map<int, List<Pose>> analysisResults,
      String mode,
      Map<PoseLandmarkType, Color> activeTracks
      ) {
    Map<PoseLandmarkType, double> heights = {};
    List<RenderReleasePoint> releasePoints = [];

    bool isRight = true;
    if (mode == 'LEFT') isRight = false;
    else if (mode == 'RIGHT') isRight = true;
    else if (activeTracks.containsKey(PoseLandmarkType.leftWrist) && !activeTracks.containsKey(PoseLandmarkType.rightWrist)) isRight = false;

    PoseLandmarkType wrist = isRight ? PoseLandmarkType.rightWrist : PoseLandmarkType.leftWrist;
    PoseLandmarkType elbow = isRight ? PoseLandmarkType.rightElbow : PoseLandmarkType.leftElbow;
    PoseLandmarkType shoulder = isRight ? PoseLandmarkType.rightShoulder : PoseLandmarkType.leftShoulder;
    PoseLandmarkType hip = isRight ? PoseLandmarkType.rightHip : PoseLandmarkType.leftHip;

    List<int> sortedFrames = analysisResults.keys.toList()..sort();
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

      if ((currHip.x - prevHip.x).abs() < 8.0) {
        stanceFrames.add(currFrame);
        final e = currPose.landmarks[elbow];
        final w = currPose.landmarks[wrist];
        if (e != null && e.y > 0) validElbowYs.add(e.y);
        if (w != null && w.y > 0) validWristYs.add(w.y);
      }
    }

    if (mode != 'NONE') {
      if (validElbowYs.isNotEmpty) {
        validElbowYs.sort();
        heights[elbow] = validElbowYs[(validElbowYs.length * 0.3).toInt()];
      }
      if (validWristYs.isNotEmpty) {
        validWristYs.sort();
        heights[wrist] = validWristYs[(validWristYs.length * 0.3).toInt()];
      }
    }

    int lastReleaseFrame = -999;
    for (int i = 1; i < sortedFrames.length; i++) {
      int currF = sortedFrames[i];
      int prevF = sortedFrames[i - 1];
      if (!stanceFrames.contains(currF)) continue;

      final currPose = analysisResults[currF]?.firstOrNull;
      final prevPose = analysisResults[prevF]?.firstOrNull;
      if (currPose == null || prevPose == null) continue;

      final w = currPose.landmarks[wrist];
      final e = currPose.landmarks[elbow];
      if (w == null || e == null) continue;

      if (w.y >= e.y) continue;

      double currAngle = _calculateAngle(currPose, shoulder, elbow, wrist);
      double prevAngle = _calculateAngle(prevPose, shoulder, elbow, wrist);

      if (prevAngle < 90.0 && currAngle >= 90.0) {
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
}

// 🌍 [배치 작업 처리 함수] Isolate에서 실행됨
// 한 번 호출되면 10장을 연속으로 처리하고 결과를 반환함 (효율성 극대화)
BatchResult _processBatchTask(BatchTaskData batchData) {
  Map<int, Uint8List> results = {};

  for (var task in batchData.tasks) {
    // 1. 이미지 디코딩 (가장 무거운 작업)
    img.Image image = img.decodeJpg(task.imageBytes)!;

    double baseWidth = 720.0;
    double scale = image.width / baseWidth;
    if (scale < 1.0) scale = 1.0;

    // 2. 트래킹 라인
    if (batchData.showTrackingLines) {
      task.activeTrackColors.forEach((partType, colorInt) {
        if (task.accumulatedPaths.containsKey(partType)) {
          List<Offset> path = _applySmoothingStatic(task.accumulatedPaths[partType]!, windowSize: 4);
          if (path.length > 1) {
            img.Color drawColor = img.ColorRgba8(
                (colorInt >> 16) & 0xFF, (colorInt >> 8) & 0xFF, colorInt & 0xFF, 255);
            int thickness = (3.0 * scale).toInt();
            for (int k = 0; k < path.length - 1; k++) {
              img.drawLine(image,
                  x1: path[k].dx.toInt(), y1: path[k].dy.toInt(),
                  x2: path[k+1].dx.toInt(), y2: path[k+1].dy.toInt(),
                  color: drawColor, thickness: thickness);
            }
          }
        }
      });
    }

    // 3. 뼈대 그리기
    img.Color boneColor = img.ColorRgba8(255, 255, 255, 255);
    img.Color jointColor = img.ColorRgba8(255, 255, 255, 255);
    int boneThickness = (2.0 * scale).toInt();
    int jointRadius = (4.0 * scale).toInt();

    void drawLine(PoseLandmarkType t1, PoseLandmarkType t2) {
      final o1 = task.landmarks[t1];
      final o2 = task.landmarks[t2];
      if (o1 != null && o2 != null) {
        img.drawLine(image, x1: o1.dx.toInt(), y1: o1.dy.toInt(), x2: o2.dx.toInt(), y2: o2.dy.toInt(), color: boneColor, thickness: boneThickness);
      }
    }
    void drawPoint(PoseLandmarkType t) {
      final o = task.landmarks[t];
      if (o != null) {
        img.fillCircle(image, x: o.dx.toInt(), y: o.dy.toInt(), radius: jointRadius, color: jointColor);
      }
    }

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

    // 4. 기준선
    if (batchData.referenceMode != 'NONE') {
      img.Color guideColor = img.ColorRgba8(255, 255, 255, 255);
      img.Color shadowColor = img.ColorRgba8(0, 0, 0, 128);

      batchData.referenceHeights.forEach((type, y) {
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

    // 5. 릴리즈 포인트
    if (batchData.showReleasePoints && batchData.releasePoints.isNotEmpty) {
      for (int k = 0; k < batchData.releasePoints.length; k++) {
        final pointData = batchData.releasePoints[k];
        if (pointData.frameIndex <= task.frameIndex) {
          int cx = pointData.point.dx.toInt();
          int cy = pointData.point.dy.toInt();
          int radius = (6 * scale).toInt();

          img.fillCircle(image, x: cx, y: cy, radius: radius + 2, color: img.ColorRgba8(255, 255, 255, 255));
          img.fillCircle(image, x: cx, y: cy, radius: radius, color: img.ColorRgba8(255, 50, 50, 255));
          img.drawString(image, '${k + 1}', font: img.arial24, x: cx - 6, y: cy - 20, color: img.ColorRgba8(255, 255, 255, 255));
        }
      }
    }

    // 결과 저장 (품질 80)
    results[task.frameIndex] = img.encodeJpg(image, quality: 80);
  }

  return BatchResult(results);
}

List<Offset> _applySmoothingStatic(List<Offset> points, {int windowSize = 4}) {
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