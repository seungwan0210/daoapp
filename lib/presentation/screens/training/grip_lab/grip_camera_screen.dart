import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:daoapp/presentation/providers/training/grip_lab_provider.dart';
import 'package:daoapp/presentation/providers/training/grip_baseline_provider.dart';
import 'package:daoapp/data/models/grip_baseline_model.dart';
import 'package:daoapp/services/grip_snapshot_service.dart';
import 'package:daoapp/data/services/native_grip_bridge.dart';
import 'widgets/ghost_overlay_painter.dart';

class GripCameraScreen extends ConsumerStatefulWidget {
  const GripCameraScreen({super.key});

  @override
  ConsumerState<GripCameraScreen> createState() => _GripCameraScreenState();
}

// ✅ WidgetsBindingObserver를 추가하여 앱의 포커스 상태 변화를 감지합니다.
class _GripCameraScreenState extends ConsumerState<GripCameraScreen> with WidgetsBindingObserver {
  bool _hasCameraPermission = false;
  final GlobalKey _captureKey = GlobalKey();
  bool _isSaving = false;

  final NativeGripBridge _cameraBridge = NativeGripBridge();

  @override
  void initState() {
    super.initState();
    // 💡 옵저버 등록: 사용자가 설정창에 갔다가 돌아오는 것을 감지하기 위함
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndStart();
  }

  @override
  void dispose() {
    // 💡 옵저버 해제
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ 사용자가 설정 화면에서 권한을 바꾸고 앱으로 돌아오면 자동으로 실행됩니다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndStart();
    }
  }

  // ✅ 핵심 수정: 권한 상태를 확인하고 시스템과 동기화합니다.
  Future<void> _checkPermissionAndStart() async {
    var status = await Permission.camera.status;

    // 만약 거부 상태라면 명시적으로 요청 (처음 진입 시)
    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    if (!mounted) return;

    // 허용 여부에 따라 UI 상태 업데이트
    final isGranted = status.isGranted;
    
    // 상태가 변경되었을 때만 업데이트하여 불필요한 빌드 방지
    if (_hasCameraPermission != isGranted) {
      setState(() {
        _hasCameraPermission = isGranted;
      });
    }

    if (isGranted) {
      _startAnalysisWithDelay();
    } else if (status.isPermanentlyDenied) {
      // 완전히 거부된 경우 설정창 유도
      _showPermissionDialog();
    }
  }

  // 💡 네이티브 뷰가 빌드될 시간을 충분히 준 뒤 분석을 시작합니다.
  void _startAnalysisWithDelay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _hasCameraPermission) {
          ref.read(gripLabProvider.notifier).startAnalysis();
        }
      });
    });
  }

  // 🔒 설정 앱 이동 유도 다이얼로그
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("카메라 권한 필요"),
        content: const Text("설정에서 카메라 권한을 허용해야 그립 분석 기능을 사용할 수 있습니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text("설정으로 이동"),
          ),
        ],
      ),
    );
  }

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

    ref.read(gripLabProvider.notifier).stopAnalysis();
    setState(() => _isSaving = true);

    try {
      final double pixelRatio = MediaQuery.of(context).devicePixelRatio > 3.0
          ? 3.0
          : MediaQuery.of(context).devicePixelRatio;

      final File? file = await GripSnapshotService.captureToTempFile(
        boundaryKey: _captureKey,
        saveToGallery: true,
        pixelRatio: pixelRatio,
      );

      if (file == null) throw Exception("이미지 캡처 실패");

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

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ 기준 그립 저장 완료!")),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("저장 중 오류 발생: $e")),
        );
        ref.read(gripLabProvider.notifier).startAnalysis();
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildNativeView() {
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
          RepaintBoundary(
            key: _captureKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 💡 권한이 확실히 허용된 경우에만 네이티브 뷰를 빌드
                if (_hasCameraPermission)
                  _buildNativeView()
                else
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 20),
                        Text(
                          "카메라 권한을 확인하고 있습니다...",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),

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

          Center(
            child: CustomPaint(
              painter: _CrosshairPainter(),
              child: const SizedBox.expand(),
            ),
          ),

          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
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
                    TextSpan(
                      text: "+ 중심",
                      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: "에 맞추고\n"),
                    TextSpan(
                      text: "가로선 ― ",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: "을 보며 다트의 각도(수평)를 확인하세요"),
                  ],
                ),
              ),
            ),
          ),

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
        width: 80, height: 80,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 5)),
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