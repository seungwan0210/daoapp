import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:daoapp/core/utils/ad_manager.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/ad_banner.dart';
import 'package:daoapp/presentation/providers/training/pose_analysis_provider.dart';
import 'package:daoapp/presentation/screens/training/pose_analysis/widgets/pose_painter.dart';
import 'package:daoapp/presentation/screens/training/pose_analysis/screens/pose_analysis_setting_screen.dart';
import 'package:daoapp/l10n/app_localizations.dart';

class ReleasePoint {
  final Offset point;
  final int frameIndex;
  ReleasePoint(this.point, this.frameIndex);
}

class PoseAnalysisResultScreen extends ConsumerStatefulWidget {
  const PoseAnalysisResultScreen({super.key});

  @override
  ConsumerState<PoseAnalysisResultScreen> createState() => _PoseAnalysisResultScreenState();
}

class _PoseAnalysisResultScreenState extends ConsumerState<PoseAnalysisResultScreen> {
  VideoPlayerController? _videoController;

  bool _showTrackingLines = true;
  bool _showReleasePoints = true;
  String _referenceMode = 'NONE';

  Map<PoseLandmarkType, double> _cachedSetupHeights = {};
  List<ReleasePoint> _releasePoints = [];

  final Map<PoseLandmarkType, Color> _partColors = {
    PoseLandmarkType.rightWrist: const Color(0xFFFFEB3B),
    PoseLandmarkType.rightElbow: const Color(0xFF2979FF),
    PoseLandmarkType.leftWrist: const Color(0xFF00E676),
    PoseLandmarkType.leftElbow: const Color(0xFFFF4081),
  };

  @override
  void initState() {
    super.initState();
    _initVideo();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final results = ref.read(poseAnalysisProvider).analysisResults;
      if (results != null) {
        _analyzeData(results);
      }
    });
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

  void _analyzeData(Map<int, List<Pose>>? analysisResults) {
    if (analysisResults == null) return;
    _cachedSetupHeights.clear();
    _releasePoints.clear();

    bool isRight = _referenceMode != 'LEFT';
    if (_referenceMode == 'NONE') {
      final activeTracks = ref.read(poseAnalysisProvider).activeTracks;
      if (activeTracks.containsKey(PoseLandmarkType.leftWrist) && !activeTracks.containsKey(PoseLandmarkType.rightWrist)) {
        isRight = false;
      }
    }

    PoseLandmarkType wrist = isRight ? PoseLandmarkType.rightWrist : PoseLandmarkType.leftWrist;
    PoseLandmarkType elbow = isRight ? PoseLandmarkType.rightElbow : PoseLandmarkType.leftElbow;
    PoseLandmarkType shoulder = isRight ? PoseLandmarkType.rightShoulder : PoseLandmarkType.leftShoulder;
    PoseLandmarkType hip = isRight ? PoseLandmarkType.rightHip : PoseLandmarkType.leftHip;

    List<int> sortedFrames = analysisResults.keys.toList()..sort();
    Set<int> stanceFrames = {};
    List<double> validElbowYs = [];
    List<double> validWristYs = [];

    for (int i = 5; i < sortedFrames.length - 5; i++) {
      final currPose = _getPose(analysisResults, sortedFrames[i]);
      final prevPose = _getPose(analysisResults, sortedFrames[i - 5]);
      if (currPose == null || prevPose == null) continue;
      final currHip = currPose.landmarks[hip];
      final prevHip = prevPose.landmarks[hip];
      if (currHip != null && prevHip != null && (currHip.x - prevHip.x).abs() < 8.0) {
        stanceFrames.add(sortedFrames[i]);
        final e = currPose.landmarks[elbow];
        final w = currPose.landmarks[wrist];
        if (e != null && e.y > 0) validElbowYs.add(e.y);
        if (w != null && w.y > 0) validWristYs.add(w.y);
      }
    }

    if (validElbowYs.isNotEmpty) {
      validElbowYs.sort();
      _cachedSetupHeights[elbow] = validElbowYs[(validElbowYs.length * 0.3).toInt()];
    }
    if (validWristYs.isNotEmpty) {
      validWristYs.sort();
      _cachedSetupHeights[wrist] = validWristYs[(validWristYs.length * 0.3).toInt()];
    }

    int lastReleaseFrame = -999;
    for (int i = 1; i < sortedFrames.length; i++) {
      int currF = sortedFrames[i];
      if (!stanceFrames.contains(currF)) continue;
      final currPose = _getPose(analysisResults, currF);
      final prevPose = _getPose(analysisResults, sortedFrames[i - 1]);
      if (currPose == null || prevPose == null) continue;
      final w = currPose.landmarks[wrist];
      final e = currPose.landmarks[elbow];
      if (w != null && e != null && w.y < e.y) {
        double currAngle = _calculateAngle(currPose, shoulder, elbow, wrist);
        double prevAngle = _calculateAngle(prevPose, shoulder, elbow, wrist);
        if (prevAngle < 90.0 && currAngle >= 90.0 && (currF - lastReleaseFrame > 15)) {
          _releasePoints.add(ReleasePoint(Offset(w.x, w.y), currF));
          lastReleaseFrame = currF;
        }
      }
    }
  }

  Pose? _getPose(Map<int, List<Pose>>? results, int index) => (results != null && results.containsKey(index) && results[index]!.isNotEmpty) ? results[index]!.first : null;

  double _calculateAngle(Pose pose, PoseLandmarkType a, PoseLandmarkType b, PoseLandmarkType c) {
    final la = pose.landmarks[a]; final lb = pose.landmarks[b]; final lc = pose.landmarks[c];
    if (la == null || lb == null || lc == null) return 180;
    double radians = math.atan2(lc.y - lb.y, lc.x - lb.x) - math.atan2(la.y - lb.y, la.x - lb.x);
    double angle = (radians * 180.0 / math.pi).abs();
    return angle > 180.0 ? 360.0 - angle : angle;
  }

  // 🔹 [오류 해결] 누락된 메서드 추가
  Map<PoseLandmarkType, List<Offset>> _getCurrentMultiPaths(Map<int, List<Pose>>? analysisResults, Map<PoseLandmarkType, Color> activeTracks, int currentFrameIndex) {
    if (analysisResults == null || _videoController == null) return {};
    Map<PoseLandmarkType, List<Offset>> multiPaths = {};
    final sortedKeys = analysisResults.keys.toList()..sort();
    Set<PoseLandmarkType> targetsToCalculate = {};
    targetsToCalculate.addAll(activeTracks.keys);

    if (_referenceMode == 'RIGHT') {
      targetsToCalculate.add(PoseLandmarkType.rightWrist);
      targetsToCalculate.add(PoseLandmarkType.rightElbow);
    } else if (_referenceMode == 'LEFT') {
      targetsToCalculate.add(PoseLandmarkType.leftWrist);
      targetsToCalculate.add(PoseLandmarkType.leftElbow);
    }

    for (var part in targetsToCalculate) {
      List<Offset> rawPath = [];
      for (int key in sortedKeys) {
        if (key > currentFrameIndex) break;
        final poses = analysisResults[key];
        if (poses != null && poses.isNotEmpty) {
          final landmark = poses.first.landmarks[part];
          if (landmark != null && landmark.likelihood > 0.6) rawPath.add(Offset(landmark.x, landmark.y));
        }
      }
      multiPaths[part] = _applySmoothing(rawPath, windowSize: 4);
    }
    return multiPaths;
  }

  // 🔹 [오류 해결] 누락된 메서드 추가
  List<Offset> _applySmoothing(List<Offset> points, {int windowSize = 4}) {
    if (points.length < windowSize) return points;
    List<Offset> smoothedPoints = [];
    for (int i = 0; i < points.length; i++) {
      double sumX = 0; double sumY = 0; int count = 0;
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

  void _handleSaveVideo() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RenderingProgressDialog(
        mode: _referenceMode,
        showTracking: _showTrackingLines,
        showRelease: _showReleasePoints,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final state = ref.watch(poseAnalysisProvider);
    final notifier = ref.read(poseAnalysisProvider.notifier);

    int currentFrameIndex = 0;
    if (_videoController != null && _videoController!.value.isInitialized) {
      currentFrameIndex = (_videoController!.value.position.inMicroseconds / 1000000.0 * 30).round();
    }
    Pose? currentPose = _getPose(state.analysisResults, currentFrameIndex);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(s.pose_result_title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: () { notifier.reset(); Navigator.of(context).popUntil((route) => route.isFirst); })
        ],
      ),
      body: Column(
        children: [
          Container(
              height: 280, width: double.infinity, color: Colors.black,
              child: Stack(alignment: Alignment.center, children: [
                if (_videoController != null && _videoController!.value.isInitialized)
                  AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!)),
                if (_videoController != null && state.analysisResults != null && currentPose != null)
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: CustomPaint(
                      painter: PosePainter(
                        pose: currentPose,
                        imageSize: state.videoSize ?? const Size(1080, 1920),
                        poseColor: state.poseColor,
                        multiPaths: _getCurrentMultiPaths(state.analysisResults, state.activeTracks, currentFrameIndex),
                        activeTrackColors: state.activeTracks,
                        allPartColors: _partColors,
                        showTrackingLines: _showTrackingLines,
                        showReleasePoints: _showReleasePoints,
                        referenceMode: _referenceMode,
                        setupHeights: _cachedSetupHeights,
                        releasePoints: _releasePoints,
                        currentFrameIndex: currentFrameIndex,
                        labelRElbow: s.pose_label_r_elbow,
                        labelLElbow: s.pose_label_l_elbow,
                        labelRWrist: s.pose_label_r_wrist,
                        labelLWrist: s.pose_label_l_wrist,
                        labelSet: s.pose_label_set,
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () => setState(() => _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play()),
                  child: Container(color: Colors.transparent, child: Center(child: _videoController != null && !_videoController!.value.isPlaying ? const Icon(Icons.play_circle_fill, size: 64, color: Colors.white70) : const SizedBox.shrink())),
                ),
              ])
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
                          Text(s.pose_result_guide_title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 12),
                          Row(children: [
                            _buildModeButton(s.pose_result_guide_off, "NONE", Colors.grey),
                            const SizedBox(width: 8),
                            _buildModeButton(s.pose_result_guide_left, "LEFT", Colors.cyan),
                            const SizedBox(width: 8),
                            _buildModeButton(s.pose_result_guide_right, "RIGHT", Colors.cyan),
                          ]),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),
                          _buildSwitchRow(title: s.pose_result_show_track, subtitle: s.pose_result_show_track_sub, value: _showTrackingLines, onChanged: (val) => setState(() => _showTrackingLines = val)),
                          const SizedBox(height: 12),
                          _buildSwitchRow(title: s.pose_result_show_release, subtitle: s.pose_result_show_release_sub, value: _showReleasePoints, onChanged: (val) => setState(() => _showReleasePoints = val)),
                          const SizedBox(height: 20),
                          if (_showTrackingLines) ...[
                            Text(s.pose_result_select_part, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: trackingPartsMap.entries.map((entry) {
                              final isSelected = state.activeTracks.containsKey(entry.value);
                              return ChoiceChip(
                                label: Text(entry.key, style: const TextStyle(fontSize: 12)),
                                selected: isSelected,
                                onSelected: (selected) => notifier.toggleTrack(entry.value, _partColors[entry.value] ?? Colors.yellow),
                                selectedColor: Colors.cyan[100],
                                labelStyle: TextStyle(color: isSelected ? Colors.cyan[800] : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                backgroundColor: Colors.grey[100],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.cyan : Colors.grey[300]!)),
                              );
                            }).toList()),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const AdBanner(type: AdBannerType.detail),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
              child: Row(children: [
                Expanded(child: OutlinedButton(onPressed: () async {
                  notifier.reset();
                  if (await notifier.pickVideo() && context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PoseAnalysisSettingScreen()));
                  }
                }, style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), side: BorderSide(color: Colors.grey[300]!), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(s.pose_result_btn_repick, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(onPressed: _handleSaveVideo, icon: const Icon(Icons.download_rounded, size: 18), label: Text(s.pose_result_btn_save), style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan[600], foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0))),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 [오류 해결] 누락된 메서드 추가
  Widget _buildSwitchRow({required String title, required String subtitle, required bool value, required Function(bool) onChanged}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey))]),
      Switch(value: value, activeColor: Colors.cyan, onChanged: onChanged),
    ]);
  }

  // 🔹 [오류 해결] 누락된 메서드 추가
  Widget _buildModeButton(String label, String mode, Color color) {
    final isSelected = _referenceMode == mode;
    return Expanded(child: GestureDetector(onTap: () => _setReferenceMode(mode), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isSelected ? color : Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? Colors.transparent : Colors.grey[300]!)), child: Center(child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13))))));
  }

  void _setReferenceMode(String mode) {
    setState(() {
      _referenceMode = mode;
      _analyzeData(ref.read(poseAnalysisProvider).analysisResults);
    });
  }
}

class _RenderingProgressDialog extends ConsumerStatefulWidget {
  final String mode;
  final bool showTracking;
  final bool showRelease;
  const _RenderingProgressDialog({required this.mode, required this.showTracking, required this.showRelease});
  @override
  ConsumerState<_RenderingProgressDialog> createState() => _RenderingProgressDialogState();
}

class _RenderingProgressDialogState extends ConsumerState<_RenderingProgressDialog> {
  double _progress = 0.0;
  String _statusKey = "pose_render_preparing";
  bool _isRenderingFinished = false;
  bool _isAdFinished = false;

  BannerAd? _topBannerAd;
  BannerAd? _bottomMrecAd;
  InterstitialAd? _interstitialAd;

  bool _isTopAdLoaded = false;
  bool _isBottomAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAds();
    _startRendering();
  }

  @override
  void dispose() {
    _topBannerAd?.dispose();
    _bottomMrecAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _loadAds() {
    if (kAdMobSuspended) {
      _isAdFinished = true;
      return;
    }
    _topBannerAd = BannerAd(
      adUnitId: AdManager.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(onAdLoaded: (_) => setState(() => _isTopAdLoaded = true), onAdFailedToLoad: (ad, _) => ad.dispose()),
    )..load();

    _bottomMrecAd = BannerAd(
      adUnitId: AdManager.mrecUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(onAdLoaded: (_) => setState(() => _isBottomAdLoaded = true), onAdFailedToLoad: (ad, _) => ad.dispose()),
    )..load();

    InterstitialAd.load(
      adUnitId: AdManager.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.show();
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) { ad.dispose(); _isAdFinished = true; _checkAndExit(); },
            onAdFailedToShowFullScreenContent: (ad, _) { ad.dispose(); _isAdFinished = true; _checkAndExit(); },
          );
        },
        onAdFailedToLoad: (_) { _isAdFinished = true; _checkAndExit(); },
      ),
    );
  }

  void _startRendering() {
    ref.read(poseAnalysisProvider.notifier).saveRenderedVideo(widget.mode, widget.showTracking, widget.showRelease, (progress) {
      if (!mounted) return;
      setState(() {
        _progress = progress;
        if (progress < 0.2) _statusKey = "pose_render_extracting";
        else if (progress < 0.8) _statusKey = "pose_render_analyzing";
        else if (progress < 1.0) _statusKey = "pose_render_encoding";
        else {
          _statusKey = "pose_render_complete";
          _isRenderingFinished = true;
          _checkAndExit();
        }
      });
    });
  }

  void _checkAndExit() {
    if (_isRenderingFinished && _isAdFinished && mounted) {
      final s = AppLocalizations.of(context)!;
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.pose_render_save_success)));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    String statusText = "";
    switch (_statusKey) {
      case "pose_render_preparing": statusText = s.pose_render_preparing; break;
      case "pose_render_extracting": statusText = s.pose_render_extracting; break;
      case "pose_render_analyzing": statusText = s.pose_render_analyzing; break;
      case "pose_render_encoding": statusText = s.pose_render_encoding; break;
      case "pose_render_complete": statusText = s.pose_render_complete; break;
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 330),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 24, 15, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!kAdMobSuspended && _isTopAdLoaded && _topBannerAd != null)
                  Center(child: SizedBox(width: _topBannerAd!.size.width.toDouble(), height: 50, child: AdWidget(ad: _topBannerAd!)))
                else const SizedBox(height: 50),
                const SizedBox(height: 20),
                Text(s.pose_render_dialog_title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(width: 80, height: 80, child: CircularProgressIndicator(value: _progress, strokeWidth: 7, color: Colors.cyan, backgroundColor: Colors.grey[100])),
                    Text("${(_progress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(statusText, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 32),
                if (!kAdMobSuspended && _isBottomAdLoaded && _bottomMrecAd != null)
                  Center(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(width: 300, height: 250, decoration: BoxDecoration(border: Border.all(color: Colors.grey[100]!)), child: AdWidget(ad: _bottomMrecAd!))))
                else Container(width: 300, height: 250, decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)), child: const Center(child: Text("DAO DARTS", style: TextStyle(color: Colors.grey, fontSize: 12)))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}