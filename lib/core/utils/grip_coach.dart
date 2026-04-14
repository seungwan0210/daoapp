import 'dart:math' as math;
import 'dart:ui';
import 'package:daoapp/core/utils/geometry_utils.dart';

/// 그립 분석 AI 코치 (칭찬 기능 추가 버전)
class GripCoach {
  static List<String> analyze({
    required List<Offset> baseline,
    required List<Offset> current,
  }) {
    final List<String> feedback = [];       // 지적 사항 (Warning)
    final List<String> goodFingers = [];    // 칭찬할 손가락들 (Good)

    // ===========================================================
    // 1. 엄지-검지 거리 (핀치 간격)
    // ===========================================================
    final double baseGap = GeometryUtils.getPinchGapRatio(baseline);
    final double curGap = GeometryUtils.getPinchGapRatio(current);
    final double gapDiff = curGap - baseGap;

    if (gapDiff > 0.03) {
      feedback.add("↔️ [그립 너비] 엄지-검지가 기준보다 멉니다.");
    } else if (gapDiff < -0.03) {
      feedback.add("-><- [그립 너비] 엄지-검지가 기준보다 가깝습니다.");
    } else {
      // 핀치 간격이 좋으면 칭찬 리스트가 아니라 별도 멘트 추가 (중요하니까)
      feedback.add("✅ [그립 너비] 엄지와 검지 간격이 완벽합니다!");
    }

    // ===========================================================
    // 2. 손가락별 상태 분석 (리턴값: 문제 없으면 true)
    // ===========================================================

    // 검지
    if (_checkFinger(feedback, "검지", baseline, current, [5, 6, 7, 8], 15.0)) {
      goodFingers.add("검지");
    }

    // 중지
    if (_checkFinger(feedback, "중지", baseline, current, [9, 10, 11, 12], 15.0)) {
      goodFingers.add("중지");
    }

    // 약지
    if (_checkFinger(feedback, "약지", baseline, current, [13, 14, 15, 16], 20.0)) {
      goodFingers.add("약지");
    }

    // 소지
    if (_checkFinger(feedback, "새끼", baseline, current, [17, 18, 19, 20], 20.0)) {
      goodFingers.add("새끼손가락");
    }

    // ===========================================================
    // 3. 종합 결과 정리 (지적 + 칭찬)
    // ===========================================================

    // 만약 지적사항이 하나도 없다면?
    if (feedback.where((s) => !s.startsWith("✅")).isEmpty) {
      return ["🎉 완벽합니다! 모든 손가락이 기준 그립과 일치합니다."];
    }

    // 지적사항이 있지만, 잘한 손가락도 있다면? -> 칭찬 멘트 합치기
    if (goodFingers.isNotEmpty) {
      // 예: "중지, 약지, 새끼손가락은 기준과 잘 맞습니다."
      final String goodNames = goodFingers.join(", ");
      feedback.add("🆗 $goodNames의 모양은 기준과 잘 맞습니다.");
    }

    return feedback;
  }

  /// [내부 함수] 손가락 상태 체크
  /// 반환값: 문제가 없으면(Good) true, 문제가 있으면 false
  static bool _checkFinger(
      List<String> feedback,
      String fingerName,
      List<Offset> baseline,
      List<Offset> current,
      List<int> indices,
      double threshold,
      ) {
    // 세 점 각도 계산
    final double baseAngle = _calculateThreePointAngle(baseline[indices[0]], baseline[indices[1]], baseline[indices[3]]);
    final double curAngle = _calculateThreePointAngle(current[indices[0]], current[indices[1]], current[indices[3]]);

    final double diff = curAngle - baseAngle;

    if (diff > threshold) {
      feedback.add("☝️ [$fingerName] 기준보다 더 펴졌습니다.");
      return false; // 문제 있음
    } else if (diff < -threshold) {
      feedback.add("✊ [$fingerName] 기준보다 더 구부러졌습니다.");
      return false; // 문제 있음
    }

    return true; // 문제 없음 (Good)
  }

  /// 각도 계산 헬퍼
  static double _calculateThreePointAngle(Offset a, Offset b, Offset c) {
    final vectorBA = Offset(a.dx - b.dx, a.dy - b.dy);
    final vectorBC = Offset(c.dx - b.dx, c.dy - b.dy);

    final dotProduct = vectorBA.dx * vectorBC.dx + vectorBA.dy * vectorBC.dy;
    final magBA = math.sqrt(vectorBA.dx * vectorBA.dx + vectorBA.dy * vectorBA.dy);
    final magBC = math.sqrt(vectorBC.dx * vectorBC.dx + vectorBC.dy * vectorBC.dy);

    if (magBA * magBC == 0) return 0.0;

    final angleRad = math.acos((dotProduct / (magBA * magBC)).clamp(-1.0, 1.0));
    return angleRad * (180 / math.pi);
  }
}