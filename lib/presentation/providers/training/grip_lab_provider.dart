// lib/presentation/providers/training/grip_lab_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/data/services/native_grip_bridge.dart';
import 'package:daoapp/data/models/grip_native_payload.dart';
import 'package:daoapp/core/utils/geometry_utils.dart';

/// 상태 관리용 데이터 모델
class GripState {
  /// 0.0~1.0 정규화 좌표(네이티브 기준)
  final List<Offset> landmarks;

  /// 핀치 간격 비율
  final double pinchGap;

  /// 검지 굽힘 각도
  final double indexAngle;

  /// 손 감지 여부
  final bool isHandDetected;

  /// ✅ 네이티브 분석 프레임 실제 크기(회전 반영 후)
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

/// 프로바이더
final gripLabProvider = StateNotifierProvider<GripLabNotifier, GripState>((ref) {
  return GripLabNotifier();
});

class GripLabNotifier extends StateNotifier<GripState> {
  final NativeGripBridge _bridge = NativeGripBridge();
  StreamSubscription<GripNativePayload>? _sub;

  /// ✅ 너무 자주 state 갱신하면 CustomPaint 리빌드 폭발할 수 있어서 간단 throttle
  static const int _minUpdateIntervalMs = 33; // ~30fps
  int _lastUpdateMs = 0;

  GripLabNotifier() : super(const GripState()) {
    _initStream();
  }

  void _initStream() {
    debugPrint("✅ GripLabNotifier: stream subscribe start");

    _sub = _bridge.gripDataStream.listen(
          (payload) {
        if (!payload.isValid) {
          if (state.isHandDetected) {
            state = state.copyWith(isHandDetected: false);
          }
          return;
        }

        // ✅ 간단 throttle (성능 안정)
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastUpdateMs < _minUpdateIntervalMs) return;
        _lastUpdateMs = now;

        final data = payload.landmarks;

        // 방어: 길이가 모자라면 종료
        if (data.length < 63) {
          state = state.copyWith(isHandDetected: false);
          return;
        }

        // 1) Raw [x,y,z] -> List<Offset>
        final List<Offset> points = <Offset>[];
        for (int i = 0; i < 63; i += 3) {
          points.add(Offset(data[i], data[i + 1])); // z는 무시
        }

        // 2) 수치 계산
        final double gap = GeometryUtils.getPinchGapRatio(points);
        final double angle = GeometryUtils.getIndexFlexionAngle(points);

        // 3) 상태 업데이트 (✅ w/h 포함)
        state = GripState(
          landmarks: points,
          pinchGap: gap,
          indexAngle: angle,
          isHandDetected: true,
          imageWidth: payload.w,
          imageHeight: payload.h,
        );
      },
      onError: (e, st) {
        debugPrint("❌ grip stream error: $e");
        if (mounted) {
          state = state.copyWith(isHandDetected: false);
        }
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    super.dispose();
  }
}
