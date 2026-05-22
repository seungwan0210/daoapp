import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/presentation/providers/training/grip_baseline_provider.dart';
import 'package:daoapp/presentation/providers/training/grip_lab_provider.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_camera_screen.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/widgets/ghost_overlay_painter.dart';
import 'package:daoapp/core/utils/grip_coach.dart';
import 'package:daoapp/data/services/native_grip_bridge.dart';
import 'package:daoapp/services/grip_snapshot_service.dart';
import 'package:daoapp/l10n/app_localizations.dart';

class GripCompareScreen extends ConsumerStatefulWidget {
  const GripCompareScreen({super.key});

  @override
  ConsumerState<GripCompareScreen> createState() => _GripCompareScreenState();
}

class _GripCompareScreenState extends ConsumerState<GripCompareScreen> {
  final NativeGripBridge _cameraBridge = NativeGripBridge();

  // 🔥 [구조 변경] 이제 화면 전체가 아닌, 하단 결과 분석 스크롤 뷰만 타깃으로 삼습니다.
  final GlobalKey _resultCaptureKey = GlobalKey();

  bool _isCaptured = false;
  List<Offset>? _capturedLandmarks;
  List<String> _aiFeedback = [];
  File? _capturedFile;

  bool _isProcessing = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  bool _mirrorBaseline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) ref.read(gripLabProvider.notifier).startAnalysis();
      });
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Widget _buildNativeCameraView() {
    const String viewType = 'dao_grip_camera_view';
    const codec = StandardMessageCodec();
    if (Platform.isIOS) {
      return const UiKitView(viewType: viewType, creationParamsCodec: codec);
    } else {
      return const AndroidView(viewType: viewType, creationParamsCodec: codec);
    }
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 5;
      _isProcessing = true;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_cooldownSeconds > 0) {
          _cooldownSeconds--;
        } else {
          _isProcessing = false;
          timer.cancel();
        }
      });
    });
  }

  void _resetCapture() {
    setState(() {
      _isCaptured = false;
      _capturedLandmarks = null;
      _aiFeedback = [];
      _capturedFile = null;
    });
    ref.read(gripLabProvider.notifier).stopAnalysis();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) ref.read(gripLabProvider.notifier).startAnalysis();
    });
  }

  void _captureAndAnalyze() async {
    if (_isProcessing || _cooldownSeconds > 0) return;

    final s = AppLocalizations.of(context)!;
    final gripState = ref.read(gripLabProvider);
    final baseline = ref.read(gripBaselineProvider).baseline;

    if (gripState.isHandDetected && gripState.landmarks.length >= 21 && baseline != null) {
      _startCooldown();

      // 1. 순수 연산 기반 AI 분석 결과 도출
      final feedback = GripCoach.analyze(
        s: s,
        baseline: baseline.landmarks,
        current: gripState.landmarks,
      );

      // 먼저 상태를 변경하여 하단 결과 위젯 레이아웃(_resultCaptureKey)이 화면에 트리거되도록 유도합니다.
      setState(() {
        _isCaptured = true;
        _capturedLandmarks = List.from(gripState.landmarks);
        _aiFeedback = feedback;
      });

      try {
        final double ratio = GripSnapshotService.recommendPixelRatio(context);

        // 2. 0순위 선(先) 캡처: 상태 변화 후 하단 뷰 픽셀 바이트를 안전하게 떠냅니다.
        final file = await GripSnapshotService.captureToTempFile(
          boundaryKey: _resultCaptureKey,
          filenamePrefix: 'grip_compare',
          saveToGallery: true,
          pixelRatio: ratio,
        );

        // 3. 캡처가 온전히 확보되면 비로소 분석 네이티브 영상 스트림을 닫습니다.
        ref.read(gripLabProvider.notifier).stopAnalysis();

        if (file != null) {
          setState(() {
            _capturedFile = file;
          });
        }

      } catch (e) {
        _isProcessing = false;
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("결과 저장 도중 예외 발생: ${e.toString()}")),
          );
          // 실패 시 분석 스트림 원복 복구
          ref.read(gripLabProvider.notifier).startAnalysis();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final baselineState = ref.watch(gripBaselineProvider);
    final gripState = ref.watch(gripLabProvider);

    if (!baselineState.hasBaseline || baselineState.baseline == null) {
      return _NoBaselineView(onTake: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const GripCameraScreen()));
        await ref.read(gripBaselineProvider.notifier).fetchBaseline();
      });
    }

    final baselineModel = baselineState.baseline!;
    final bool isHandLive = gripState.isHandDetected && gripState.landmarks.length >= 21;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          _isCaptured ? s.grip_comp_result_title : s.grip_comp_title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: s.grip_comp_mirror_on,
            icon: Icon(
              Icons.flip_rounded,
              color: _mirrorBaseline ? Colors.cyanAccent : Colors.grey,
            ),
            onPressed: () {
              setState(() => _mirrorBaseline = !_mirrorBaseline);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_mirrorBaseline ? s.grip_comp_mirror_on : s.grip_comp_mirror_off),
                  duration: const Duration(milliseconds: 600),
                ),
              );
            },
          ),
          if (!_isCaptured)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
              onPressed: () => _cameraBridge.switchCamera(),
            ),
          if (_isCaptured)
            TextButton(
              onPressed: _resetCapture,
              child: Text(s.grip_comp_retake, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      // ❌ 보디 전체를 묶어 네이티브 서피스 버퍼를 깨뜨리던 외곽 RepaintBoundary 가드를 해제했습니다.
      body: _isCaptured
          ? _buildCapturedSplitView(baselineModel, gripState, s)
          : _buildLiveView(baselineModel, isHandLive, gripState, s),
    );
  }

  Widget _buildCapturedSplitView(dynamic baselineModel, dynamic gripState, AppLocalizations s) {
    if (_capturedLandmarks == null) return const SizedBox.shrink();
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildNativeCameraView(),
              Container(color: Colors.black.withOpacity(0.3)),
              CustomPaint(
                painter: GhostOverlayPainter(
                  liveLandmarks: _capturedLandmarks,
                  baselineLandmarks: baselineModel.landmarks,
                  imageWidth: gripState.imageWidth,
                  imageHeight: gripState.imageHeight,
                  fillCenter: true,
                  mirrorBaseline: _mirrorBaseline,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          // 🔥 [핵심 수정] 네이티브 서피스를 완벽히 제외하고, 순수 플러터 컨텐츠인 하단 결과 뷰 영역만 캡처 타깃으로 격리 지정합니다.
          child: RepaintBoundary(
            key: _resultCaptureKey,
            child: Container(
              color: const Color(0xFF121212),
              child: _buildResultScrollView(s),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultScrollView(AppLocalizations s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Colors.cyanAccent, size: 28),
              const SizedBox(width: 12),
              Text(s.grip_comp_ai_title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.grip_comp_info_dist,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_aiFeedback.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(s.grip_comp_no_result, style: const TextStyle(color: Colors.white54, fontSize: 16)),
            ),
          ..._aiFeedback.map((text) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.check_circle, color: Colors.greenAccent, size: 20)),
                const SizedBox(width: 14),
                Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4))),
              ],
            ),
          )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _resetCapture,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan[700],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(s.grip_comp_btn_retake, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLiveView(dynamic baselineModel, bool isHandLive, dynamic gripState, AppLocalizations s) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildNativeCameraView(),
        if (isHandLive)
          IgnorePointer(
            child: CustomPaint(
              painter: GhostOverlayPainter(
                liveLandmarks: gripState.landmarks,
                baselineLandmarks: null,
                imageWidth: gripState.imageWidth,
                imageHeight: gripState.imageHeight,
                fillCenter: true,
                mirrorBaseline: _mirrorBaseline,
              ),
            ),
          )
        else
          Center(child: Text(s.grip_comp_live_guide, style: const TextStyle(color: Colors.white54))),

        Positioned(
          top: 20, right: 20,
          child: Container(
            width: 110, height: 176,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.cyan.withOpacity(0.8), width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.black,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(baselineModel.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.error))),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      color: Colors.black.withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(s.grip_comp_baseline_label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        Center(child: CustomPaint(painter: _CrosshairPainter(), child: const SizedBox.expand())),
        Positioned(bottom: 30, left: 20, right: 20, child: _buildCaptureButton(isHandLive, s)),
      ],
    );
  }

  Widget _buildCaptureButton(bool enabled, AppLocalizations s) {
    final bool canClick = enabled && !_isProcessing && _cooldownSeconds == 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canClick)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
            child: Text(s.grip_comp_shoot_guide, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14)),
          )
        else if (_cooldownSeconds > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
            child: Text(s.grip_comp_cooldown(_cooldownSeconds.toString()), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        GestureDetector(
          onTap: () {
            if (_cooldownSeconds > 0) return;
            if (canClick) _captureAndAnalyze();
          },
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_cooldownSeconds > 0) ? Colors.grey[800] : (canClick ? Colors.white : Colors.grey[700]),
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: (_cooldownSeconds > 0)
                  ? Text("$_cooldownSeconds", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))
                  : Icon(Icons.camera_alt, color: canClick ? Colors.black : Colors.white38, size: 32),
            ),
          ),
        ),
      ],
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final horizonPaint = Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 1.0..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), horizonPaint);
    final crossPaint = Paint()..color = Colors.cyanAccent..strokeWidth = 2.0..style = PaintingStyle.stroke;
    const double crossSize = 20.0;
    canvas.drawLine(Offset(cx - crossSize, cy), Offset(cx + crossSize, cy), crossPaint);
    canvas.drawLine(Offset(cx, cy - crossSize), Offset(cx, cy + crossSize), crossPaint);
    canvas.drawCircle(Offset(cx, cy), 3.0, Paint()..color = Colors.redAccent);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _NoBaselineView extends StatelessWidget {
  final VoidCallback onTake;
  const _NoBaselineView({required this.onTake});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.grip_comp_title), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(s.grip_comp_no_baseline),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onTake, child: Text(s.grip_comp_btn_go_shoot))
          ],
        ),
      ),
    );
  }
}