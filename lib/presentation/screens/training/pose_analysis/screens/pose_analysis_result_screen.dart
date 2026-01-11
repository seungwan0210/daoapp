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

  // ✅ UI 상태 관리
  bool _showTrackingLines = true;
  String _referenceMode = 'NONE'; // NONE, LEFT, RIGHT

  // 부위별 고정 색상 (Painter에게 전달해서 라벨 색상으로 사용)
  final Map<PoseLandmarkType, Color> _partColors = {
    PoseLandmarkType.rightWrist: const Color(0xFFFFEB3B), // 노랑
    PoseLandmarkType.rightElbow: const Color(0xFF2979FF), // 파랑
    PoseLandmarkType.leftWrist: const Color(0xFF00E676),  // 초록
    PoseLandmarkType.leftElbow: const Color(0xFFFF4081),  // 핑크
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

  // ✅ [핵심] 트래킹이 꺼져 있어도, 기준선 계산을 위한 데이터는 확보해야 함
  Map<PoseLandmarkType, List<Offset>> _getCurrentMultiPaths(
      Map<int, List<Pose>>? analysisResults,
      Map<PoseLandmarkType, Color> activeTracks // 사용자가 "보고 싶어서 켠" 트래킹
      ) {
    if (analysisResults == null || _videoController == null) return {};

    double currentSeconds = _videoController!.value.position.inMicroseconds / 1000000.0;
    int currentFrameIndex = (currentSeconds * 30).round();

    Map<PoseLandmarkType, List<Offset>> multiPaths = {};
    final sortedKeys = analysisResults.keys.toList()..sort();

    // 1. 계산할 부위 목록 만들기 (사용자 선택 + 기준선 모드 필수 부위)
    Set<PoseLandmarkType> targetsToCalculate = {};

    // (A) 사용자가 칩으로 켠 부위 (화면에 트래킹 선을 그리기 위함)
    targetsToCalculate.addAll(activeTracks.keys);

    // (B) 기준선 모드에 필요한 부위 (트래킹은 안 보여도 기준선 계산용 데이터는 필요함)
    if (_referenceMode == 'RIGHT') {
      targetsToCalculate.add(PoseLandmarkType.rightWrist);
      targetsToCalculate.add(PoseLandmarkType.rightElbow);
    } else if (_referenceMode == 'LEFT') {
      targetsToCalculate.add(PoseLandmarkType.leftWrist);
      targetsToCalculate.add(PoseLandmarkType.leftElbow);
    }

    // 2. 데이터 계산
    for (var part in targetsToCalculate) {
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
      multiPaths[part] = applySmoothing(rawPath, windowSize: 4);
    }
    return multiPaths;
  }

  // ✅ [수정] 트래킹을 강제로 켜지 않고, 모드만 변경
  void _setReferenceMode(String mode) {
    setState(() {
      _referenceMode = mode;
    });
  }

  void _handleSaveVideo() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RenderingProgressDialog(mode: _referenceMode), // ✅ 모드 전달
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
                if (_videoController != null && state.analysisResults != null)
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: CustomPaint(
                      painter: PosePainter(
                        _getCurrentPoses(state.analysisResults),
                        state.videoSize ?? const Size(1080, 1920),
                        poseColor: state.poseColor,
                        // 모든 필요한 데이터(기준선용 포함) 전달
                        multiPaths: _getCurrentMultiPaths(state.analysisResults, state.activeTracks),
                        // 사용자가 "진짜 켠" 트래킹 색상만 전달 (이것만 트래킹 선으로 그려짐)
                        activeTrackColors: state.activeTracks,
                        // 기본 색상표 전달 (기준선 라벨용)
                        allPartColors: _partColors,
                        showTrackingLines: _showTrackingLines,
                        referenceMode: _referenceMode,
                      ),
                    ),
                  ),
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
                          const Text("기준선 가이드 (팔꿈치/손목)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildModeButton("끄기", "NONE", Colors.grey),
                              const SizedBox(width: 8),
                              _buildModeButton("왼쪽 켜기", "LEFT", Colors.cyan),
                              const SizedBox(width: 8),
                              _buildModeButton("오른쪽 켜기", "RIGHT", Colors.cyan),
                            ],
                          ),

                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("트래킹 궤적 보기", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  SizedBox(height: 4),
                                  Text("투구 궤적이 궁금하다면 켜보세요", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              Switch(
                                value: _showTrackingLines,
                                activeColor: Colors.cyan,
                                onChanged: (val) {
                                  setState(() => _showTrackingLines = val);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // 트래킹 상세 선택 (마스터 토글이 켜져야 보임)
                          if (_showTrackingLines) ...[
                            const SizedBox(height: 8),
                            const Text("보고 싶은 부위 선택", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: trackingPartsMap.entries.map((entry) {
                                final isSelected = state.activeTracks.containsKey(entry.value);
                                return ChoiceChip(
                                  label: Text(entry.key, style: const TextStyle(fontSize: 12)),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    Color color = _partColors[entry.value] ?? Colors.yellow;
                                    notifier.toggleTrack(entry.value, color);
                                  },
                                  selectedColor: Colors.cyan[100],
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.cyan[800] : Colors.grey[700],
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  backgroundColor: Colors.grey[100],
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(color: isSelected ? Colors.cyan : Colors.grey[300]!)
                                  ),
                                );
                              }).toList(),
                            ),
                          ],

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 하단 버튼
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
                      onPressed: _handleSaveVideo,
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

  Widget _buildModeButton(String label, String mode, Color color) {
    final isSelected = _referenceMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setReferenceMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? Colors.transparent : Colors.grey[300]!),
          ),
          child: Center(
            child: Text(
                label,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 13
                )
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ 저장 다이얼로그 (모드 전달받음)
class _RenderingProgressDialog extends ConsumerStatefulWidget {
  final String mode; // ✅ 추가: 기준선 모드 전달
  const _RenderingProgressDialog({required this.mode});

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
    // ✅ 전달받은 mode를 Provider 함수에 함께 넘김
    ref.read(poseAnalysisProvider.notifier).saveRenderedVideo(widget.mode, (progress) {
      if (mounted) {
        setState(() {
          _progress = progress;
          if (progress < 0.2) _status = "프레임 추출 중...";
          else if (progress < 0.8) _status = "AI 뼈대 그리는 중... (오래 걸려요)";
          else if (progress < 1.0) _status = "영상 인코딩 중...";
          else _status = "저장 완료!";
        });
        if (progress >= 1.0) {
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("갤러리에 저장되었습니다!")));
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("영상 생성 중...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            // 광고 영역 (예시)
            Container(height: 200, width: double.infinity, color: Colors.grey[100], child: const Center(child: Icon(Icons.ad_units, color: Colors.grey))),
            const SizedBox(height: 20),
            Stack(alignment: Alignment.center, children: [
              SizedBox(width: 60, height: 60, child: CircularProgressIndicator(value: _progress, strokeWidth: 5, color: Colors.cyan)),
              Text("${(_progress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Text(_status, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}