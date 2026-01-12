import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui; // Size 사용을 위해 추가
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:gal/gal.dart';

// ✅ 영상 렌더링 서비스 import
import 'package:daoapp/services/video_render_service.dart';

// 추적 부위 옵션
const Map<String, PoseLandmarkType> trackingPartsMap = {
  '오른손목': PoseLandmarkType.rightWrist,
  '왼손목': PoseLandmarkType.leftWrist,
  '오른쪽 팔꿈치': PoseLandmarkType.rightElbow,
  '왼쪽 팔꿈치': PoseLandmarkType.leftElbow,
  '오른쪽 어깨': PoseLandmarkType.rightShoulder,
  '왼쪽 어깨': PoseLandmarkType.leftShoulder,
};

class PoseAnalysisState {
  final bool isAnalyzing;
  final String? videoPath;
  final Map<int, List<Pose>>? analysisResults;
  final String statusMessage;
  final Size? videoSize;

  final Color poseColor;

  final Map<PoseLandmarkType, Color> activeTracks;

  PoseAnalysisState({
    this.isAnalyzing = false,
    this.videoPath,
    this.analysisResults,
    this.statusMessage = "",
    this.videoSize,
    this.poseColor = Colors.white,
    this.activeTracks = const {},
  });

  PoseAnalysisState copyWith({
    bool? isAnalyzing,
    String? videoPath,
    Map<int, List<Pose>>? analysisResults,
    String? statusMessage,
    Size? videoSize,
    Color? poseColor,
    Map<PoseLandmarkType, Color>? activeTracks,
  }) {
    return PoseAnalysisState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      videoPath: videoPath ?? this.videoPath,
      analysisResults: analysisResults ?? this.analysisResults,
      statusMessage: statusMessage ?? this.statusMessage,
      videoSize: videoSize ?? this.videoSize,
      poseColor: poseColor ?? this.poseColor,
      activeTracks: activeTracks ?? this.activeTracks,
    );
  }
}

class PoseAnalysisNotifier extends StateNotifier<PoseAnalysisState> {
  PoseAnalysisNotifier() : super(PoseAnalysisState());

  final ImagePicker _picker = ImagePicker();
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions(mode: PoseDetectionMode.stream));

  // ✅ 렌더링 서비스 인스턴스
  final VideoRenderService _renderService = VideoRenderService();

  void setPoseColor(Color color) => state = state.copyWith(poseColor: color);

  void toggleTrack(PoseLandmarkType part, Color color) {
    final newTracks = Map<PoseLandmarkType, Color>.from(state.activeTracks);
    if (newTracks.containsKey(part)) {
      newTracks.remove(part);
    } else {
      newTracks[part] = color;
    }
    state = state.copyWith(activeTracks: newTracks);
  }

  void setSingleTrack(PoseLandmarkType part, Color color) {
    state = state.copyWith(activeTracks: {part: color});
  }

  void reset() {
    state = PoseAnalysisState();
  }

  Future<bool> pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        state = state.copyWith(
          videoPath: video.path,
          analysisResults: null,
          statusMessage: "영상 선택 완료",
          activeTracks: {PoseLandmarkType.rightWrist: const Color(0xFFFFEB3B)},
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(statusMessage: "선택 실패: $e");
    }
    return false;
  }

  Future<bool> analyzeVideo() async {
    if (state.videoPath == null) return false;

    state = state.copyWith(isAnalyzing: true, analysisResults: null, statusMessage: "영상 처리 중...");

    final tempDir = await getTemporaryDirectory();
    final String framesDir = '${tempDir.path}/frames_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(framesDir).create();

    String command = '-i "${state.videoPath}" -vf fps=30 -q:v 2 "$framesDir/frame_%04d.jpg"';

    bool success = false;
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        await _processFrames(framesDir);
        success = true;
      } else {
        state = state.copyWith(isAnalyzing: false, statusMessage: "영상 처리 실패");
      }
    });
    return success;
  }

  Future<void> _processFrames(String framesDir) async {
    final dir = Directory(framesDir);
    final List<FileSystemEntity> files = dir.listSync()
      ..sort((a, b) => a.path.compareTo(b.path));

    Map<int, List<Pose>> results = {};
    int frameIndex = 0;
    Size? detectedSize;

    for (var file in files) {
      if (file is File && file.path.endsWith('.jpg')) {
        final inputImage = InputImage.fromFile(file);

        if (detectedSize == null) {
          final decodedImage = await decodeImageFromList(file.readAsBytesSync());
          detectedSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
        }

        final List<Pose> poses = await _poseDetector.processImage(inputImage);
        if (poses.isNotEmpty) {
          results[frameIndex] = poses;
        }
        frameIndex++;
      }
    }

    state = state.copyWith(
      isAnalyzing: false,
      analysisResults: results,
      videoSize: detectedSize,
      statusMessage: "분석 완료!",
    );
  }

  // ✅ [수정] 합성된 영상 저장 (렌더링 실행)
  // referenceMode: 기준선 모드
  // showTrackingLines, showReleasePoints: 토글 상태 추가
  Future<void> saveRenderedVideo(
      String referenceMode,
      bool showTrackingLines, // 추가됨
      bool showReleasePoints, // 추가됨
      Function(double) onProgress
      ) async {
    if (state.videoPath == null || state.analysisResults == null) return;

    try {
      // 1. 렌더링 서비스 호출 (토글 상태 전달)
      final String? outputPath = await _renderService.renderExportVideo(
        originalVideoPath: state.videoPath!,
        analysisResults: state.analysisResults!,
        activeTracks: state.activeTracks,
        referenceMode: referenceMode,
        // ✅ 토글 전달
        showTrackingLines: showTrackingLines,
        showReleasePoints: showReleasePoints,
        onProgress: onProgress,
      );

      // 2. 갤러리 저장
      if (outputPath != null) {
        await Gal.putVideo(outputPath);
        state = state.copyWith(statusMessage: "분석 영상이 갤러리에 저장되었습니다! 🎉");
      } else {
        state = state.copyWith(statusMessage: "영상 생성에 실패했습니다.");
      }
    } catch (e) {
      state = state.copyWith(statusMessage: "저장 오류: $e");
    }
  }
}

// 지터링 방지 필터
List<Offset> applySmoothing(List<Offset> points, {int windowSize = 4}) {
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

final poseAnalysisProvider = StateNotifierProvider<PoseAnalysisNotifier, PoseAnalysisState>((ref) {
  return PoseAnalysisNotifier();
});