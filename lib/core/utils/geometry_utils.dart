import 'dart:math' as math;
import 'dart:ui';

/// [GeometryUtils] - MediaPipe Hands (Native) 버전
/// 네이티브에서 넘어온 List<Offset> (21개 점)을 받아 분석합니다.
class GeometryUtils {

  // 랜드마크 인덱스 (MediaPipe Hands 표준)
  static const int WRIST = 0;
  static const List<int> THUMB = [1, 2, 3, 4];   // CMC, MCP, IP, TIP
  static const List<int> INDEX = [5, 6, 7, 8];   // MCP, PIP, DIP, TIP
  static const List<int> MIDDLE = [9, 10, 11, 12];
  static const List<int> RING = [13, 14, 15, 16];
  static const List<int> PINKY = [17, 18, 19, 20];

  // ==========================================================
  // 1. 스케일 정규화 (손 크기에 따른 오차 제거)
  // ==========================================================

  // 손목(0) ~ 중지 뿌리(9) 길이를 기준(1.0)으로 잡음
  static double getHandScaleReference(List<Offset> landmarks) {
    if (landmarks.length < 21) return 1.0;
    return calculateDistance(landmarks[WRIST], landmarks[MIDDLE[0]]);
  }

  // 픽셀 거리를 정규화된 비율로 변환
  static double normalizeDistance(double pixelDist, double refScale) {
    if (refScale == 0) return 0;
    return pixelDist / refScale;
  }

  // ==========================================================
  // 2. 다트 그립 핵심 분석
  // ==========================================================

  // [핀치 간격] 엄지 끝(4) <-> 검지 끝(8)
  static double getPinchGapRatio(List<Offset> landmarks) {
    if (landmarks.length < 21) return 0.0;

    double scale = getHandScaleReference(landmarks);
    double dist = calculateDistance(landmarks[THUMB[3]], landmarks[INDEX[3]]);

    return normalizeDistance(dist, scale);
  }

  // [검지 굽힘 각도] MCP(5)-PIP(6)-DIP(7)
  // 180도에 가까우면 펴짐(Pencil), 90도면 굽힘(Hook/Claw)
  static double getIndexFlexionAngle(List<Offset> landmarks) {
    if (landmarks.length < 21) return 0.0;

    // 검지의 뿌리-중간-끝마디 각도
    return calculateAngle(
        landmarks[INDEX[0]],
        landmarks[INDEX[1]],
        landmarks[INDEX[2]]
    );
  }

  // ==========================================================
  // 3. 수학 공식
  // ==========================================================
  static double calculateDistance(Offset p1, Offset p2) {
    return (p1 - p2).distance;
  }

  static double calculateAngle(Offset p1, Offset p2, Offset p3) {
    final double angle1 = math.atan2(p1.dy - p2.dy, p1.dx - p2.dx);
    final double angle2 = math.atan2(p3.dy - p2.dy, p3.dx - p2.dx);

    double degree = (angle1 - angle2) * (180 / math.pi);
    if (degree < 0) degree += 360;
    if (degree > 180) degree = 360 - degree;

    return degree;
  }
}