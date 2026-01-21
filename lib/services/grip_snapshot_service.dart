// lib/services/grip_snapshot_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// 그립 연구소 - "화면(위젯)을 이미지로 캡처"하는 서비스
///
/// ✅ 핵심:
/// - 반드시 import 'package:flutter/rendering.dart';
/// - 반드시 import 'dart:ui' as ui;
class GripSnapshotService {
  const GripSnapshotService();

  /// RepaintBoundary(GlobalKey)를 PNG 바이트로 캡처
  static Future<Uint8List> capturePngBytes(
      GlobalKey repaintBoundaryKey, {
        double pixelRatio = 2.0,
      }) async {
    final boundary = _getBoundary(repaintBoundaryKey);

    // 첫 프레임에서 boundary가 아직 그려지기 전이면 실패할 수 있음
    if (boundary.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

    // ✅ ByteData 타입을 노출하지 않고 안전하게 처리
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw Exception('snapshot byteData is null');
    }

    return data.buffer.asUint8List();
  }

  /// RepaintBoundary(GlobalKey)를 ui.Image로 캡처
  static Future<ui.Image> captureImage(
      GlobalKey repaintBoundaryKey, {
        double pixelRatio = 2.0,
      }) async {
    final boundary = _getBoundary(repaintBoundaryKey);

    if (boundary.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    return boundary.toImage(pixelRatio: pixelRatio);
  }

  /// ✅ 가장 많이 쓸 함수: RepaintBoundary를 PNG로 캡처해서 "임시 파일"로 저장 후 File 반환
  static Future<File?> captureToTempFile({
    required GlobalKey boundaryKey,
    double? pixelRatio,
    String filenamePrefix = 'grip_baseline',
  }) async {
    try {
      double ratio = pixelRatio ?? 2.0;

      final ctx = boundaryKey.currentContext;
      if (ctx != null && pixelRatio == null) {
        ratio = recommendPixelRatio(ctx);
      }

      final bytes = await capturePngBytes(boundaryKey, pixelRatio: ratio);

      final dir = await getTemporaryDirectory();
      final name =
          '${filenamePrefix}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$name');

      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      // 캡처 실패는 null (UI에서 안내)
      return null;
    }
  }

  /// 캡처 안전장치: boundary를 못 찾으면 명확한 에러
  static RenderRepaintBoundary _getBoundary(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) {
      throw Exception('RepaintBoundary context is null (key not mounted)');
    }

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw Exception(
        'RenderObject is not RenderRepaintBoundary. '
            'Did you wrap target widget with RepaintBoundary(key: ...)?',
      );
    }

    return renderObject;
  }

  /// (선택) 캡처 전에 다음 프레임까지 기다리기
  static Future<void> waitNextFrame() async {
    await Future<void>.delayed(const Duration(milliseconds: 16));
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }

  /// (선택) 캡처 결과가 너무 무겁지 않게 픽셀비율 자동 결정
  static double recommendPixelRatio(BuildContext context) {
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
    return dpr.clamp(1.5, 3.0);
  }
}
