// lib/data/models/checkout_route_model.dart
/// 체크아웃 추천 경로를 나타내는 모델
/// - primary: 주요 경로 (예: ["T20", "T20", "D20"])
/// - alts: 대안 경로 (예: [["T19", "T19", "D16"]])
class CheckoutRoute {
  final List<String> primary;
  final List<List<String>> alts;

  const CheckoutRoute({
    required this.primary,
    required this.alts,
  });

  /// JSON에서 생성
  factory CheckoutRoute.fromJson(Map<String, dynamic> json) {
    return CheckoutRoute(
      primary: List<String>.from(json['primary'] ?? []),
      alts: (json['alts'] as List<dynamic>?)
          ?.map((alt) => List<String>.from(alt as List))
          .toList() ??
          [],
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'primary': primary,
      'alts': alts,
    };
  }

  @override
  String toString() => 'CheckoutRoute(primary: $primary, alts: $alts)';
}