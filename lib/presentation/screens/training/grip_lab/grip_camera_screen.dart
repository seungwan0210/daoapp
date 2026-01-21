// lib/presentation/screens/training/grip_lab/grip_camera_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:daoapp/presentation/providers/training/grip_lab_provider.dart';
import 'package:daoapp/presentation/providers/training/grip_baseline_provider.dart';
import 'package:daoapp/data/models/grip_baseline_model.dart';
import 'package:daoapp/services/grip_snapshot_service.dart';

import 'widgets/ghost_overlay_painter.dart';

class GripCameraScreen extends ConsumerStatefulWidget {
  const GripCameraScreen({super.key});

  @override
  ConsumerState<GripCameraScreen> createState() => _GripCameraScreenState();
}

class _GripCameraScreenState extends ConsumerState<GripCameraScreen> {
  bool _hasCameraPermission = false;

  // ✅ 스냅샷 캡쳐 대상
  final GlobalKey _captureKey = GlobalKey();

  bool _isSaving = false;

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
        const SnackBar(content: Text("손이 인식된 상태에서 저장할 수 있어요.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1) 화면 스냅샷 -> File
      final File? file = await GripSnapshotService.captureToTempFile(
        boundaryKey: _captureKey,
      );

      if (file == null) {
        throw Exception("스냅샷 생성 실패");
      }

      // 2) Baseline 모델 생성 (이미지 URL은 repo가 업로드 후 채움)
      final baseline = GripBaselineModel(
        createdAt: DateTime.now(),
        imageUrl: '', // repo.saveBaseline에서 downloadUrl로 교체
        landmarks: gripState.landmarks,
        pinchGap: gripState.pinchGap,
        indexAngle: gripState.indexAngle,
        imageWidth: imageW,
        imageHeight: imageH,
      );

      // 3) 저장
      final ok = await ref.read(gripBaselineProvider.notifier).saveBaseline(
        imageFile: file,
        model: baseline,
      );

      if (!ok) {
        throw Exception("기준 저장 실패");
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ 기준 그립이 저장/업데이트 되었어요.")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("저장 실패: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gripState = ref.watch(gripLabProvider);
    final baselineState = ref.watch(gripBaselineProvider);

    // ✅ 네이티브에서 넘어온 실제 프레임 크기(회전 반영 후)
    final int imageW = gripState.imageWidth;
    final int imageH = gripState.imageHeight;

    final bool canPaintOverlay = _hasCameraPermission &&
        gripState.isHandDetected &&
        gripState.landmarks.length >= 21 &&
        imageW > 0 &&
        imageH > 0;

    final bool hasBaseline = baselineState.hasBaseline;

    return Scaffold(
      backgroundColor: Colors.black,
      body: RepaintBoundary(
        key: _captureKey, // ✅ 이 영역이 스냅샷 저장 대상
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1) 카메라 화면 (Android Native View)
            if (_hasCameraPermission)
              const AndroidView(viewType: 'dao_grip_camera_view')
            else
              const Center(
                child: Text(
                  "카메라 권한이 필요합니다",
                  style: TextStyle(color: Colors.white54),
                ),
              ),

            // 2) 안내 멘트
            if (_hasCameraPermission && !gripState.isHandDetected)
              const Center(
                child: Text(
                  "손을 카메라에 비춰주세요",
                  style: TextStyle(color: Colors.white54),
                ),
              ),

            // 3) 오버레이 (뼈대)
            IgnorePointer(
              child: CustomPaint(
                painter: canPaintOverlay
                    ? GhostOverlayPainter(
                  gripState.landmarks,
                  imageWidth: imageW,
                  imageHeight: imageH,
                  fillCenter: true,
                )
                    : null,
                child: const SizedBox.expand(),
              ),
            ),

            // 4) 하단 정보창
            Positioned(
              bottom: 96,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.70),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Pinch Gap: ${(gripState.pinchGap * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Index Angle: ${gripState.indexAngle.toStringAsFixed(1)}°",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Frame: ${imageW > 0 && imageH > 0 ? '${imageW}x$imageH' : '...'}",
                      style:
                      const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // 5) 저장 버튼 (기준 저장/업데이트)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: (_isSaving || !_hasCameraPermission)
                      ? null
                      : _saveAsBaseline,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan[600],
                    disabledBackgroundColor: Colors.cyan[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                      : Icon(
                    hasBaseline ? Icons.update : Icons.save,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isSaving
                        ? "저장 중..."
                        : (hasBaseline ? "기준 업데이트" : "기준 저장"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // 6) 뒤로가기 버튼
            Positioned(
              top: 50,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: _isSaving ? null : () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
