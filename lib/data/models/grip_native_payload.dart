/// 네이티브에서 전달되는 그립 데이터 payload
/// 형식: { "w": int, "h": int, "landmarks": List<double>(63) }
class GripNativePayload {
  final int w;
  final int h;
  final List<double> landmarks;

  const GripNativePayload({
    required this.w,
    required this.h,
    required this.landmarks,
  });

  bool get isValid => w > 0 && h > 0 && landmarks.length >= 63;
}
