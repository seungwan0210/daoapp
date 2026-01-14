import 'dart:io'; // 🔥 Platform.isAndroid 사용을 위해 필수!
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/providers/training/pose_analysis_provider.dart';
import 'package:daoapp/presentation/screens/training/pose_analysis/widgets/pose_painter.dart';
import 'package:daoapp/presentation/screens/training/pose_analysis/screens/pose_analysis_setting_screen.dart';

// ✅ 시간 순서 표시를 위한 데이터 모델
class ReleasePoint {
  final Offset point;   // 위치
  final int frameIndex; // 시간
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

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

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
    _loadBannerAd();

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
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      // 🔥 [수정] 기기에 따라 광고 ID 분기
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-5180429166023258/2238891690' // 안드로이드 배너
          : 'ca-app-pub-5180429166023258/8644517940', // iOS 배너 (home_banner)
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('결과 화면 배너 로드 실패: $error');
        },
      ),
    )..load();
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

  Pose? _getCurrentPose(Map<int, List<Pose>>? analysisResults, int currentFrame) {
    if (analysisResults == null || !analysisResults.containsKey(currentFrame)) return null;
    if (analysisResults[currentFrame]!.isEmpty) return null;
    return analysisResults[currentFrame]!.first;
  }

  // ✅ [중요 수정] 미리보기 분석 로직을 영상 저장 로직과 100% 동일하게 맞춤 (높이 체크 + 교차 검증)
  void _analyzeData(Map<int, List<Pose>>? analysisResults) {
    if (analysisResults == null) return;

    _cachedSetupHeights.clear();
    _releasePoints.clear();

    bool isRight = true;

    if (_referenceMode == 'LEFT') {
      isRight = false;
    } else if (_referenceMode == 'NONE') {
      final activeTracks = ref.read(poseAnalysisProvider).activeTracks;
      if (activeTracks.containsKey(PoseLandmarkType.leftWrist) &&
          !activeTracks.containsKey(PoseLandmarkType.rightWrist)) {
        isRight = false;
      }
    }

    PoseLandmarkType wrist = isRight ? PoseLandmarkType.rightWrist : PoseLandmarkType.leftWrist;
    PoseLandmarkType elbow = isRight ? PoseLandmarkType.rightElbow : PoseLandmarkType.leftElbow;
    PoseLandmarkType shoulder = isRight ? PoseLandmarkType.rightShoulder : PoseLandmarkType.leftShoulder;
    PoseLandmarkType hip = isRight ? PoseLandmarkType.rightHip : PoseLandmarkType.leftHip;

    List<int> sortedFrames = analysisResults.keys.toList()..sort();

    // 1. 스탠스 식별 (8.0 기준)
    Set<int> stanceFrames = {};
    List<double> validElbowYs = [];
    List<double> validWristYs = [];
    int window = 5;

    for (int i = window; i < sortedFrames.length - window; i++) {
      int currFrame = sortedFrames[i];
      int prevFrame = sortedFrames[i - window];

      final currPose = _getPose(analysisResults, currFrame);
      final prevPose = _getPose(analysisResults, prevFrame);
      if (currPose == null || prevPose == null) continue;

      final currHip = currPose.landmarks[hip];
      final prevHip = prevPose.landmarks[hip];
      if (currHip == null || prevHip == null) continue;

      double movement = (currHip.x - prevHip.x).abs();

      if (movement < 8.0) {
        stanceFrames.add(currFrame);
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

    // 2. 릴리즈 포인트 (영상 저장 로직과 동기화)
    int lastReleaseFrame = -999;

    for (int i = 1; i < sortedFrames.length; i++) {
      int currF = sortedFrames[i];
      int prevF = sortedFrames[i - 1];

      if (!stanceFrames.contains(currF)) continue;

      final currPose = _getPose(analysisResults, currF);
      final prevPose = _getPose(analysisResults, prevF);
      if (currPose == null || prevPose == null) continue;

      final w = currPose.landmarks[wrist];
      final e = currPose.landmarks[elbow];

      if (w == null || e == null) continue;

      // 🔥 [조건 1] 높이 체크: 손목이 팔꿈치보다 높아야 함 (화면상 y좌표가 작아야 함)
      bool isHigherThanElbow = w.y < e.y;
      if (!isHigherThanElbow) continue; // 팔꿈치보다 낮으면 무시

      // 각도 계산
      double currAngle = _calculateAngle(currPose, shoulder, elbow, wrist);
      double prevAngle = _calculateAngle(prevPose, shoulder, elbow, wrist);

      // 🔥 [조건 2] 교차 검증: 90도 안쪽이었다가 90도를 지나는 순간
      bool isCrossing = (prevAngle < 90.0) && (currAngle >= 90.0);

      if (isCrossing) {
        if (currF - lastReleaseFrame > 15) {
          _releasePoints.add(ReleasePoint(Offset(w.x, w.y), currF));
          lastReleaseFrame = currF;
        }
      }
    }
  }

  Pose? _getPose(Map<int, List<Pose>>? results, int index) {
    if (results != null && results.containsKey(index) && results[index]!.isNotEmpty) {
      return results[index]!.first;
    }
    return null;
  }

  double _calculateAngle(Pose pose, PoseLandmarkType a, PoseLandmarkType b, PoseLandmarkType c) {
    final la = pose.landmarks[a]; final lb = pose.landmarks[b]; final lc = pose.landmarks[c];
    if (la == null || lb == null || lc == null) return 180;
    double radians = math.atan2(lc.y - lb.y, lc.x - lb.x) - math.atan2(la.y - lb.y, la.x - lb.x);
    double angle = (radians * 180.0 / math.pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  Map<PoseLandmarkType, List<Offset>> _getCurrentMultiPaths(
      Map<int, List<Pose>>? analysisResults,
      Map<PoseLandmarkType, Color> activeTracks,
      int currentFrameIndex,
      ) {
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
    } else {
      if (activeTracks.containsKey(PoseLandmarkType.rightWrist)) targetsToCalculate.add(PoseLandmarkType.rightWrist);
      if (activeTracks.containsKey(PoseLandmarkType.leftWrist)) targetsToCalculate.add(PoseLandmarkType.leftWrist);
    }

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
      multiPaths[part] = _applySmoothing(rawPath, windowSize: 4);
    }
    return multiPaths;
  }

  List<Offset> _applySmoothing(List<Offset> points, {int windowSize = 4}) {
    if (points.length < windowSize) return points;
    List<Offset> smoothedPoints = [];
    for (int i = 0; i < points.length; i++) {
      double sumX = 0; double sumY = 0; int count = 0;
      for (int j = 0; j < windowSize; j++) {
        if (i - j >= 0) { sumX += points[i - j].dx; sumY += points[i - j].dy; count++; }
      }
      smoothedPoints.add(Offset(sumX / count, sumY / count));
    }
    return smoothedPoints;
  }

  void _setReferenceMode(String mode) {
    setState(() {
      _referenceMode = mode;
      final results = ref.read(poseAnalysisProvider).analysisResults;
      _analyzeData(results);
    });
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
    final state = ref.watch(poseAnalysisProvider);
    final notifier = ref.read(poseAnalysisProvider.notifier);

    int currentFrameIndex = 0;
    if (_videoController != null && _videoController!.value.isInitialized) {
      double currentSeconds = _videoController!.value.position.inMicroseconds / 1000000.0;
      currentFrameIndex = (currentSeconds * 30).round();
    }

    Pose? currentPose = _getCurrentPose(state.analysisResults, currentFrameIndex);

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
              height: 280, width: double.infinity, color: Colors.black,
              child: Stack(
                  alignment: Alignment.center,
                  children: [
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
                  ]
              )
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

                          _buildSwitchRow(
                            title: "트래킹 궤적 보기",
                            subtitle: "투구 궤적 표시",
                            value: _showTrackingLines,
                            onChanged: (val) => setState(() => _showTrackingLines = val),
                          ),
                          const SizedBox(height: 12),
                          _buildSwitchRow(
                            title: "릴리즈 포인트 보기",
                            subtitle: "던지는 순간 표시 (점)",
                            value: _showReleasePoints,
                            onChanged: (val) => setState(() => _showReleasePoints = val),
                          ),

                          const SizedBox(height: 20),
                          if (_showTrackingLines) ...[
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
                  const SizedBox(height: 16),
                  if (_isBannerLoaded && _bannerAd != null)
                    Container(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 50,
                      alignment: Alignment.center,
                      child: const Text(""),
                    ),
                  const SizedBox(height: 20),
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

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        Switch(
          value: value,
          activeColor: Colors.cyan,
          onChanged: onChanged,
        ),
      ],
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
            child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
      ),
    );
  }
}

// ✅ [병렬 처리 완벽 구현] 렌더링 + 광고 동시 실행 후 둘 다 끝나야 닫힘
class _RenderingProgressDialog extends ConsumerStatefulWidget {
  final String mode;
  final bool showTracking;
  final bool showRelease;

  const _RenderingProgressDialog({
    required this.mode,
    required this.showTracking,
    required this.showRelease,
  });

  @override
  ConsumerState<_RenderingProgressDialog> createState() => _RenderingProgressDialogState();
}

class _RenderingProgressDialogState extends ConsumerState<_RenderingProgressDialog> {
  double _progress = 0.0;
  String _status = "영상 분석 준비 중...";

  // 🔥 병렬 처리 상태 변수
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
    _loadBannerAds();

    // ✅ [병렬] 동시에 실행
    _loadInterstitialAd();
    _startRendering();
  }

  @override
  void dispose() {
    _topBannerAd?.dispose();
    _bottomMrecAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _loadBannerAds() {
    _topBannerAd = BannerAd(
      // 🔥 [수정] 상단 배너 ID 분기
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-5180429166023258/2238891690' // 안드로이드 배너
          : 'ca-app-pub-5180429166023258/8644517940', // iOS 배너 (home_banner)
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isTopAdLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();

    _bottomMrecAd = BannerAd(
      // 🔥 [수정] 하단 MREC ID 분기
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-5180429166023258/8399618129' // 안드로이드 MREC
          : 'ca-app-pub-5180429166023258/4871189236', // iOS MREC (loading_mrec)
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBottomAdLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      // 🔥 [수정] 전면 광고 ID 분기
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-5180429166023258/2986659287' // 안드로이드 전면
          : 'ca-app-pub-5180429166023258/1484470385', // iOS 전면 (save_interstitial)
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.setImmersiveMode(true);
          _interstitialAd!.show();

          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isAdFinished = true; // 광고 종료 체크
              _checkAndExit();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _isAdFinished = true; // 실패해도 종료로 간주
              _checkAndExit();
            },
          );
        },
        onAdFailedToLoad: (err) {
          print('전면 광고 로드 실패: $err');
          _isAdFinished = true; // 로드 실패시 바로 종료로 간주
          _checkAndExit();
        },
      ),
    );
  }

  void _startRendering() {
    ref.read(poseAnalysisProvider.notifier).saveRenderedVideo(
        widget.mode,
        widget.showTracking,
        widget.showRelease,
            (progress) {
          if (!mounted) return;

          setState(() {
            _progress = progress;
            if (progress < 0.2) _status = "프레임 추출 중...";
            else if (progress < 0.8) _status = "AI 뼈대 그리는 중... (오래 걸려요)";
            else if (progress < 1.0) _status = "영상 인코딩 중...";
            else _status = "저장 완료!";
          });

          if (progress >= 1.0) {
            _isRenderingFinished = true; // 렌더링 종료 체크
            _checkAndExit();
          }
        });
  }

  // ✅ 둘 다 끝났는지 확인하고 종료
  void _checkAndExit() {
    if (_isRenderingFinished && _isAdFinished) {
      if (mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("갤러리에 저장되었습니다!")));
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isTopAdLoaded && _topBannerAd != null)
                Container(
                  width: _topBannerAd!.size.width.toDouble(),
                  height: _topBannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _topBannerAd!),
                )
              else
                Container(width: 320, height: 50, color: Colors.grey[50]),

              const SizedBox(height: 24),

              const Text("영상 생성 중...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              Stack(alignment: Alignment.center, children: [
                SizedBox(
                    width: 70, height: 70,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 6,
                      color: Colors.cyan,
                      backgroundColor: Colors.grey[200],
                    )
                ),
                Text(
                    "${(_progress * 100).toInt()}%",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
              ]),
              const SizedBox(height: 12),
              Text(_status, style: TextStyle(color: Colors.grey[600], fontSize: 13)),

              // 렌더링은 끝났는데 광고 보는 중일 때 안내
              if (_isRenderingFinished && !_isAdFinished)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text("저장은 완료되었습니다. 광고를 닫으면 화면이 종료됩니다.",
                      style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                ),

              const SizedBox(height: 24),

              if (_isBottomAdLoaded && _bottomMrecAd != null)
                Container(
                  width: _bottomMrecAd!.size.width.toDouble(),
                  height: _bottomMrecAd!.size.height.toDouble(),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!)),
                  child: AdWidget(ad: _bottomMrecAd!),
                )
              else
                Container(
                  width: 300, height: 250,
                  decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!)
                  ),
                  alignment: Alignment.center,
                  child: const Text("광고 로딩 중...", style: TextStyle(color: Colors.grey)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}