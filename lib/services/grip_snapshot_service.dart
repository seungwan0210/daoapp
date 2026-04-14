import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart'; // 갤러리 저장용 패키지
import 'package:path_provider/path_provider.dart';

/// 그립 연구소 - "화면(위젯)을 이미지로 캡처"하는 서비스
///
/// ✅ 핵심 역할:
/// 1. RepaintBoundary를 캡처하여 ByteData로 변환
/// 2. 앱 내부 사용(Firebase 업로드 등)을 위해 임시 파일(Temp File) 생성
/// 3. 사용자 소장용으로 폰 갤러리(Album)에 자동 저장
class GripSnapshotService {
  const GripSnapshotService();

  /// 1. RepaintBoundary(GlobalKey)를 PNG 바이트로 캡처
  static Future<Uint8List> capturePngBytes(
      GlobalKey repaintBoundaryKey, {
        double pixelRatio = 2.0,
      }) async {
    final boundary = _getBoundary(repaintBoundaryKey);

    // 첫 프레임 등에서 boundary가 준비되지 않았을 경우 대기
    if (boundary.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    // 캡처 실행 (toImage)
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

    // ByteData 변환
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw Exception('Snapshot ByteData is null');
    }

    return data.buffer.asUint8List();
  }

  /// 2. RepaintBoundary(GlobalKey)를 ui.Image 객체로 캡처
  static Future<ui.Image> captureImage(
      GlobalKey repaintBoundaryKey, {
        double pixelRatio = 2.0,
      }) async {
    final boundary = _getBoundary(repaintBoundaryKey);

    if (boundary.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    return boundary.toImage(pixelRatio: pixelRatio);
  }

  /// ✅ 3. 핵심 함수: 캡처 -> 임시 파일 저장 -> (옵션) 갤러리 저장 -> File 반환
  /// [pixelRatio]를 낮게(예: 1.5 ~ 2.0) 설정하면 저장 속도가 매우 빨라집니다.
  static Future<File?> captureToTempFile({
    required GlobalKey boundaryKey,
    double? pixelRatio, // 외부에서 속도 조절을 위해 값을 주입받음
    String filenamePrefix = 'grip_baseline',
    bool saveToGallery = true,
  }) async {
    try {
      // A. 해상도(Ratio) 결정 로직
      // 외부에서 pixelRatio를 지정했으면 그걸 쓰고, 아니면 기기 해상도에 맞춰 자동 계산
      double ratio;
      if (pixelRatio != null) {
        ratio = pixelRatio;
      } else {
        final ctx = boundaryKey.currentContext;
        ratio = (ctx != null) ? recommendPixelRatio(ctx) : 2.0;
      }

      // B. 화면 캡처 수행
      final bytes = await capturePngBytes(boundaryKey, pixelRatio: ratio);

      // C. 임시 디렉토리에 파일 생성
      final dir = await getTemporaryDirectory();
      final name = '${filenamePrefix}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$name');

      await file.writeAsBytes(bytes, flush: true);

      // D. 갤러리 저장 (비동기 처리 가능하지만, 안정성을 위해 await 권장)
      if (saveToGallery) {
        await _saveToGallery(file.path);
      }

      return file;
    } catch (e) {
      debugPrint("❌ GripSnapshotService Error: $e");
      return null;
    }
  }

  /// [Internal] 갤러리 저장 로직
  static Future<void> _saveToGallery(String filePath) async {
    try {
      // 권한 확인
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          debugPrint("⚠️ 갤러리 접근 권한 거부됨");
          return;
        }
      }

      // 갤러리에 저장 (앨범명: DAO Darts)
      await Gal.putImage(filePath, album: "DAO Darts");
      debugPrint("✅ 갤러리 저장 완료: DAO Darts 앨범");

    } catch (e) {
      // 갤러리 저장이 실패해도 메인 플로우(임시파일 반환)는 방해하지 않음
      debugPrint("⚠️ 갤러리 저장 실패: $e");
    }
  }

  /// [Internal] Boundary 찾기
  static RenderRepaintBoundary _getBoundary(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) {
      throw Exception('RepaintBoundary context is null (Key not mounted)');
    }

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw Exception(
        'Target is not RenderRepaintBoundary. Wrap your widget with RepaintBoundary(key: ...).',
      );
    }

    return renderObject;
  }

  /// [Internal] 적절한 픽셀 비율 추천
  /// 너무 고해상도(3.0 이상)는 처리 속도가 느리므로 적절히 제한합니다.
  static double recommendPixelRatio(BuildContext context) {
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
    // 안정성과 속도를 위해 최대 2.5 정도로 제한하는 것을 추천
    return dpr.clamp(1.5, 2.5);
  }
}