import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:daoapp/presentation/providers/training/grip_lab_provider.dart';
import 'package:daoapp/presentation/providers/training/grip_baseline_provider.dart';
import 'package:daoapp/data/models/grip_baseline_model.dart';
import 'package:daoapp/services/grip_snapshot_service.dart';
import 'package:daoapp/data/services/native_grip_bridge.dart'; // [New] 카메라 전환용
import 'widgets/ghost_overlay_painter.dart';

class GripCameraScreen extends ConsumerStatefulWidget {
  const GripCameraScreen({super.key});

  @override
  ConsumerState<GripCameraScreen> createState() => _GripCameraScreenState();
}

class _GripCameraScreenState extends ConsumerState<GripCameraScreen> {
  bool _hasCameraPermission = false;
  final GlobalKey _captureKey = GlobalKey();
  bool _isSaving = false;

  // 🔄 [New] 카메라 브릿지 인스턴스 (전환 명령용)
  final NativeGripBridge _cameraBridge = NativeGripBridge();

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() => _hasCameraPermission = status.isGranted);
  }

  // 🔄 [New] 카메라 전환 함수
  Future<void> _switchCamera() async {
    await _cameraBridge.switchCamera();
  }

  Future<void> _saveAsBaseline() async {
    if (_isSaving) return;

    final gripState = ref.read(gripLabProvider);
    final int imageW = gripState.imageWidth;
    final int imageH = gripState.imageHeight;

    final bool canSave = _hasCameraPermission &&
        gripState.isHandDetected &&
        gripState.landmarks.length >= 21 &&
        imageW > 0 &&
        imageH > 0;

    if (!canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("손이 인식된 상태에서만 촬영할 수 있어요.")),
      );
      return;
    }

    // 🛑 [중요] 저장 시작 전, 무거운 AI 분석기 강제 중지! (튕김 방지)
    ref.read(gripLabProvider.notifier).stopAnalysis();

    setState(() => _isSaving = true);

    try {
      final double pixelRatio = MediaQuery.of(context).devicePixelRatio > 2.0
          ? 2.0
          : MediaQuery.of(context).devicePixelRatio;

      final File? file = await GripSnapshotService.captureToTempFile(
        boundaryKey: _captureKey,
        saveToGallery: true,
        pixelRatio: pixelRatio,
      );

      if (file == null) throw Exception("이미지 캡처 실패");

      // 🚀 낙관적 UI: 화면 먼저 닫기
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ 기준 그립을 저장합니다 (백그라운드)")),
        );
      }

      final baseline = GripBaselineModel(
        createdAt: DateTime.now(),
        imageUrl: '',
        landmarks: gripState.landmarks,
        pinchGap: gripState.pinchGap,
        indexAngle: gripState.indexAngle,
        imageWidth: imageW,
        imageHeight: imageH,
      );

      await ref.read(gripBaselineProvider.notifier).saveBaseline(
        imageFile: file,
        model: baseline,
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("저장 중 오류 발생: $e")),
        );
        // 에러 나면 다시 분석기 켜줘야 함
        ref.read(gripLabProvider.notifier).startAnalysis();
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gripState = ref.watch(gripLabProvider);

    final bool isHandReady = _hasCameraPermission &&
        gripState.isHandDetected &&
        gripState.landmarks.length >= 21;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 카메라 + 오버레이 영역 (캡처 대상)
          RepaintBoundary(
            key: _captureKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_hasCameraPermission)
                  const AndroidView(viewType: 'dao_grip_camera_view')
                else
                  const Center(child: Text("카메라 권한이 필요합니다", style: TextStyle(color: Colors.white))),

                IgnorePointer(
                  child: CustomPaint(
                    painter: isHandReady
                        ? GhostOverlayPainter(
                      liveLandmarks: gripState.landmarks,
                      baselineLandmarks: null,
                      imageWidth: gripState.imageWidth,
                      imageHeight: gripState.imageHeight,
                      fillCenter: true,
                    )
                        : null,
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),

          // 2. 십자선 가이드
          Center(
            child: CustomPaint(
              painter: _CrosshairPainter(),
              child: const SizedBox(width: double.infinity, height: double.infinity),
            ),
          ),

          // 3. 상단 안내 박스
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                      children: [
                        TextSpan(text: "엄지와 검지를 "),
                        TextSpan(text: "+ 중심", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                        TextSpan(text: "에 맞추고\n"),
                        TextSpan(text: "가로선 ― ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        TextSpan(text: "을 보며 다트의 각도(수평)를 확인하세요"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. 뒤로가기 버튼 (좌측 상단)
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: _isSaving ? null : () => Navigator.pop(context),
              ),
            ),
          ),

          // 🔄 [New] 카메라 전환 버튼 (우측 상단)
          Positioned(
            top: 50,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 22),
                onPressed: _isSaving ? null : _switchCamera,
              ),
            ),
          ),

          // 5. 하단 셔터 버튼
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: _ShutterButton(
                isEnabled: isHandReady && !_isSaving,
                isSaving: _isSaving,
                onTap: _saveAsBaseline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ... Painter, Button 위젯 (기존 동일)
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

class _ShutterButton extends StatelessWidget {
  final bool isEnabled;
  final bool isSaving;
  final VoidCallback onTap;
  const _ShutterButton({required this.isEnabled, required this.isSaving, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 5), color: Colors.transparent,
        ),
        child: Center(
          child: isSaving
              ? const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Container(
            width: 64, height: 64,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isEnabled ? Colors.white : Colors.grey.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }
}