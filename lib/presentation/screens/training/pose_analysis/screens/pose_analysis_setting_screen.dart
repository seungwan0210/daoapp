import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/providers/training/pose_analysis_provider.dart';
import 'package:daoapp/presentation/screens/training/pose_analysis/screens/pose_analysis_process_screen.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:daoapp/l10n/app_localizations.dart';

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

  String _getTranslatedPartName(String rawKey, AppLocalizations s) {
    // 손목
    if (rawKey.contains('오른쪽 손목') || rawKey.contains('Right Wrist')) return s.pose_label_r_wrist;
    if (rawKey.contains('왼쪽 손목') || rawKey.contains('Left Wrist')) return s.pose_label_l_wrist;

    // 팔꿈치
    if (rawKey.contains('오른쪽 팔꿈치') || rawKey.contains('Right Elbow')) return s.pose_label_r_elbow;
    if (rawKey.contains('왼쪽 팔꿈치') || rawKey.contains('Left Elbow')) return s.pose_label_l_elbow;

    // 어깨 (새로 추가)
    if (rawKey.contains('오른쪽 어깨') || rawKey.contains('Right Shoulder')) return s.pose_label_r_shoulder;
    if (rawKey.contains('왼쪽 어깨') || rawKey.contains('Left Shoulder')) return s.pose_label_l_shoulder;

    return rawKey;
  }

  Future<void> _changeVideo() async {
    _previewController?.pause();
    final notifier = ref.read(poseAnalysisProvider.notifier);
    await notifier.pickVideo();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final state = ref.watch(poseAnalysisProvider);
    final notifier = ref.read(poseAnalysisProvider.notifier);

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
        title: Text(s.pose_setting_title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.video_library_outlined, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              s.pose_setting_change_video,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                            Text(s.pose_setting_tip_title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900], fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTipText(s.pose_setting_tip1),
                        const SizedBox(height: 4),
                        _buildTipText(s.pose_setting_tip2),
                      ],
                    ),
                  ),

                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(s.pose_setting_section_part, Icons.ads_click),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: trackingPartsMap.entries.where((entry) {
                              final name = entry.key;
                              return !name.contains('엄지') && !name.contains('검지');
                            }).map((entry) {
                              final isSelected = currentPart == entry.value;
                              return ChoiceChip(
                                // ✅ 헬퍼 함수를 통해 번역된 텍스트를 적용합니다.
                                label: Text(_getTranslatedPartName(entry.key, s)),
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

                          _buildSectionHeader(s.pose_setting_section_skeleton, Icons.palette_outlined),
                          const SizedBox(height: 12),
                          _buildColorRow(
                              [Colors.white, Colors.redAccent, Colors.greenAccent, Colors.black],
                              state.poseColor,
                                  (c) => notifier.setPoseColor(c)
                          ),

                          const SizedBox(height: 24),

                          _buildSectionHeader(s.pose_setting_section_line, Icons.timeline),
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
                child: Text(s.pose_setting_btn_start, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

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