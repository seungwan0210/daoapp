//lib/core/utils/landmark_smoother.dart
import 'dart:ui';

/// 미디어파이프 랜드마크의 떨림(Jitter)을 보정하는 스무딩 클래스
///
/// 알고리즘: 지수 이동 평균 (Exponential Moving Average, EMA)
/// 효과: 이전 프레임의 좌표와 현재 좌표를 적절히 섞어 움직임을 부드럽게 만듦
class LandmarkSmoother {
  /// 이전 프레임의 스무딩된 좌표 저장소
  List<Offset>? _prevLandmarks;

  /// 스무딩 강도 (Alpha)
  /// - 범위: 0.0 ~ 1.0
  /// - 특징:
  ///   * 1.0에 가까움: 반응속도 빠름 / 떨림 보정 약함 (원본 그대로)
  ///   * 0.0에 가까움: 반응속도 느림(물속 느낌) / 떨림 보정 강함
  /// - 추천값: 0.5 ~ 0.7 (다트 그립처럼 정적인 자세는 0.6 정도가 적당)
  final double alpha;

  LandmarkSmoother({this.alpha = 0.6});

  /// 현재 들어온 랜드마크(raw data)를 부드럽게 변환하여 반환
  List<Offset> smooth(List<Offset> current) {
    // 1. 첫 프레임이거나, 손이 바뀌어서 포인트 개수가 달라지면 초기화 (그대로 반환)
    if (_prevLandmarks == null || _prevLandmarks!.length != current.length) {
      _prevLandmarks = current;
      return current;
    }

    final List<Offset> smoothedResults = [];

    // 2. 모든 관절 포인트(21개)에 대해 루프를 돌며 보정
    for (int i = 0; i < current.length; i++) {
      final Offset prev = _prevLandmarks![i];
      final Offset cur = current[i];

      // EMA 공식: 결과 = (현재값 * alpha) + (이전값 * (1 - alpha))
      final double newX = cur.dx * alpha + prev.dx * (1 - alpha);
      final double newY = cur.dy * alpha + prev.dy * (1 - alpha);

      smoothedResults.add(Offset(newX, newY));
    }

    // 3. 현재 계산된 값을 다음 프레임을 위해 저장
    _prevLandmarks = smoothedResults;

    return smoothedResults;
  }

  /// 손이 화면에서 사라졌거나 인식이 끊겼을 때 호출하여 리셋
  void reset() {
    _prevLandmarks = null;
  }
}