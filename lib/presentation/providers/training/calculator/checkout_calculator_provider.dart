import 'package:flutter/foundation.dart';
import 'package:daoapp/core/constants/checkout_table.dart';
import 'package:daoapp/data/models/checkout_route_model.dart';

/// ✅ 서큐레이터(체크아웃 계산기) 전용 Provider
/// - 숫자 입력(차감)
/// - 되돌리기(undo)
/// - 추천 루트(primary + alts 전체 표시)
class CheckoutCalculatorProvider extends ChangeNotifier {
  /// 남은 점수
  int remainingScore = 0;

  /// 추천 루트들 (현재 점수 기준)
  /// checkoutTable 구조상 "점수 1개 -> CheckoutRoute 1개"라서 보통 0~1개만 들어감
  List<CheckoutRoute> routes = [];

  /// 되돌리기용 히스토리 (차감한 점수 기록)
  final List<int> _history = [];
  List<int> get history => List.unmodifiable(_history);

  bool get canUndo => _history.isNotEmpty;

  /// 계산기 시작 점수 세팅
  void setInitialScore(int score) {
    remainingScore = score.clamp(0, 999);
    _history.clear();
    _updateRoutes();
  }

  /// 점수 차감 (키패드 confirm)
  void subtractScore(int score) {
    if (score <= 0) return;
    if (score > remainingScore) return;

    remainingScore -= score;
    if (remainingScore < 0) remainingScore = 0;

    _history.add(score);
    _updateRoutes();
  }

  /// 마지막 차감 되돌리기
  void undoLast() {
    if (!canUndo) return;

    final last = _history.removeLast();
    remainingScore += last;
    _updateRoutes();
  }

  /// 초기화(원하면 화면에서 “다시 시작” 같은 버튼에 연결)
  void reset() {
    remainingScore = 0;
    routes.clear();
    _history.clear();
    notifyListeners();
  }

  /// 추천 루트 갱신
  void _updateRoutes() {
    routes.clear();

    // 체크아웃은 2~170만 의미있음
    if (remainingScore < 2 || remainingScore > 170) {
      notifyListeners();
      return;
    }

    final data = checkoutTable[remainingScore.toString()];
    if (data != null) {
      // ✅ primary + alts 모두 들고 있는 CheckoutRoute 그대로 넣기
      routes.add(
        CheckoutRoute(
          primary: data.primary,
          alts: data.alts,
        ),
      );
    }

    notifyListeners();
  }
}
