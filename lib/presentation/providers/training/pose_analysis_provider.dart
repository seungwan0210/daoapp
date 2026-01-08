import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:gal/gal.dart';

// ✅ 릴리즈 정보를 담을 클래스 (좌표 + 각도 텍스트)
class ReleasePointInfo {
  final Offset point;
  final String angleText; // 예: "158°"
  ReleasePointInfo(this.point, this.angleText);
}

const Map<String, PoseLandmarkType> trackingPartsMap = {
  '오른손 투구 (검지)': PoseLandmarkType.rightIndex,
  '왼손 투구 (검지)': PoseLandmarkType.leftIndex,
};

class PoseAnalysisState {
  final bool isAnalyzing;
  final String? videoPath;
  final Map<int, List<Pose>>? analysisResults;
  final String statusMessage;
  final Size? videoSize;

  final bool showPose;
  final Color poseColor;
  final bool isTracking;
  final Color trackingColor;
  final PoseLandmarkType trackingPart;

  // ✅ [수정] 시간별 트래킹 데이터 (시간: 좌표) -> 그려지는 효과를 위해 필요
  final Map<int, Offset> timeBasedPath;
  // ✅ [수정] 릴리즈 정보 (좌표 + 각도)
  final List<ReleasePointInfo> releasePoints;

  PoseAnalysisState({
    this.isAnalyzing = false,
    this.videoPath,
    this.analysisResults,
    this.statusMessage = "",
    this.videoSize,
    this.showPose = true,
    this.poseColor = Colors.white,
    this.isTracking = true,
    this.trackingColor = const Color(0xFFFFEB3B),
    this.trackingPart = PoseLandmarkType.rightIndex,
    this.timeBasedPath = const {},
    this.releasePoints = const [],
  });

  PoseAnalysisState copyWith({
    bool? isAnalyzing,
    String? videoPath,
    Map<int, List<Pose>>? analysisResults,
    String? statusMessage,
    Size? videoSize,
    bool? showPose,
    Color? poseColor,
    bool? isTracking,
    Color? trackingColor,
    PoseLandmarkType? trackingPart,
    Map<int, Offset>? timeBasedPath,
    List<ReleasePointInfo>? releasePoints,
  }) {
    return PoseAnalysisState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      videoPath: videoPath ?? this.videoPath,
      analysisResults: analysisResults ?? this.analysisResults,
      statusMessage: statusMessage ?? this.statusMessage,
      videoSize: videoSize ?? this.videoSize,
      showPose: showPose ?? this.showPose,
      poseColor: poseColor ?? this.poseColor,
      isTracking: isTracking ?? this.isTracking,
      trackingColor: trackingColor ?? this.trackingColor,
      trackingPart: trackingPart ?? this.trackingPart,
      timeBasedPath: timeBasedPath ?? this.timeBasedPath,
      releasePoints: releasePoints ?? this.releasePoints,
    );
  }
}

class PoseAnalysisNotifier extends StateNotifier<PoseAnalysisState> {
  PoseAnalysisNotifier() : super(PoseAnalysisState());

  final ImagePicker _picker = ImagePicker();
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions(mode: PoseDetectionMode.stream));

  void setPoseColor(Color color) => state = state.copyWith(poseColor: color);
  void setTrackingColor(Color color) => state = state.copyWith(trackingColor: color);

  void setTrackingPart(PoseLandmarkType part) {
    state = state.copyWith(trackingPart: part);
    _calculatePathAndReleases(); // 부위 바뀌면 재계산
  }

  void reset() {
    state = PoseAnalysisState();
  }

  // 📐 [수정] 3점 사이의 각도 계산 함수 (어깨-팔꿈치-손목)
  double _calculateAngle(PoseLandmark first, PoseLandmark middle, PoseLandmark last) {
    double radians = atan2(last.y - middle.y, last.x - middle.x) -
        atan2(first.y - middle.y, first.x - middle.x);
    double angle = (radians * 180.0 / pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  // 🧠 [핵심] 경로 생성 및 릴리즈 포인트(각도+몸통고정) 계산
  void _calculatePathAndReleases() {
    if (state.analysisResults == null) return;

    Map<int, Offset> pathMap = {};
    List<ReleasePointInfo> detectedReleases = [];

    final sortedKeys = state.analysisResults!.keys.toList()..sort();

    // 이전 프레임 데이터 저장용
    Offset? prevHip;
    double? prevElbowAngle;
    int cooldownFrames = 0;

    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final poses = state.analysisResults![key];

      if (poses != null && poses.isNotEmpty) {
        final pose = poses.first;
        final targetLandmark = pose.landmarks[state.trackingPart];

        // 1. 트래킹 경로 저장
        if (targetLandmark != null && targetLandmark.likelihood > 0.6) {
          pathMap[key] = Offset(targetLandmark.x, targetLandmark.y);
        }

        // 2. 릴리즈 감지 로직 (오른손 기준 예시)
        // 오른손이면: 우어깨-우팔꿈치-우손목, 왼손이면 좌측
        final isRight = state.trackingPart == PoseLandmarkType.rightIndex;
        final shoulder = pose.landmarks[isRight ? PoseLandmarkType.rightShoulder : PoseLandmarkType.leftShoulder];
        final elbow = pose.landmarks[isRight ? PoseLandmarkType.rightElbow : PoseLandmarkType.leftElbow];
        final wrist = pose.landmarks[isRight ? PoseLandmarkType.rightWrist : PoseLandmarkType.leftWrist];
        final hip = pose.landmarks[isRight ? PoseLandmarkType.rightHip : PoseLandmarkType.leftHip];

        if (shoulder != null && elbow != null && wrist != null && hip != null) {
          double currentAngle = _calculateAngle(shoulder, elbow, wrist);
          Offset currentHip = Offset(hip.x, hip.y);

          // (A) 몸통 고정 체크 (걷는 중인지 확인)
          // 이전 힙 위치와 비교해서 5픽셀 이상 움직였으면 "걷는 중"으로 간주 -> 감지 스킵
          bool isWalking = false;
          if (prevHip != null) {
            double hipSpeed = (currentHip - prevHip).distance;
            if (hipSpeed > 5.0) isWalking = true; // 임계값 조절 가능
          }

          // (B) 릴리즈 조건 확인
          // 쿨타임 없음 + 걷지 않음 + 팔이 펴지는 중 + 각도가 130도 이상
          if (cooldownFrames == 0 && !isWalking && prevElbowAngle != null) {
            bool isExtending = currentAngle > prevElbowAngle!; // 팔이 펴지는 중

            // 🚀 조건 만족 시 릴리즈 포인트 등록
            if (isExtending && currentAngle > 130 && currentAngle < 175) {
              // 손 속도 체크 (너무 느리면 무시)
              // 여기서는 간단히 각도 변화와 힙 고정만으로도 충분할 수 있음

              // 감지됨!
              detectedReleases.add(ReleasePointInfo(
                  Offset(targetLandmark!.x, targetLandmark.y),
                  "${currentAngle.toStringAsFixed(0)}°" // 각도 텍스트
              ));
              cooldownFrames = 20; // 약 0.7초 쿨타임
            }
          }

          if (cooldownFrames > 0) cooldownFrames--;
          prevElbowAngle = currentAngle;
          prevHip = currentHip;
        }
      }
    }

    state = state.copyWith(
      timeBasedPath: pathMap,
      releasePoints: detectedReleases,
    );
  }

  Future<void> pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        state = state.copyWith(
            videoPath: video.path,
            analysisResults: null,
            timeBasedPath: {},
            releasePoints: [],
            statusMessage: "영상이 선택되었습니다."
        );
      }
    } catch (e) {
      state = state.copyWith(statusMessage: "영상 선택 실패: $e");
    }
  }

  Future<void> analyzeVideo() async {
    if (state.videoPath == null) return;
    state = state.copyWith(isAnalyzing: true, statusMessage: "30프레임 정밀 분석 중...");

    final tempDir = await getTemporaryDirectory();
    final String framesDir = '${tempDir.path}/frames_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(framesDir).create();

    // 30 FPS
    String command = '-i "${state.videoPath}" -vf fps=30 -q:v 2 "$framesDir/frame_%04d.jpg"';

    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        await _processFrames(framesDir);
      } else {
        state = state.copyWith(isAnalyzing: false, statusMessage: "분석 실패");
      }
    });
  }

  Future<void> _processFrames(String framesDir) async {
    final dir = Directory(framesDir);
    final List<FileSystemEntity> files = dir.listSync()
      ..sort((a, b) => a.path.compareTo(b.path));

    Map<int, List<Pose>> results = {};
    int frameIndex = 0;
    int intervalMs = 33; // 33ms 간격
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
          results[frameIndex * intervalMs] = poses;
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

    _calculatePathAndReleases();
  }

  Future<void> saveResultVideo() async {
    if (state.videoPath == null) return;
    try {
      await Gal.putVideo(state.videoPath!);
      state = state.copyWith(statusMessage: "갤러리에 저장되었습니다!");
    } catch (e) {
      state = state.copyWith(statusMessage: "저장 실패: $e");
    }
  }

  @override
  void dispose() {
    _poseDetector.close();
    super.dispose();
  }
}

final poseAnalysisProvider = StateNotifierProvider<PoseAnalysisNotifier, PoseAnalysisState>((ref) {
  return PoseAnalysisNotifier();
});