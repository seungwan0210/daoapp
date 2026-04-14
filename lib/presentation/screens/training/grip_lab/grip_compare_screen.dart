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

class GripCompareScreen extends ConsumerStatefulWidget {
  const GripCompareScreen({super.key});

  @override
  ConsumerState<GripCompareScreen> createState() => _GripCompareScreenState();
}

class _GripCompareScreenState extends ConsumerState<GripCompareScreen> {
  final NativeGripBridge _cameraBridge = NativeGripBridge();

  bool _isCaptured = false;
  List<Offset>? _capturedLandmarks;
  List<String> _aiFeedback = [];

  bool _isProcessing = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  bool _mirrorBaseline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // iOS 네이티브 뷰 안착 대기 후 분석 시작
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
      return const UiKitView(
        viewType: viewType,
        creationParamsCodec: codec,
      );
    } else {
      return const AndroidView(
        viewType: viewType,
        creationParamsCodec: codec,
      );
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

  // ✅ 핵심 수정: 재촬영 로직 안정화
  // 시스템이 카메라 세션을 정리할 시간을 준 뒤 분석기를 재시작합니다.
  void _resetCapture() {
    setState(() {
      _isCaptured = false;
      _capturedLandmarks = null;
      _aiFeedback = [];
    });

    // 1. 먼저 명확하게 분석 중지 명령을 내립니다.
    ref.read(gripLabProvider.notifier).stopAnalysis();

    // 2. iOS 시스템이 카메라 소스를 정리하도록 약간 대기합니다 (300ms)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        // 3. 다시 분석 시작
        ref.read(gripLabProvider.notifier).startAnalysis();
      }
    });
  }

  void _captureAndAnalyze() {
    if (_isProcessing || _cooldownSeconds > 0) return;

    final gripState = ref.read(gripLabProvider);
    final baseline = ref.read(gripBaselineProvider).baseline;

    if (gripState.isHandDetected && gripState.landmarks.length >= 21 && baseline != null) {
      _startCooldown();

      final feedback = GripCoach.analyze(
        baseline: baseline.landmarks,
        current: gripState.landmarks,
      );

      setState(() {
        _isCaptured = true;
        _capturedLandmarks = List.from(gripState.landmarks);
        _aiFeedback = feedback;
      });

      // 촬영 후 분석 일시 정지
      ref.read(gripLabProvider.notifier).stopAnalysis();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          _isCaptured ? "분석 결과" : "그립 비교 촬영",
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
            tooltip: "기준 그립 반전",
            icon: Icon(
              Icons.flip_rounded,
              color: _mirrorBaseline ? Colors.cyanAccent : Colors.grey,
            ),
            onPressed: () {
              setState(() => _mirrorBaseline = !_mirrorBaseline);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_mirrorBaseline ? "기준 뼈대 반전(거울 모드)" : "기준 뼈대 원복"),
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
              child: const Text("재촬영", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isCaptured
          ? _buildCapturedSplitView(baselineModel, gripState)
          : _buildLiveView(baselineModel, isHandLive, gripState),
    );
  }

  Widget _buildCapturedSplitView(dynamic baselineModel, dynamic gripState) {
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
          child: Container(
            color: const Color(0xFF121212),
            child: _buildResultScrollView(),
          ),
        ),
      ],
    );
  }

  Widget _buildResultScrollView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: Colors.cyanAccent, size: 28),
              SizedBox(width: 12),
              Text("AI 그립 분석 결과", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
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
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.white70, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "거리 분석 기준: 엄지 손톱 끝과 검지 손톱 끝 사이의 직선 거리를 비교합니다.",
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_aiFeedback.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("분석 결과가 없습니다.", style: TextStyle(color: Colors.white54, fontSize: 16)),
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
              child: const Text("다시 촬영하기", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLiveView(dynamic baselineModel, bool isHandLive, dynamic gripState) {
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
          const Center(child: Text("손을 카메라에 비춰주세요", style: TextStyle(color: Colors.white54))),

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
                      child: const Text("기준 그립", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        Center(child: CustomPaint(painter: _CrosshairPainter(), child: const SizedBox.expand())),
        Positioned(bottom: 30, left: 20, right: 20, child: _buildCaptureButton(isHandLive)),
      ],
    );
  }

  Widget _buildCaptureButton(bool enabled) {
    final bool canClick = enabled && !_isProcessing && _cooldownSeconds == 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canClick)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
            child: const Text("기준 사진과 비슷하게 잡고\n+ 중심에 맞춰 촬영하세요", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 14)),
          )
        else if (_cooldownSeconds > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
            child: Text("$_cooldownSeconds초 뒤 촬영 가능", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      appBar: AppBar(title: const Text("그립 비교"), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("기준 그립이 없습니다."),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onTake, child: const Text("촬영하러 가기"))
          ],
        ),
      ),
    );
  }
}