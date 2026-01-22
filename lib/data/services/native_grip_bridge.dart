// lib/data/services/native_grip_bridge.dart
import 'package:flutter/services.dart';
import 'package:daoapp/data/models/grip_native_payload.dart';

class NativeGripBridge {
  static const EventChannel _eventChannel =
  EventChannel('com.dao.darts/grip_stream');

  // ✅ [추가] 명령 제어 채널
  static const MethodChannel _methodChannel =
  MethodChannel('com.dao.darts/grip_control');

  /// 카메라 전환 명령 (Front <-> Back)
  Future<void> switchCamera() async {
    try {
      await _methodChannel.invokeMethod('switchCamera');
    } catch (e) {
      print("❌ Camera switch failed: $e");
    }
  }

  /// 네이티브로부터 payload 스트림을 받습니다.
  Stream<GripNativePayload> get gripDataStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event is! Map) {
        return const GripNativePayload(w: 0, h: 0, landmarks: []);
      }
      final Map<dynamic, dynamic> map = event;
      final int w = ((map['w'] as num?) ?? 0).toInt();
      final int h = ((map['h'] as num?) ?? 0).toInt();
      final List<dynamic> raw =
          (map['landmarks'] as List<dynamic>?) ?? const <dynamic>[];
      final List<double> landmarks = raw
          .map((e) => (e is num) ? e.toDouble() : 0.0)
          .toList(growable: false);
      return GripNativePayload(w: w, h: h, landmarks: landmarks);
    });
  }
}