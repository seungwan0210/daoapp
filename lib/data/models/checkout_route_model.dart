// lib/data/models/checkout_route_model.dart

/// 체크아웃 추천 경로 모델
/// - primary: 주 추천 루트 (예: ["T20", "T20", "D20"])
/// - alts: 대안 루트 리스트 (예: [["T19", "T19", "D16"]])
class CheckoutRoute {
  final List<String> primary;
  final List<List<String>> alts;

  const CheckoutRoute({
    required this.primary,
    this.alts = const [],
  });

  /// JSON → CheckoutRoute (Firestore 연동 시 유용)
  factory CheckoutRoute.fromJson(Map<String, dynamic> json) {
    return CheckoutRoute(
      primary: List<String>.from(json['primary'] ?? []),
      alts: (json['alts'] as List<dynamic>?)
          ?.map((e) => List<String>.from(e as List))
          .toList() ?? [],
    );
  }

  /// CheckoutRoute → JSON
  Map<String, dynamic> toJson() {
    return {
      'primary': primary,
      'alts': alts,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CheckoutRoute &&
        listEquals(primary, other.primary) &&
        listEquals(alts, other.alts);
  }

  @override
  int get hashCode => Object.hash(primary, alts);

  @override
  String toString() => 'CheckoutRoute(primary: $primary, alts: $alts)';
}

// 리스트 비교 헬퍼 (dart:ui에서 가져옴)
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}