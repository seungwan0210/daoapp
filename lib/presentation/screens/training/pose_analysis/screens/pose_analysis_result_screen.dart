import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // ✅ 광고 패키지
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

  // 💰 [광고] 결과 화면 하단 배너
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
    _loadBannerAd(); // 배너 광고 로드

    // 🔥 [수정] 화면 진입 시 즉시 분석 (기준선 없어도 동작)
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

  // 광고 로드 (home_banner)
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-5180429166023258/2238891690', // ✅ 실제 ID 적용됨
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

  // ✅ [수정된 분석 로직] NONE이어도 자동 감지하여 분석
  void _analyzeData(Map<int, List<Pose>>? analysisResults) {
    if (analysisResults == null) return;

    _cachedSetupHeights.clear();
    _releasePoints.clear();

    // 🔥 팔 방향 자동 결정 로직
    bool isRight = true;

    if (_referenceMode == 'LEFT') {
      isRight = false;
    } else if (_referenceMode == 'NONE') {
      final activeTracks = ref.read(poseAnalysisProvider).activeTracks;
      // 왼손만 선택되어 있고 오른손은 선택 안 된 경우에만 왼쪽으로 간주
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

    // 1. 스탠스 식별 (엄격 모드 6.0)
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

      if (movement < 6.0) {
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

    // 2. 릴리즈 포인트
    bool isThrowing = false;
    bool releaseDetected = false;
    int lastReleaseFrame = -999;

    for (int fIdx in sortedFrames) {
      if (!stanceFrames.contains(fIdx)) {
        isThrowing = false; releaseDetected = false; continue;
      }

      final pose = _getPose(analysisResults, fIdx);
      if (pose == null) continue;

      double angle = _calculateAngle(pose, shoulder, elbow, wrist);

      if (angle < 80 && angle > 20) {
        isThrowing = true; releaseDetected = false;
      }

      if (isThrowing && !releaseDetected && angle > 90) {
        if (fIdx - lastReleaseFrame > 30) {
          final w = pose.landmarks[wrist];
          if (w != null) {
            _releasePoints.add(ReleasePoint(Offset(w.x, w.y), fIdx));
            releaseDetected = true;
            lastReleaseFrame = fIdx;
          }
        }
      }

      if (isThrowing && angle < 100 && releaseDetected) {
        isThrowing = false;
      }
    }
  }

  Pose? _getPose(Map<int, List<Pose>>? results, int index) {
    if (results != null && results.containsKey(index) && results[index]!.isNotEmpty) {
      return results[index]!.first;
    }
    return null;
  }

  double _calculateDistance(Offset p1, Offset p2) {
    return math.sqrt(math.pow(p1.dx - p2.dx, 2) + math.pow(p1.dy - p2.dy, 2));
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
      // NONE일 때도 내가 선택한 손목은 그려주기
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
      multiPaths[part] = applySmoothing(rawPath, windowSize: 4);
    }
    return multiPaths;
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

                  // 🔥 [광고 배너 영역]
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
                      child: const Text(""), // 로딩 중에는 빈 공간
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

// ✅ 렌더링 다이얼로그 (병렬 처리 + 전면 광고 + MREC + 상단 배너)
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
  bool _isAnalysisFinished = false; // 분석 완료 여부 체크

  // 💰 광고
  BannerAd? _topBannerAd;
  BannerAd? _bottomMrecAd;
  InterstitialAd? _interstitialAd; // 🔥 전면 광고

  bool _isTopAdLoaded = false;
  bool _isBottomAdLoaded = false;
  bool _isInterstitialShowed = false; // 전면광고 보여졌는지 여부

  @override
  void initState() {
    super.initState();
    _loadBannerAds();
    _loadInterstitialAd(); // 🔥 전면 광고 로드 및 즉시 실행
    _startRendering();     // 병렬로 렌더링 시작
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
      adUnitId: 'ca-app-pub-5180429166023258/2238891690', // ✅ home_banner ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isTopAdLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();

    _bottomMrecAd = BannerAd(
      adUnitId: 'ca-app-pub-5180429166023258/8399618129', // ✅ loading_mrec ID
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBottomAdLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  // 🔥 전면 광고: 로드되면 바로 보여줌
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-5180429166023258/2986659287', // ✅ save_interstitial ID (실제 적용됨)
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.show(); // 로드 즉시 표시!
          _isInterstitialShowed = true;

          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              // 광고 닫았는데 이미 분석이 끝나있다면 -> 바로 닫기(성공 팝업)
              if (_isAnalysisFinished && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("갤러리에 저장되었습니다!")));
              }
            },
            onAdFailedToShowFullScreenContent: (ad, err) => ad.dispose(),
          );
        },
        onAdFailedToLoad: (err) {
          print('전면 광고 로드 실패: $err');
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
          if (mounted) {
            setState(() {
              _progress = progress;
              if (progress < 0.2) _status = "프레임 추출 중...";
              else if (progress < 0.8) _status = "AI 뼈대 그리는 중... (오래 걸려요)";
              else if (progress < 1.0) _status = "영상 인코딩 중...";
              else _status = "저장 완료!";
            });
            if (progress >= 1.0) {
              _isAnalysisFinished = true; // 완료 플래그 ON

              // 전면 광고가 안 떴거나(로드 실패 등), 이미 닫힌 상태라면 여기서 닫아줌
              if (!_isInterstitialShowed || _interstitialAd == null) {
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("갤러리에 저장되었습니다!")));
                  }
                });
              }
            }
          }
        });
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
              // 1. 상단 배너
              if (_isTopAdLoaded && _topBannerAd != null)
                Container(
                  width: _topBannerAd!.size.width.toDouble(),
                  height: _topBannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _topBannerAd!),
                )
              else
                Container(width: 320, height: 50, color: Colors.grey[50]),

              const SizedBox(height: 24),

              // 2. 로딩
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

              const SizedBox(height: 24),

              // 3. 하단 MREC (전면광고 닫고 나오면 보이는 큰 배너)
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