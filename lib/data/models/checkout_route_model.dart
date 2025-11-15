// lib/data/models/checkout_route_model.dart

/// 체크아웃 한 루트(경로)를 표현하는 모델
/// 예: ["T20", "T20", "D20"]
/// alts는 같은 점수에서의 다른 루트들을 넣을 때 사용
class CheckoutRoute {
  final List<String> primary;        // 메인 루트
  final List<List<String>> alts;     // 대체 루트들

  const CheckoutRoute({
    required this.primary,
    this.alts = const [],
  });
}
