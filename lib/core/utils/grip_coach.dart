import 'dart:math' as math;
import 'dart:ui';
import 'package:daoapp/core/utils/geometry_utils.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

/// 그립 분석 AI 코치 (다국어 지원 버전)
class GripCoach {
  static List<String> analyze({
    required AppLocalizations s, // 🔹 언어팩 인자 추가
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
      feedback.add(s.grip_coach_gap_wide);
    } else if (gapDiff < -0.03) {
      feedback.add(s.grip_coach_gap_tight);
    } else {
      feedback.add(s.grip_coach_gap_perfect);
    }

    // ===========================================================
    // 2. 손가락별 상태 분석
    // ===========================================================

    // 검지
    if (_checkFinger(s, feedback, s.grip_coach_index, baseline, current, [5, 6, 7, 8], 15.0)) {
      goodFingers.add(s.grip_coach_index);
    }

    // 중지
    if (_checkFinger(s, feedback, s.grip_coach_middle, baseline, current, [9, 10, 11, 12], 15.0)) {
      goodFingers.add(s.grip_coach_middle);
    }

    // 약지
    if (_checkFinger(s, feedback, s.grip_coach_ring, baseline, current, [13, 14, 15, 16], 20.0)) {
      goodFingers.add(s.grip_coach_ring);
    }

    // 소지 (새끼)
    if (_checkFinger(s, feedback, s.grip_coach_pinky, baseline, current, [17, 18, 19, 20], 20.0)) {
      goodFingers.add(s.grip_coach_pinky);
    }

    // ===========================================================
    // 3. 종합 결과 정리 (지적 + 칭찬)
    // ===========================================================

    // 만약 지적사항이 하나도 없다면? (체크마크로 시작하는 성공 멘트 제외)
    if (feedback.where((msg) => !msg.contains("✅")).isEmpty) {
      return [s.grip_coach_all_perfect];
    }

    // 지적사항이 있지만, 잘한 손가락도 있다면? -> 칭찬 멘트 합치기
    if (goodFingers.isNotEmpty) {
      final String goodNames = goodFingers.join(", ");
      feedback.add(s.grip_coach_good_job(goodNames));
    }

    return feedback;
  }

  /// [내부 함수] 손가락 상태 체크
  static bool _checkFinger(
      AppLocalizations s,
      List<String> feedback,
      String fingerName,
      List<Offset> baseline,
      List<Offset> current,
      List<int> indices,
      double threshold,
      ) {
    final double baseAngle = _calculateThreePointAngle(baseline[indices[0]], baseline[indices[1]], baseline[indices[3]]);
    final double curAngle = _calculateThreePointAngle(current[indices[0]], current[indices[1]], current[indices[3]]);

    final double diff = curAngle - baseAngle;

    if (diff > threshold) {
      feedback.add(s.grip_coach_finger_straight(fingerName));
      return false;
    } else if (diff < -threshold) {
      feedback.add(s.grip_coach_finger_bent(fingerName));
      return false;
    }

    return true;
  }

  static double _calculateThreePointAngle(Offset a, Offset b, Offset c) {
    final vectorBA = Offset(a.dx - b.dx, a.dy - b.dy);
    final vectorBC = Offset(c.dx - b.dx, c.dy - b.dy);

    final dotProduct = vectorBA.dx * vectorBC.dx + vectorBC.dy * vectorBA.dy;
    final magBA = math.sqrt(vectorBA.dx * vectorBA.dx + vectorBA.dy * vectorBA.dy);
    final magBC = math.sqrt(vectorBC.dx * vectorBC.dx + vectorBC.dy * vectorBC.dy);

    if (magBA * magBC == 0) return 0.0;

    final angleRad = math.acos((dotProduct / (magBA * magBC)).clamp(-1.0, 1.0));
    return angleRad * (180 / math.pi);
  }
}