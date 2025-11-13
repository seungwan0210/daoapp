// lib/presentation/providers/checkout_provider.dart
import 'package:flutter/material.dart';
import 'package:daoapp/core/constants/checkout_table.dart';
import 'package:daoapp/data/models/checkout_route_model.dart';
import 'package:daoapp/core/constants/route_constants.dart'; // 추가!

class CheckoutProvider extends ChangeNotifier {
  int remainingScore = 0;
  List<String> currentTurn = [];
  List<CheckoutRoute> routes = [];
  List<Turn> practiceHistory = [];
  bool isPracticing = false;

  void calculateRoutes(int score) {
    routes.clear();
    if (score < 2 || score > 170) return;
    final data = checkoutTable[score.toString()];
    if (data != null) {
      routes.add(CheckoutRoute(primary: data.primary));
      routes.addAll(data.alts.map((alt) => CheckoutRoute(primary: alt)));
    }
    notifyListeners();
  }

  void startPractice(int startScore) {
    remainingScore = startScore;
    isPracticing = true;
    practiceHistory.clear();
    currentTurn.clear();
    notifyListeners();
  }

  void inputDart(String segment) {
    if (currentTurn.length >= 3 || !isPracticing) return;
    currentTurn.add(segment);
    remainingScore -= _segmentValue(segment);
    if (remainingScore < 0) remainingScore = 0;
    notifyListeners();
  }

  void finishTurn(BuildContext context) {
    if (currentTurn.isEmpty) return;
    final turnScore = _turnScore();
    practiceHistory.add(Turn(
      darts: List.from(currentTurn),
      scoreBefore: remainingScore + turnScore,
    ));
    currentTurn.clear();

    if (remainingScore <= 0) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (context.mounted) {
          Navigator.pushNamed(context, RouteConstants.checkoutResult);
        }
      });
    }
    notifyListeners();
  }

  int _turnScore() => currentTurn.map(_segmentValue).fold(0, (a, b) => a + b);

  bool _isDouble(String s) => s.startsWith('D') || s == 'Bull';

  int _segmentValue(String s) {
    if (s == 'Bull') return 50;
    if (s == 'SB') return 25;
    final match = RegExp(r'([STD])(\d+)').firstMatch(s);
    if (match == null) return 0;
    final type = match.group(1);
    final num = int.parse(match.group(2)!);
    return type == 'S' ? num : type == 'D' ? num * 2 : num * 3;
  }
}

// const 제거! List는 const 아님
class Turn {
  final List<String> darts;
  final int scoreBefore;

  const Turn({required this.darts, required this.scoreBefore});
}