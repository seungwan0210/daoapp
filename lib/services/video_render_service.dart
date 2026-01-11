import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class VideoRenderService {

  // 🚀 메인 함수
  Future<String?> renderExportVideo({
    required String originalVideoPath,
    required Map<int, List<Pose>> analysisResults,
    required Map<PoseLandmarkType, Color> activeTracks,
    required String referenceMode, // ✅ [NEW] 기준선 모드 (NONE, LEFT, RIGHT)
    required Function(double) onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final String rawFramesDir = '${tempDir.path}/raw_frames_${DateTime.now().millisecondsSinceEpoch}';
    final String processedFramesDir = '${tempDir.path}/proc_frames_${DateTime.now().millisecondsSinceEpoch}';
    final String outputVideoPath = '${tempDir.path}/output_${DateTime.now().millisecondsSinceEpoch}.mp4';

    await Directory(rawFramesDir).create();
    await Directory(processedFramesDir).create();

    try {
      // 1️⃣ [전처리] 기준선 높이 미리 계산 (전체 데이터 스캔)
      Map<PoseLandmarkType, double> referenceHeights = _calculateReferenceHeights(analysisResults, referenceMode);

      // 2️⃣ [추출] 프레임 추출
      // -q:v 9: 속도와 용량 최적화
      String extractCmd = '-i "$originalVideoPath" -vf fps=30 -q:v 9 "$rawFramesDir/frame_%04d.jpg"';
      await FFmpegKit.execute(extractCmd);

      final List<FileSystemEntity> frameFiles = Directory(rawFramesDir).listSync()
        ..sort((a, b) => a.path.compareTo(b.path));

      int totalFrames = frameFiles.length;

      // 트래킹 경로 누적 변수
      Map<PoseLandmarkType, List<Offset>> accumulatedPaths = {};
      for (var key in activeTracks.keys) {
        accumulatedPaths[key] = [];
      }

      // 3️⃣ [그리기] 프레임별 합성 루프
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
            referenceHeights: referenceHeights, // ✅ 기준선 높이 전달
            referenceMode: referenceMode,       // ✅ 모드 전달
          );

          // 저장
          String outPath = '$processedFramesDir/frame_${i.toString().padLeft(4, '0')}.jpg';
          await File(outPath).writeAsBytes(img.encodeJpg(originalImage, quality: 80));
        }

        onProgress((i / totalFrames) * 0.8);
      }

      // 4️⃣ [인코딩] 영상 생성
      String encodeCmd = '-framerate 30 -i "$processedFramesDir/frame_%04d.jpg" -c:v libx264 -preset ultrafast -crf 28 -pix_fmt yuv420p "$outputVideoPath"';

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

  // 🧠 [로직] 전체 프레임을 훑어서 "셋업 높이"를 미리 계산하는 함수
  Map<PoseLandmarkType, double> _calculateReferenceHeights(
      Map<int, List<Pose>> analysisResults, String mode) {

    Map<PoseLandmarkType, double> heights = {};
    if (mode == 'NONE') return heights;

    // 계산할 부위 목록
    List<PoseLandmarkType> targets = [];
    if (mode == 'RIGHT') {
      targets = [PoseLandmarkType.rightWrist, PoseLandmarkType.rightElbow];
    } else if (mode == 'LEFT') {
      targets = [PoseLandmarkType.leftWrist, PoseLandmarkType.leftElbow];
    }

    for (var type in targets) {
      List<double> validYs = [];
      // 모든 프레임 순회
      analysisResults.forEach((frameIdx, poses) {
        if (poses.isNotEmpty) {
          final landmark = poses.first.landmarks[type];
          if (landmark != null && landmark.likelihood > 0.6 && landmark.y > 0) {
            validYs.add(landmark.y);
          }
        }
      });

      if (validYs.isNotEmpty) {
        validYs.sort(); // 높이순 정렬 (작은 값 = 위쪽)
        // 상위 30% (팔을 든 상태) 추출
        int topRangeCount = (validYs.length * 0.3).ceil();
        if (topRangeCount == 0) topRangeCount = validYs.length;

        List<double> aimingCandidates = validYs.sublist(0, topRangeCount);
        // 중앙값 저장
        heights[type] = aimingCandidates[(aimingCandidates.length / 2).floor()];
      }
    }
    return heights;
  }

  // 🖌️ 그리기 로직 (기준선 추가됨)
  void _drawSkeletonAndTracks({
    required img.Image image,
    required int frameIndex,
    required Map<int, List<Pose>> analysisResults,
    required Map<PoseLandmarkType, Color> activeTracks,
    required Map<PoseLandmarkType, List<Offset>> accumulatedPaths,
    required Map<PoseLandmarkType, double> referenceHeights,
    required String referenceMode,
  }) {
    if (!analysisResults.containsKey(frameIndex)) return;
    final List<Pose> poses = analysisResults[frameIndex]!;
    if (poses.isEmpty) return;
    final pose = poses.first;

    // 🔥 스케일 계산 (두께 조절용)
    double baseWidth = 720.0;
    double scale = image.width / baseWidth;
    if (scale < 1.0) scale = 1.0;

    // 1️⃣ 트래킹 라인 그리기 (activeTracks에 있는 것만)
    activeTracks.forEach((partType, color) {
      final landmark = pose.landmarks[partType];
      if (landmark != null && landmark.likelihood > 0.6) {
        accumulatedPaths[partType]!.add(Offset(landmark.x, landmark.y));
      }

      List<Offset> rawPath = accumulatedPaths[partType]!;
      List<Offset> path = _applySmoothing(rawPath, windowSize: 4);

      if (path.length > 1) {
        img.Color drawColor = _convertColor(color);
        // ✅ [수정] 두께를 살짝 줄임 (6 -> 4.5)
        int thickness = (4.5 * scale).toInt();

        for (int k = 0; k < path.length - 1; k++) {
          img.drawLine(
              image,
              x1: path[k].dx.toInt(), y1: path[k].dy.toInt(),
              x2: path[k+1].dx.toInt(), y2: path[k+1].dy.toInt(),
              color: drawColor,
              thickness: thickness
          );
        }
      }
    });

    // 2️⃣ 뼈대 그리기
    img.Color boneColor = img.ColorRgba8(255, 255, 255, 255);
    img.Color jointColor = img.ColorRgba8(255, 255, 255, 255);

    // ✅ [수정] 뼈대 두께도 살짝 줄임 (3 -> 2)
    int boneThickness = (2.0 * scale).toInt();
    int jointRadius = (4.0 * scale).toInt(); // (5 -> 4)

    void drawLine(PoseLandmarkType t1, PoseLandmarkType t2) {
      final l1 = pose.landmarks[t1];
      final l2 = pose.landmarks[t2];
      if (l1 != null && l2 != null && l1.likelihood > 0.5 && l2.likelihood > 0.5) {
        img.drawLine(image,
            x1: l1.x.toInt(), y1: l1.y.toInt(),
            x2: l2.x.toInt(), y2: l2.y.toInt(),
            color: boneColor,
            thickness: boneThickness
        );
      }
    }

    void drawPoint(PoseLandmarkType t) {
      final l = pose.landmarks[t];
      if (l != null && l.likelihood > 0.5) {
        img.fillCircle(image,
            x: l.x.toInt(), y: l.y.toInt(),
            radius: jointRadius,
            color: jointColor
        );
      }
    }

    // 몸통/팔 연결 (손가락 제외, 손목까지만)
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);

    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

    // 주요 관절만 점 찍기
    for (var type in [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
    ]) {
      drawPoint(type);
    }

    // 3️⃣ [NEW] 기준선(가이드) 그리기
    if (referenceMode != 'NONE') {
      img.Color guideColor = img.ColorRgba8(255, 255, 255, 255); // 흰색
      img.Color shadowColor = img.ColorRgba8(0, 0, 0, 128);      // 반투명 검정

      referenceHeights.forEach((type, y) {
        // y 좌표는 원본 해상도 기준이므로 바로 사용 가능
        int lineY = y.toInt();
        int lineThickness = (1.5 * scale).toInt();
        if (lineThickness < 1) lineThickness = 1;

        // 점선 그리기 (직접 구현)
        int dashWidth = (15 * scale).toInt(); // 점선 길이
        int dashSpace = (8 * scale).toInt();  // 빈 공간

        for (int x = 0; x < image.width; x += dashWidth + dashSpace) {
          int endX = x + dashWidth;
          if (endX > image.width) endX = image.width;

          // 그림자 먼저 (y+1)
          img.drawLine(image, x1: x, y1: lineY + 1, x2: endX, y2: lineY + 1, color: shadowColor, thickness: lineThickness + 1);
          // 흰색 선
          img.drawLine(image, x1: x, y1: lineY, x2: endX, y2: lineY, color: guideColor, thickness: lineThickness);
        }
      });
    }
  }

  List<Offset> _applySmoothing(List<Offset> points, {int windowSize = 4}) {
    if (points.length < windowSize) return points;
    List<Offset> smoothedPoints = [];
    for (int i = 0; i < points.length; i++) {
      double sumX = 0;
      double sumY = 0;
      int count = 0;
      for (int j = 0; j < windowSize; j++) {
        if (i - j >= 0) {
          sumX += points[i - j].dx;
          sumY += points[i - j].dy;
          count++;
        }
      }
      smoothedPoints.add(Offset(sumX / count, sumY / count));
    }
    return smoothedPoints;
  }

  img.Color _convertColor(Color c) {
    return img.ColorRgba8(c.red, c.green, c.blue, 255);
  }
}