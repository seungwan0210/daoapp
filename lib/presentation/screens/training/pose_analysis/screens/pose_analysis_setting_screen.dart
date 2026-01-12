import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/providers/training/pose_analysis_provider.dart';
import 'package:daoapp/presentation/screens/training/pose_analysis/screens/pose_analysis_process_screen.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseAnalysisSettingScreen extends ConsumerStatefulWidget {
  const PoseAnalysisSettingScreen({super.key});

  @override
  ConsumerState<PoseAnalysisSettingScreen> createState() => _PoseAnalysisSettingScreenState();
}

class _PoseAnalysisSettingScreenState extends ConsumerState<PoseAnalysisSettingScreen> {
  VideoPlayerController? _previewController;

  @override
  void dispose() {
    _previewController?.dispose();
    super.dispose();
  }

  // ✅ 영상 변경 로직
  Future<void> _changeVideo() async {
    _previewController?.pause();
    final notifier = ref.read(poseAnalysisProvider.notifier);
    await notifier.pickVideo();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(poseAnalysisProvider);
    final notifier = ref.read(poseAnalysisProvider.notifier);

    // 현재 선택된 부위/색상
    final currentPart = state.activeTracks.isNotEmpty
        ? state.activeTracks.keys.first
        : PoseLandmarkType.rightWrist;
    final currentColor = state.activeTracks.isNotEmpty
        ? state.activeTracks.values.first
        : const Color(0xFFFFEB3B);

    if (state.videoPath != null && (_previewController == null || _previewController!.dataSource != 'file://${state.videoPath}')) {
      _previewController?.dispose();
      _previewController = VideoPlayerController.file(File(state.videoPath!))
        ..initialize().then((_) => setState(() {}));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("분석 설정", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // 영상 미리보기 영역
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_previewController != null && _previewController!.value.isInitialized)
                  AspectRatio(
                    aspectRatio: _previewController!.value.aspectRatio,
                    child: VideoPlayer(_previewController!),
                  )
                else
                  const Center(child: CircularProgressIndicator(color: Colors.white)),

                // 영상 변경 버튼
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Material(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _changeVideo,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.video_library_outlined, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              "영상 변경",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
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
                  // 🔥 [추가됨] 분석 가이드 팁 (파란색 박스)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tips_and_updates_outlined, size: 18, color: Colors.blue[800]),
                            const SizedBox(width: 8),
                            Text("정확한 분석을 위한 팁", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900], fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTipText("• 원활한 분석을 위해 20~25초 내외의 영상을 권장합니다."),
                        const SizedBox(height: 4),
                        _buildTipText("• 측면에서 몸과 팔 전체가 나오도록 촬영하면 가장 정확합니다."),
                      ],
                    ),
                  ),

                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("추적 부위 선택", Icons.ads_click),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: trackingPartsMap.entries.where((entry) {
                              final name = entry.key;
                              return !name.contains('엄지') && !name.contains('검지');
                            }).map((entry) {
                              final isSelected = currentPart == entry.value;
                              return ChoiceChip(
                                label: Text(entry.key),
                                labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey[700],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    notifier.setSingleTrack(entry.value, currentColor);
                                  }
                                },
                                selectedColor: Colors.cyan[600],
                                backgroundColor: Colors.grey[100],
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!)
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),

                          _buildSectionHeader("뼈대 색상", Icons.palette_outlined),
                          const SizedBox(height: 12),
                          _buildColorRow(
                              [Colors.white, Colors.redAccent, Colors.greenAccent, Colors.black],
                              state.poseColor,
                                  (c) => notifier.setPoseColor(c)
                          ),

                          const SizedBox(height: 24),

                          _buildSectionHeader("트래킹 라인 색상", Icons.timeline),
                          const SizedBox(height: 12),
                          _buildColorRow(
                              [const Color(0xFFFFEB3B), Colors.blueAccent, Colors.purpleAccent, Colors.orangeAccent],
                              currentColor,
                                  (c) => notifier.setSingleTrack(currentPart, c)
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PoseAnalysisProcessScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[600],
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("분석 시작", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 가이드 텍스트 스타일 헬퍼
  Widget _buildTipText(String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.blue[800], fontSize: 13, height: 1.4),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildColorRow(List<Color> colors, Color selectedColor, Function(Color) onSelect) {
    return Row(
      children: colors.map((color) {
        final isSelected = color == selectedColor;
        final isWhite = color == Colors.white;

        return GestureDetector(
          onTap: () => onSelect(color),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                  color: isSelected ? Colors.cyan : (isWhite ? Colors.grey[300]! : Colors.transparent),
                  width: isSelected ? 2.5 : 1
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
            ),
            child: isSelected
                ? Icon(Icons.check, size: 20, color: isWhite ? Colors.black : Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}