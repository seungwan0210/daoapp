import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:daoapp/presentation/providers/training/pose_analysis_provider.dart';
import 'package:daoapp/presentation/screens/training/pose_analysis/widgets/pose_painter.dart';

class PoseAnalysisScreen extends ConsumerStatefulWidget {
  const PoseAnalysisScreen({super.key});

  @override
  ConsumerState<PoseAnalysisScreen> createState() => _PoseAnalysisScreenState();
}

class _PoseAnalysisScreenState extends ConsumerState<PoseAnalysisScreen> {
  VideoPlayerController? _videoController;

  // 색상 선택 다이얼로그
  void _showColorPicker(BuildContext context, bool isPoseColor, WidgetRef ref) {
    final notifier = ref.read(poseAnalysisProvider.notifier);
    final List<Color> colors = isPoseColor
        ? [Colors.white, Colors.redAccent]
        : [const Color(0xFFFFEB3B), Colors.blueAccent];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPoseColor ? "뼈대 색상" : "트래킹 색상"),
        content: Wrap(
          spacing: 16,
          alignment: WrapAlignment.center,
          children: colors.map((color) => GestureDetector(
            onTap: () {
              if (isPoseColor) {
                notifier.setPoseColor(color);
              } else {
                notifier.setTrackingColor(color);
              }
              Navigator.pop(context);
            },
            child: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 1),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo(String path) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(File(path));
    await _videoController!.initialize();
    _videoController!.addListener(() {
      // 영상이 재생될 때마다 화면을 갱신하여 선이 그려지는 효과를 줌
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  List<Pose> _getCurrentPoses(Map<int, List<Pose>>? analysisResults) {
    if (analysisResults == null || _videoController == null) return [];
    final currentMillis = _videoController!.value.position.inMilliseconds;

    // 30 FPS (약 33ms) 기준 매핑
    final targetKey = (currentMillis / 33).round() * 33;

    if (analysisResults.containsKey(targetKey)) {
      return analysisResults[targetKey]!;
    }
    for (int offset in [-33, 33, -66, 66]) {
      if (analysisResults.containsKey(targetKey + offset)) {
        return analysisResults[targetKey + offset]!;
      }
    }
    return [];
  }

  // ✅ [NEW] 현재 재생 시점까지의 트래킹 경로만 잘라서 반환 (그려지는 효과)
  List<Offset> _getCurrentPath(Map<int, Offset> fullPath) {
    if (_videoController == null) return [];
    final currentMillis = _videoController!.value.position.inMilliseconds;

    // 현재 시간(currentMillis)보다 작거나 같은 시간대의 좌표만 필터링
    final path = fullPath.entries
        .where((entry) => entry.key <= currentMillis)
        .map((entry) => entry.value)
        .toList();

    return path;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(poseAnalysisProvider);
    final notifier = ref.read(poseAnalysisProvider.notifier);

    if (state.videoPath != null && (_videoController == null || _videoController!.dataSource != 'file://${state.videoPath}')) {
      _initializeVideo(state.videoPath!);
    }

    // 1. 로딩 화면
    if (state.isAnalyzing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120, height: 120,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  color: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
                ),
              ),
              const SizedBox(height: 24),
              Text(state.statusMessage, style: const TextStyle(fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: () => notifier.reset(),
                child: const Text("취소"),
              ),
            ],
          ),
        ),
      );
    }

    // 2. 시작 화면
    if (state.videoPath == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("AI 자세 분석", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_esports, size: 80, color: const Color(0xFF7C4DFF).withOpacity(0.8)),
              const SizedBox(height: 20),
              const Text("투구 영상을 선택하세요", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () => notifier.pickVideo(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("영상 선택", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. 메인 화면
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // [상단] 비디오 & 오버레이
            Expanded(
              flex: 4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(color: Colors.black),
                  if (_videoController != null && _videoController!.value.isInitialized)
                    AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  if (_videoController != null && _videoController!.value.isInitialized && state.analysisResults != null)
                    AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: CustomPaint(
                        painter: PosePainter(
                          _getCurrentPoses(state.analysisResults),
                          state.videoSize ?? const Size(1080, 1920),
                          InputImageRotation.rotation0deg,
                          poseColor: state.poseColor,
                          // ✅ [수정] 전체 경로 대신 '현재까지 그려진 경로' 전달
                          trackingPath: _getCurrentPath(state.timeBasedPath),
                          trackingColor: state.trackingColor,
                          // ✅ [수정] 각도 정보가 포함된 릴리즈 포인트 전달
                          releasePoints: state.releasePoints,
                        ),
                      ),
                    ),
                  if (_videoController != null && _videoController!.value.isInitialized)
                    GestureDetector(
                      onTap: () {
                        _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                      },
                      child: _videoController!.value.isPlaying ? const SizedBox.shrink() : Container(
                        color: Colors.black12,
                        child: const Icon(Icons.play_circle_filled, size: 70, color: Colors.white70),
                      ),
                    ),
                ],
              ),
            ),

            // [하단] 컨트롤 패널
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.analysisResults != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => notifier.saveResultVideo(),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text("분석 영상 저장"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const Text("분석 옵션", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.ads_click, color: Color(0xFF7C4DFF)),
                            title: const Text("추적 부위", style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text("손가락 끝을 선택하면 릴리즈 포인트 확인 가능"),
                            trailing: DropdownButton<PoseLandmarkType>(
                              value: state.trackingPart,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.keyboard_arrow_down),
                              onChanged: (value) {
                                if (value != null) notifier.setTrackingPart(value);
                              },
                              items: trackingPartsMap.entries.map((entry) {
                                return DropdownMenuItem(
                                  value: entry.value,
                                  child: Text(entry.key, style: const TextStyle(fontSize: 14)),
                                );
                              }).toList(),
                            ),
                          ),
                          const Divider(height: 1),

                          _buildColorTile(context, "뼈대 색상", state.poseColor, true, ref),
                          const Divider(height: 1),
                          _buildColorTile(context, "트래킹 색상", state.trackingColor, false, ref),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _videoController?.pause();
                              notifier.reset();
                            },
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            child: const Text("종료", style: TextStyle(color: Colors.black87)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (state.analysisResults == null)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => notifier.analyzeVideo(),
                              style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  backgroundColor: const Color(0xFF7C4DFF),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                              child: const Text("분석 시작", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => notifier.pickVideo(),
                        icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
                        label: const Text("다른 영상 선택", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorTile(BuildContext context, String title, Color color, bool isPoseColor, WidgetRef ref) {
    return ListTile(
      leading: Icon(Icons.palette_outlined, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: GestureDetector(
        onTap: () => _showColorPicker(context, isPoseColor, ref),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!),
          ),
        ),
      ),
    );
  }
}