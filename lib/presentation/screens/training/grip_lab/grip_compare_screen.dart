import 'dart:async'; // 타이머 사용
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/presentation/providers/training/grip_baseline_provider.dart';
import 'package:daoapp/presentation/providers/training/grip_lab_provider.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_camera_screen.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/widgets/ghost_overlay_painter.dart';
import 'package:daoapp/core/utils/grip_coach.dart';
// ✅ 카메라 제어 import
import 'package:daoapp/data/services/native_grip_bridge.dart';

class GripCompareScreen extends ConsumerStatefulWidget {
  const GripCompareScreen({super.key});

  @override
  ConsumerState<GripCompareScreen> createState() => _GripCompareScreenState();
}

class _GripCompareScreenState extends ConsumerState<GripCompareScreen> {
  // 🔄 카메라 전환용 브릿지
  final NativeGripBridge _cameraBridge = NativeGripBridge();

  // 📸 촬영 상태 관리
  bool _isCaptured = false;
  List<Offset>? _capturedLandmarks;
  List<String> _aiFeedback = [];

  // ⏳ 쿨다운(연타 방지) 상태 관리
  bool _isProcessing = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  // ↔️ 기준 뼈대 반전 상태
  bool _mirrorBaseline = false;

  // ✅ [중요] 화면 진입 시 분석기 강제 가동 (뼈대 사라짐 방지)
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gripLabProvider.notifier).startAnalysis();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
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

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        // 뒤로가기 시 자동 처리
      },
      child: Scaffold(
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
            // 1. 기준 뼈대 좌우 반전 버튼 (↔️)
            IconButton(
              tooltip: "기준 그립 반전",
              icon: Icon(
                Icons.flip_rounded,
                color: _mirrorBaseline ? Colors.cyanAccent : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _mirrorBaseline = !_mirrorBaseline;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_mirrorBaseline ? "기준 뼈대를 반전합니다 (거울 모드)" : "기준 뼈대를 원래대로 돌립니다"),
                    duration: const Duration(milliseconds: 800),
                  ),
                );
              },
            ),

            // 2. 카메라 전환 버튼 (촬영 전에만)
            if (!_isCaptured)
              IconButton(
                icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                onPressed: () async {
                  await _cameraBridge.switchCamera();
                },
              ),

            // 3. 재촬영 버튼 (촬영 후에만)
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
      ),
    );
  }

  // ===========================================================================
  // 🏗️ [Layout 1] 촬영 후: 상하 50:50 분할 뷰
  // ===========================================================================
  Widget _buildCapturedSplitView(dynamic baselineModel, dynamic gripState) {
    if (_capturedLandmarks == null) return const SizedBox.shrink();

    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const AndroidView(viewType: 'dao_grip_camera_view'),
                Container(color: Colors.black.withOpacity(0.3)),
                CustomPaint(
                  painter: GhostOverlayPainter(
                    liveLandmarks: _capturedLandmarks,
                    baselineLandmarks: baselineModel.landmarks,
                    imageWidth: gripState.imageWidth,
                    imageHeight: gripState.imageHeight,
                    fillCenter: true,
                    mirrorBaseline: _mirrorBaseline, // ✅ 반전 상태 전달
                  ),
                ),
              ],
            ),
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
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Colors.cyanAccent, size: 28),
              const SizedBox(width: 12),
              const Text("AI 그립 분석 결과", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
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
                const Expanded(
                  child: Text(
                    "거리 분석 기준: 손가락 마디가 아닌\n엄지 손톱 끝과 검지 손톱 끝 사이의 직선 거리를 비교합니다.",
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
              child: Text("분석된 내용이 없습니다.", style: TextStyle(color: Colors.white54, fontSize: 16)),
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
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4)),
                ),
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
                elevation: 0,
              ),
              child: const Text("다시 촬영하기", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🎥 [Layout 2] 촬영 전 뷰
  // ===========================================================================
  Widget _buildLiveView(dynamic baselineModel, bool isHandLive, dynamic gripState) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const AndroidView(viewType: 'dao_grip_camera_view'),

        if (isHandLive)
          IgnorePointer(
            child: CustomPaint(
              painter: GhostOverlayPainter(
                liveLandmarks: gripState.landmarks,
                // 라이브 뷰에서도 기준을 겹쳐보고 싶다면 baselineLandmarks 전달
                // 현재는 null로 설정됨 (PIP만 보기 위함)
                baselineLandmarks: null,
                imageWidth: gripState.imageWidth,
                imageHeight: gripState.imageHeight,
                fillCenter: true,
                mirrorBaseline: _mirrorBaseline, // ✅ 상태 전달
              ),
            ),
          )
        else
          const Center(
            child: Text("손을 카메라에 비춰주세요", style: TextStyle(color: Colors.white54)),
          ),

        // PIP (기준 사진)
        Positioned(
          top: 20, right: 20,
          child: Container(
            width: 110, height: 176,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.cyan.withOpacity(0.8), width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.black,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 기준 사진은 뒤집지 않고 그대로 보여줌 (원본 확인용)
                  Image.network(baselineModel.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.error, color: Colors.grey))),
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

        Center(
          child: CustomPaint(
            painter: _CrosshairPainter(),
            child: const SizedBox(width: double.infinity, height: double.infinity),
          ),
        ),

        Positioned(
          bottom: 30, left: 20, right: 20,
          child: _buildCaptureButton(isHandLive),
        ),
      ],
    );
  }

  // 버튼 UI
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
            child: const Text("기준 사진(우상단)과 비슷하게 잡고\n+ 중심에 맞춰 촬영하세요", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 14)),
          )
        else if (_cooldownSeconds > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
            child: Text("안정화를 위해 $_cooldownSeconds초 뒤 촬영 가능합니다", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        GestureDetector(
          onTap: () {
            if (_cooldownSeconds > 0) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("⚠️ 시스템 안정화 중입니다. $_cooldownSeconds초만 기다려주세요.")));
              return;
            }
            if (canClick) _captureAndAnalyze();
          },
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_cooldownSeconds > 0) ? Colors.grey[800] : (canClick ? Colors.white : Colors.grey[700]),
              border: Border.all(color: (_cooldownSeconds > 0) ? Colors.grey : Colors.grey[300]!, width: 4),
              boxShadow: [if (canClick) BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)],
            ),
            child: Center(
              child: (_cooldownSeconds > 0)
                  ? Text("$_cooldownSeconds", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))
                  : Icon(Icons.camera_alt, color: canClick ? Colors.black : Colors.white38, size: 32),
            ),
          ),
        ),
      ],
    );
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

      ref.read(gripLabProvider.notifier).stopAnalysis();
    }
  }

  void _resetCapture() {
    setState(() {
      _isCaptured = false;
      _capturedLandmarks = null;
      _aiFeedback = [];
    });
    ref.read(gripLabProvider.notifier).startAnalysis();
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
            ElevatedButton(onPressed: onTake, child: const Text("촬영하러 가기"))
          ],
        ),
      ),
    );
  }
}