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
import 'package:daoapp/l10n/app_localizations.dart';

class GripCameraScreen extends ConsumerStatefulWidget {
  const GripCameraScreen({super.key});

  @override
  ConsumerState<GripCameraScreen> createState() => _GripCameraScreenState();
}

class _GripCameraScreenState extends ConsumerState<GripCameraScreen> with WidgetsBindingObserver {
  bool _hasCameraPermission = false;
  final GlobalKey _captureKey = GlobalKey();
  bool _isSaving = false;

  final NativeGripBridge _cameraBridge = NativeGripBridge();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndStart();
    }
  }

  Future<void> _checkPermissionAndStart() async {
    var status = await Permission.camera.status;

    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    if (!mounted) return;

    final isGranted = status.isGranted;

    if (_hasCameraPermission != isGranted) {
      setState(() {
        _hasCameraPermission = isGranted;
      });
    }

    if (isGranted) {
      _startAnalysisWithDelay();
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog();
    }
  }

  void _startAnalysisWithDelay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _hasCameraPermission) {
          ref.read(gripLabProvider.notifier).startAnalysis();
        }
      });
    });
  }

  void _showPermissionDialog() {
    final s = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(s.grip_auth_camera_title),
        content: Text(s.grip_auth_camera_msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.common_cancel),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: Text(s.grip_auth_go_settings),
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
    final s = AppLocalizations.of(context)!;

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
        SnackBar(content: Text(s.grip_cam_msg_detected_only)),
      );
      return;
    }

    // ❌ [기존 버그] 여기서 stopAnalysis()를 먼저 호출하여 네이티브 카메라 버퍼가 닫히고 에러를 유발했습니다.
    // 💡 [수정] 먼저 UI 저장 중 상태(락)만 걸고 캡처 프로세스를 0순위로 진행합니다.
    setState(() => _isSaving = true);

    try {
      // 🔥 [화질 과부하 해제] 기존 3.0 고해상도 강제를 지우고, 최대 2.0으로 캡핑된 추천 배율을 적용합니다.
      final double ratio = GripSnapshotService.recommendPixelRatio(context);

      // 1️⃣ Impeller 엔진이 살아있는 영상 서피스 프레임을 메모리에 안전하게 캡처합니다.
      final File? file = await GripSnapshotService.captureToTempFile(
        boundaryKey: _captureKey,
        saveToGallery: true,
        pixelRatio: ratio,
      );

      if (file == null) throw Exception("Image capture failed");

      // 2️⃣ 비트맵 스냅샷 파일이 확실하게 확보된 것을 확인한 후, 비로소 안전하게 영상 분석 스트림을 닫습니다.
      ref.read(gripLabProvider.notifier).stopAnalysis();

      final baseline = GripBaselineModel(
        createdAt: DateTime.now(),
        imageUrl: '',
        landmarks: gripState.landmarks,
        pinchGap: gripState.pinchGap,
        indexAngle: gripState.indexAngle,
        imageWidth: imageW,
        imageHeight: imageH,
      );

      // 3️⃣ 무거운 Firebase Storage 업로드 및 Firestore 저장을 순차적으로 수행합니다.
      await ref.read(gripBaselineProvider.notifier).saveBaseline(
        imageFile: file,
        model: baseline,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.grip_cam_msg_save_success)),
        );
      }

    } catch (e) {
      // 🔥 [안전성 최적화] catch 블록 진입 시 락 상태를 무조건 해제하여 버튼 멈춤 현상을 차단합니다.
      _isSaving = false;

      if (mounted) {
        setState(() {}); // 로딩 인디케이터 해제 반영
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.grip_cam_msg_save_error(e.toString()))),
        );
        // 혹시 캡처 도중 실패했거나 예외가 터졌을 경우에만 분석 스트림을 재개합니다.
        ref.read(gripLabProvider.notifier).startAnalysis();
      }
    }
  }

  Widget _buildNativeView() {
    const String viewType = 'dao_grip_camera_view';
    const codec = StandardMessageCodec();
    if (Platform.isIOS) {
      return const UiKitView(viewType: viewType, creationParamsCodec: codec);
    } else {
      return const AndroidView(viewType: viewType, creationParamsCodec: codec);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
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
                if (_hasCameraPermission)
                  _buildNativeView()
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 20),
                        Text(
                          s.grip_cam_checking_auth,
                          style: const TextStyle(color: Colors.white),
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
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                  children: [
                    TextSpan(text: s.grip_cam_guide_center),
                    TextSpan(
                      text: s.grip_cam_guide_plus,
                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: s.grip_cam_guide_align),
                    TextSpan(
                      text: s.grip_cam_guide_horizon,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: s.grip_cam_guide_desc),
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