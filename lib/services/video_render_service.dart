import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img; // 이미지 처리 패키지

class VideoRenderService {

  // 🚀 메인 함수: 영상을 합성하여 저장 경로 반환
  Future<String?> renderExportVideo({
    required String originalVideoPath,
    required Map<int, List<Pose>> analysisResults,
    required Map<PoseLandmarkType, Color> activeTracks,
    required Function(double) onProgress, // 진행률 콜백 (0.0 ~ 1.0)
  }) async {
    final tempDir = await getTemporaryDirectory();
    final String rawFramesDir = '${tempDir.path}/raw_frames_${DateTime.now().millisecondsSinceEpoch}';
    final String processedFramesDir = '${tempDir.path}/proc_frames_${DateTime.now().millisecondsSinceEpoch}';
    final String outputVideoPath = '${tempDir.path}/output_${DateTime.now().millisecondsSinceEpoch}.mp4';

    await Directory(rawFramesDir).create();
    await Directory(processedFramesDir).create();

    try {
      // 1️⃣ [추출] 원본 영상을 프레임(이미지)으로 분해 (30fps 고정)
      // -q:v 9: 약간 압축된 화질 (속도 향상 및 용량 최적화)
      String extractCmd = '-i "$originalVideoPath" -vf fps=30 -q:v 9 "$rawFramesDir/frame_%04d.jpg"';
      await FFmpegKit.execute(extractCmd);

      final List<FileSystemEntity> frameFiles = Directory(rawFramesDir).listSync()
        ..sort((a, b) => a.path.compareTo(b.path));

      int totalFrames = frameFiles.length;

      // 트래킹 경로 누적을 위한 변수
      Map<PoseLandmarkType, List<Offset>> accumulatedPaths = {};
      for (var key in activeTracks.keys) {
        accumulatedPaths[key] = [];
      }

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
          );

          // 처리된 이미지 저장 (quality 80: 속도/화질 균형)
          String outPath = '$processedFramesDir/frame_${i.toString().padLeft(4, '0')}.jpg';
          await File(outPath).writeAsBytes(img.encodeJpg(originalImage, quality: 80));
        }

        // 진행률 업데이트 (0.0 ~ 0.8)
        onProgress((i / totalFrames) * 0.8);
      }

      // 2️⃣ [합성] 이미지들을 다시 동영상으로 변환
      // -preset ultrafast: 인코딩 속도 최우선
      // -crf 28: 화질을 살짝 낮춰 속도 확보
      String encodeCmd = '-framerate 30 -i "$processedFramesDir/frame_%04d.jpg" -c:v libx264 -preset ultrafast -crf 28 -pix_fmt yuv420p "$outputVideoPath"';

      await FFmpegKit.execute(encodeCmd).then((session) async {
        final returnCode = await session.getReturnCode();
        if (!ReturnCode.isSuccess(returnCode)) {
          throw Exception("FFmpeg Encoding Failed");
        }
      });

      onProgress(1.0); // 완료
      return outputVideoPath;

    } catch (e) {
      debugPrint("렌더링 오류: $e");
      return null;
    } finally {
      // 3️⃣ [청소] 임시 파일 삭제
      if (await Directory(rawFramesDir).exists()) await Directory(rawFramesDir).delete(recursive: true);
      if (await Directory(processedFramesDir).exists()) await Directory(processedFramesDir).delete(recursive: true);
    }
  }

  // 🖌️ 이미지 위에 점과 선을 그리는 로직
  void _drawSkeletonAndTracks({
    required img.Image image,
    required int frameIndex,
    required Map<int, List<Pose>> analysisResults,
    required Map<PoseLandmarkType, Color> activeTracks,
    required Map<PoseLandmarkType, List<Offset>> accumulatedPaths,
  }) {
    if (!analysisResults.containsKey(frameIndex)) return;

    final List<Pose> poses = analysisResults[frameIndex]!;
    if (poses.isEmpty) return;

    final pose = poses.first;

    // 🔥 [핵심] 해상도 대응 스케일 계산
    // 기준을 720p로 잡고, 원본 영상이 클수록 스케일도 커짐 (선 두께 자동 조절)
    double baseWidth = 720.0;
    double scale = image.width / baseWidth;
    if (scale < 1.0) scale = 1.0;

    // (A) 트래킹 라인 그리기
    activeTracks.forEach((partType, color) {
      final landmark = pose.landmarks[partType];
      if (landmark != null && landmark.likelihood > 0.6) {
        accumulatedPaths[partType]!.add(Offset(landmark.x, landmark.y));
      }

      List<Offset> rawPath = accumulatedPaths[partType]!;
      // ✅ [지터링 보정] 저장 영상에도 부드러운 선 적용
      List<Offset> path = _applySmoothing(rawPath, windowSize: 4);

      if (path.length > 1) {
        img.Color drawColor = _convertColor(color);

        // ✅ [스케일 적용] 선 두께 키우기 (기본 6)
        int thickness = (6 * scale).toInt();

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

    // (B) 뼈대 그리기
    img.Color boneColor = img.ColorRgba8(255, 255, 255, 255);
    img.Color jointColor = img.ColorRgba8(255, 255, 255, 255);

    // ✅ [스케일 적용] 뼈대와 점 크기 키우기
    int boneThickness = (3 * scale).toInt();
    int jointRadius = (5 * scale).toInt();

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

    // 몸통 연결
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);

    // 팔 연결
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

    // 다리 연결
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    drawLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    drawLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    drawLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);

    // 관절 점 찍기
    for (var type in [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle,
    ]) {
      drawPoint(type);
    }
  }

  // ✅ [지터링 필터] 선을 부드럽게 만드는 함수
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

  // Flutter Color -> img 패키지 Color 변환
  img.Color _convertColor(Color c) {
    return img.ColorRgba8(c.red, c.green, c.blue, 255);
  }
}