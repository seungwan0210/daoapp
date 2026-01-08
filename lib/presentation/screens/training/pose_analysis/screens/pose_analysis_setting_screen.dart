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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(poseAnalysisProvider);
    final notifier = ref.read(poseAnalysisProvider.notifier);

    // 현재 선택된 메인 트래킹 부위 (설정 화면에서는 하나만 선택한다고 가정)
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
          Container(
            height: 220,
            width: double.infinity,
            color: Colors.black,
            child: _previewController != null && _previewController!.value.isInitialized
                ? AspectRatio(
              aspectRatio: _previewController!.value.aspectRatio,
              child: VideoPlayer(_previewController!),
            )
                : const Center(child: CircularProgressIndicator(color: Colors.white)),
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
                          _buildSectionHeader("추적 부위 (결과 화면에서 추가 가능)", Icons.ads_click),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: trackingPartsMap.entries.map((entry) {
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
                                    // 설정 화면에서는 하나만 선택하게 하여 색상 매칭 단순화
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
                                  (c) => notifier.setSingleTrack(currentPart, c) // 현재 선택된 부위의 색상 변경
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ [수정] SafeArea 추가하여 네비게이션 바에 가리지 않게 함
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