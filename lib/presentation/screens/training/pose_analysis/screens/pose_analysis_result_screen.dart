import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/providers/training/pose_analysis_provider.dart';
import 'package:daoapp/presentation/screens/training/pose_analysis/widgets/pose_painter.dart';
import 'package:daoapp/presentation/screens/training/pose_analysis/screens/pose_analysis_setting_screen.dart';

class PoseAnalysisResultScreen extends ConsumerStatefulWidget {
  const PoseAnalysisResultScreen({super.key});

  @override
  ConsumerState<PoseAnalysisResultScreen> createState() => _PoseAnalysisResultScreenState();
}

class _PoseAnalysisResultScreenState extends ConsumerState<PoseAnalysisResultScreen> {
  VideoPlayerController? _videoController;

  // 부위별 기본 색상 프리셋
  final Map<PoseLandmarkType, Color> _partColors = {
    PoseLandmarkType.rightWrist: const Color(0xFFFFEB3B), // 노랑
    PoseLandmarkType.leftWrist: const Color(0xFF00E676), // 초록
    PoseLandmarkType.rightElbow: const Color(0xFF2979FF), // 파랑
    PoseLandmarkType.leftElbow: const Color(0xFFFF4081), // 핑크
    PoseLandmarkType.rightShoulder: const Color(0xFFE040FB), // 보라
    PoseLandmarkType.leftShoulder: const Color(0xFFFF6D00), // 주황
  };

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _initVideo() async {
    final path = ref.read(poseAnalysisProvider).videoPath;
    if (path != null) {
      _videoController = VideoPlayerController.file(File(path));
      await _videoController!.initialize();
      _videoController!.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() {});
    }
  }

  List<Pose> _getCurrentPoses(Map<int, List<Pose>>? analysisResults) {
    if (analysisResults == null || _videoController == null) return [];
    double currentSeconds = _videoController!.value.position.inMicroseconds / 1000000.0;
    int frameIndex = (currentSeconds * 30).round();
    return analysisResults[frameIndex] ?? [];
  }

  // 다중 경로 추출 + 필터링 적용
  Map<PoseLandmarkType, List<Offset>> _getCurrentMultiPaths(
      Map<int, List<Pose>>? analysisResults,
      Map<PoseLandmarkType, Color> activeTracks
      ) {
    if (analysisResults == null || _videoController == null) return {};

    double currentSeconds = _videoController!.value.position.inMicroseconds / 1000000.0;
    int currentFrameIndex = (currentSeconds * 30).round();

    Map<PoseLandmarkType, List<Offset>> multiPaths = {};
    final sortedKeys = analysisResults.keys.toList()..sort();

    for (var part in activeTracks.keys) {
      List<Offset> rawPath = [];
      for (int key in sortedKeys) {
        if (key > currentFrameIndex) break;

        final poses = analysisResults[key];
        if (poses != null && poses.isNotEmpty) {
          final landmark = poses.first.landmarks[part];
          if (landmark != null && landmark.likelihood > 0.6) {
            rawPath.add(Offset(landmark.x, landmark.y));
          }
        }
      }
      // 지터링 필터 적용 (pose_analysis_provider.dart에 정의됨)
      multiPaths[part] = applySmoothing(rawPath, windowSize: 4);
    }
    return multiPaths;
  }

  // ✅ [NEW] 저장 버튼 클릭 핸들러
  void _handleSaveVideo() {
    showDialog(
      context: context,
      barrierDismissible: false, // 로딩 중 닫기 방지
      builder: (context) {
        return _RenderingProgressDialog(); // 아래 정의된 다이얼로그 위젯 호출
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(poseAnalysisProvider);
    final notifier = ref.read(poseAnalysisProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("분석 결과", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              notifier.reset();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          )
        ],
      ),
      body: Column(
        children: [
          // 1. 영상 플레이어
          Container(
            height: 280,
            width: double.infinity,
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_videoController != null && _videoController!.value.isInitialized)
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                // 오버레이 (다중 트래킹)
                if (_videoController != null && state.analysisResults != null)
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: CustomPaint(
                      painter: PosePainter(
                        _getCurrentPoses(state.analysisResults),
                        state.videoSize ?? const Size(1080, 1920),
                        poseColor: state.poseColor,
                        multiPaths: _getCurrentMultiPaths(state.analysisResults, state.activeTracks),
                        trackColors: state.activeTracks,
                      ),
                    ),
                  ),
                // 재생 버튼
                GestureDetector(
                  onTap: () {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                    setState(() {});
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: _videoController != null && !_videoController!.value.isPlaying
                          ? const Icon(Icons.play_circle_fill, size: 64, color: Colors.white70)
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. 컨트롤 패널
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("트래킹 부위 선택 (다중 선택 가능)",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                              InkWell(
                                onTap: () => notifier.setSingleTrack(PoseLandmarkType.rightWrist, _partColors[PoseLandmarkType.rightWrist]!),
                                child: const Text("초기화", style: TextStyle(fontSize: 12, color: Colors.cyan)),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),

                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: trackingPartsMap.entries.map((entry) {
                              final isSelected = state.activeTracks.containsKey(entry.value);
                              final partColor = _partColors[entry.value] ?? Colors.grey;

                              return ChoiceChip(
                                label: Text(entry.key),
                                labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey[700],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  notifier.toggleTrack(entry.value, partColor);
                                },
                                selectedColor: partColor,
                                backgroundColor: Colors.grey[100],
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!)
                                ),
                                avatar: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),

                          const Text("💡 팁: 여러 부위를 선택하여 움직임을 비교해보세요.",
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. 하단 액션 버튼
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        notifier.reset();
                        final success = await notifier.pickVideo();
                        if (success && context.mounted) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PoseAnalysisSettingScreen()));
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("다른 영상 선택", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleSaveVideo, // ✅ 저장 버튼 연결
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text("영상 저장"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan[600],
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ [NEW] 렌더링 진행률 다이얼로그 위젯
class _RenderingProgressDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RenderingProgressDialog> createState() => _RenderingProgressDialogState();
}

class _RenderingProgressDialogState extends ConsumerState<_RenderingProgressDialog> {
  double _progress = 0.0;
  String _status = "준비 중...";

  @override
  void initState() {
    super.initState();
    _startRendering();
  }

  void _startRendering() {
    // Provider의 렌더링 함수 호출
    ref.read(poseAnalysisProvider.notifier).saveRenderedVideo((progress) {
      if (mounted) {
        setState(() {
          _progress = progress;
          // 진행률에 따른 상태 메시지 업데이트
          if (progress < 0.2) _status = "프레임 추출 중...";
          else if (progress < 0.8) _status = "AI 뼈대 그리는 중... (오래 걸려요)";
          else if (progress < 1.0) _status = "영상 인코딩 중...";
          else _status = "저장 완료!";
        });

        // 100% 완료 시 1초 뒤 닫기
        if (progress >= 1.0) {
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context); // 다이얼로그 닫기
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("갤러리에 저장되었습니다!")),
            );
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 0~100 퍼센트 정수 변환
    final percent = (_progress * 100).toInt();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("영상 만드는 중...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),

            // 🔥 광고 배너 넣기 좋은 자리 (현재는 비워둠)
            // Container(height: 50, width: double.infinity, color: Colors.grey[100], child: const Center(child: Text("광고"))),
            // const SizedBox(height: 20),

            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80, height: 80,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 6,
                    color: Colors.cyan,
                    backgroundColor: Colors.grey[100],
                  ),
                ),
                Text("$percent%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Text(_status, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}