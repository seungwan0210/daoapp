// lib/presentation/providers/training/grip_lab_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/data/services/native_grip_bridge.dart';
import 'package:daoapp/data/models/grip_native_payload.dart';
import 'package:daoapp/core/utils/geometry_utils.dart';
import 'package:daoapp/core/utils/landmark_smoother.dart';

// 상태 클래스
class GripState {
  final List<Offset> landmarks;
  final double pinchGap;
  final double indexAngle;
  final bool isHandDetected;
  final int imageWidth;
  final int imageHeight;

  const GripState({
    this.landmarks = const <Offset>[],
    this.pinchGap = 0.0,
    this.indexAngle = 0.0,
    this.isHandDetected = false,
    this.imageWidth = 0,
    this.imageHeight = 0,
  });

  GripState copyWith({
    List<Offset>? landmarks,
    double? pinchGap,
    double? indexAngle,
    bool? isHandDetected,
    int? imageWidth,
    int? imageHeight,
  }) {
    return GripState(
      landmarks: landmarks ?? this.landmarks,
      pinchGap: pinchGap ?? this.pinchGap,
      indexAngle: indexAngle ?? this.indexAngle,
      isHandDetected: isHandDetected ?? this.isHandDetected,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
    );
  }
}

// Provider 정의
final gripLabProvider = StateNotifierProvider<GripLabNotifier, GripState>((ref) {
  return GripLabNotifier();
});

// Notifier 구현
class GripLabNotifier extends StateNotifier<GripState> {
  final NativeGripBridge _bridge = NativeGripBridge();
  StreamSubscription<GripNativePayload>? _sub;
  final LandmarkSmoother _smoother = LandmarkSmoother(alpha: 0.6);

  static const int _minUpdateIntervalMs = 33; // 약 30fps
  int _lastUpdateMs = 0;

  GripLabNotifier() : super(const GripState()) {
    startAnalysis(); // 초기화 시 자동 시작
  }

  /// ▶️ 분석 시작 (스트림 구독)
  void startAnalysis() {
    if (_sub != null) return; // 이미 실행 중이면 패스

    debugPrint("🚀 GripLab: Analysis Started");
    _sub = _bridge.gripDataStream.listen(
          (payload) {
        if (!mounted) return;

        try {
          // 데이터 유효성 체크
          if (!payload.isValid) {
            if (state.isHandDetected) {
              _smoother.reset();
              state = state.copyWith(isHandDetected: false);
            }
            return;
          }

          // FPS 제한
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - _lastUpdateMs < _minUpdateIntervalMs) return;
          _lastUpdateMs = now;

          final data = payload.landmarks;
          if (data.length < 63) {
            state = state.copyWith(isHandDetected: false);
            return;
          }

          // 좌표 변환
          final List<Offset> rawPoints = <Offset>[];
          for (int i = 0; i < 63; i += 3) {
            rawPoints.add(Offset(data[i], data[i + 1]));
          }
          final List<Offset> smoothedPoints = _smoother.smooth(rawPoints);

          // 수치 계산
          final double gap = GeometryUtils.getPinchGapRatio(smoothedPoints);
          final double angle = GeometryUtils.getIndexFlexionAngle(smoothedPoints);

          state = GripState(
            landmarks: smoothedPoints,
            pinchGap: gap,
            indexAngle: angle,
            isHandDetected: true,
            imageWidth: payload.w,
            imageHeight: payload.h,
          );
        } catch (e) {
          debugPrint("⚠️ Grip Stream Error: $e");
        }
      },
      onError: (e) {
        debugPrint("❌ Grip Stream Fatal Error: $e");
      },
    );
  }

  /// ⏸️ 분석 일시정지 (스트림 해제)
  void stopAnalysis() {
    debugPrint("zzz GripLab: Analysis Paused");
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    stopAnalysis();
    super.dispose();
  }
}