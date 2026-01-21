// lib/data/services/native_grip_bridge.dart
import 'package:flutter/services.dart';
import 'package:daoapp/data/models/grip_native_payload.dart';

class NativeGripBridge {
  static const EventChannel _eventChannel =
  EventChannel('com.dao.darts/grip_stream');

  /// 네이티브로부터 payload 스트림을 받습니다.
  /// payload: { w: int, h: int, landmarks: List<double>(63) }
  Stream<GripNativePayload> get gripDataStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      // ✅ 타입 방어 (크래시 방지)
      if (event is! Map) {
        return const GripNativePayload(w: 0, h: 0, landmarks: []);
      }

      final Map<dynamic, dynamic> map = event;

      // ✅ int/num 혼재 방어 (일부 기기에서 num으로 올 수 있음)
      final int w = ((map['w'] as num?) ?? 0).toInt();
      final int h = ((map['h'] as num?) ?? 0).toInt();

      final List<dynamic> raw =
          (map['landmarks'] as List<dynamic>?) ?? const <dynamic>[];

      // ✅ num -> double 변환 방어
      final List<double> landmarks = raw
          .map((e) => (e is num) ? e.toDouble() : 0.0)
          .toList(growable: false);

      return GripNativePayload(
        w: w,
        h: h,
        landmarks: landmarks,
      );
    });
  }
}
