// lib/presentation/providers/checkout_provider.dart
import 'package:flutter/material.dart';
import 'package:daoapp/core/constants/checkout_table.dart';
import 'package:daoapp/data/models/checkout_route_model.dart';
import 'package:daoapp/core/constants/route_constants.dart';

/// 체크아웃 계산기 + 연습 모드 공통 상태 관리
class CheckoutProvider extends ChangeNotifier {
  // === 계산기 & 연습 공통 ===
  int remainingScore = 0;              // 남은 점수
  List<CheckoutRoute> routes = [];     // 현재 점수에서 추천 루트들

  // === 연습 모드 전용 ===
  List<String> currentTurn = [];       // 이번 턴에서 던진 다트들 ["T20", "T20", "D20"]
  List<Turn> practiceHistory = [];     // 연습 기록
  bool isPracticing = false;

  // ================================================================
  //                           계산기 모드
  // ================================================================

  /// 초기 점수 설정 (계산기 진입 시)
  void setInitialScore(int score) {
    remainingScore = score;
    _updateRoutes();
  }

  /// 점수 차감 (키패드 입력 후)
  void subtractScore(int score) {
    remainingScore -= score;
    if (remainingScore < 0) remainingScore = 0;
    _updateRoutes();
  }

  // ================================================================
  //                           연습 모드
  // ================================================================

  /// 연습 시작
  void startPractice(int startScore) {
    remainingScore = startScore;
    isPracticing = true;
    practiceHistory.clear();
    currentTurn.clear();
    _updateRoutes();
  }

  /// 다트 입력 (세그먼트: T20, D20 등)
  void inputDart(String segment) {
    if (currentTurn.length >= 3 || !isPracticing) return;
    currentTurn.add(segment);
    remainingScore -= _segmentValue(segment);
    if (remainingScore < 0) remainingScore = 0;
    _updateRoutes();
  }

  /// 턴 종료
  void finishTurn(BuildContext context) {
    if (currentTurn.isEmpty || !isPracticing) return;

    final turnScore = _turnScore();
    final scoreBefore = remainingScore + turnScore;

    practiceHistory.add(
      Turn(
        darts: List.from(currentTurn),
        scoreBefore: scoreBefore,
      ),
    );

    currentTurn.clear();

    if (remainingScore <= 0) {
      // 체크아웃 성공 → 결과 화면으로
      Future.delayed(const Duration(milliseconds: 400), () {
        if (context.mounted) {
          Navigator.pushNamed(context, RouteConstants.checkoutResult);
        }
      });
    } else {
      _updateRoutes();
    }

    notifyListeners();
  }

  // ================================================================
  //                           공통 유틸
  // ================================================================

  /// 추천 루트 갱신
  void _updateRoutes() {
    routes.clear();

    // 체크아웃 가능한 범위만 (2~170점)
    if (remainingScore < 2 || remainingScore > 170) {
      notifyListeners();
      return;
    }

    final data = checkoutTable[remainingScore.toString()];
    if (data != null) {
      // ① 메인 루트
      routes.add(
        CheckoutRoute(
          primary: data.primary,
        ),
      );

      // ② 대체 루트들 각각을 별도 CheckoutRoute로 추가
      routes.addAll(
        data.alts.map(
              (alt) => CheckoutRoute(primary: alt),
        ),
      );
    }

    notifyListeners();
  }

  /// 턴 점수 합계
  int _turnScore() => currentTurn.map(_segmentValue).fold(0, (a, b) => a + b);

  /// 세그먼트 → 실제 점수 변환
  int _segmentValue(String s) {
    if (s == 'Bull') return 50;
    // 과거에 SB(싱글 불, 25)를 썼다면 그대로 유지
    if (s == 'SB') return 25;

    final match = RegExp(r'([STD])(\d+)').firstMatch(s);
    if (match == null) return 0;

    final type = match.group(1);
    final num = int.parse(match.group(2)!);

    if (type == 'S') return num;
    if (type == 'D') return num * 2;
    if (type == 'T') return num * 3;
    return 0;
  }
}

/// 연습 기록 모델
class Turn {
  final List<String> darts;     // ["T20", "D20"]
  final int scoreBefore;        // 턴 시작 전 남은 점수

  const Turn({
    required this.darts,
    required this.scoreBefore,
  });
}
