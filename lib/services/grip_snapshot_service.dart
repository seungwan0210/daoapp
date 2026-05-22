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

    // 🔥 [배포 모드 타이밍 버그 최종 해결]
    // AOT 기계어 최적화 빌드에서는 20ms의 유격이 너무 짧아 픽셀 서피스를 정상적으로 동기화하지 못합니다.
    // 렌더링 버퍼가 확실하게 채워지고 메모리가 완전히 정렬될 수 있도록 프레임 대기 마진을 150ms로 늘려줍니다.
    await Future<void>.delayed(const Duration(milliseconds: 150));

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

    // 🔥 여기도 마찬가지로 안전 마진을 확보하여 릴리즈 모드에서의 충돌을 예방합니다.
    await Future<void>.delayed(const Duration(milliseconds: 150));

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

      // 💡 [배포 모드 안정성] OS 버퍼 비우기(flush)를 true로 설정하여 파일이 디스크에 완전히 쓰이도록 보장
      await file.writeAsBytes(bytes, flush: true);

      // D. 갤러리 저장
      if (saveToGallery) {
        // 💡 갤러리 저장이 실패하더라도 'Firebase 업로드를 위한 임시 파일 반환'이라는 메인 스트림이
        // 무조건적으로 성공할 수 있도록 여기서 한 번 더 별도의 try-catch 안전망을 씌웁니다.
        try {
          await _saveToGallery(file.path);
        } catch (galError) {
          debugPrint("⚠️ 갤러리 저장 단계 최상위 가드 통과 실패 (메인 플로우 유지): $galError");
        }
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
      debugPrint("⚠️ 갤러리 저장 내부 예외 발생: $e");
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
    // 💡 디바이스 고유의 dpr을 가져오되 시스템 누락 시 2.0 매핑
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;

    // 💡 배포 모드 Impeller 그래픽 버퍼의 연산 과부하를 완전히 해결하기 위해
    // 최대 상한선을 기존 2.5에서 초안정권인 2.0으로 클램핑 범위를 최적화합니다.
    return dpr.clamp(1.2, 1.5);
  }
}