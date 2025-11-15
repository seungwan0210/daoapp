// lib/presentation/providers/checkout_practice_provider.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/core/constants/checkout_table.dart';
import 'package:daoapp/data/models/checkout_route_model.dart';

class PracticeProblem {
  final int targetScore;
  final List<String> recommendedRoute;

  PracticeProblem({
    required this.targetScore,
    required this.recommendedRoute,
  });
}

class PracticeResult {
  final PracticeProblem problem;
  final int dartsUsed;
  final bool success;
  final int originalScore;

  PracticeResult({
    required this.problem,
    required this.dartsUsed,
    required this.success,
    required this.originalScore,
  });
}

/// 연습 1세트(10문제) 요약 데이터
class PracticeSessionSummary {
  final int elapsedSeconds;
  final List<PracticeResult> results;

  PracticeSessionSummary({
    required this.elapsedSeconds,
    required this.results,
  });
}

class CheckoutPracticeProvider extends ChangeNotifier {
  // 문제/결과
  List<PracticeProblem> problems = [];
  int currentIndex = 0;
  int remainingScore = 0;
  List<String> currentDarts = [];
  int dartCount = 0;
  List<PracticeResult> results = [];

  // 타이머
  int elapsedSeconds = 0;
  Timer? _timer;

  // 최적 다트 수 테이블
  late final Map<int, int> _optimalDartsCount;

  CheckoutPracticeProvider() {
    _optimalDartsCount = _buildOptimalDartsFromTable();
  }

  Map<int, int> _buildOptimalDartsFromTable() {
    final map = <int, int>{};
    checkoutTable.forEach((scoreStr, route) {
      final score = int.parse(scoreStr);
      map[score] = route.primary.length;
    });
    return map;
  }

  int getOptimalDarts(int score) => _optimalDartsCount[score] ?? 3;

  double get optimizationRate {
    final successResults = results.where((r) => r.success).toList();
    if (successResults.isEmpty) return 0.0;

    final optimalCount = successResults.where(
          (r) => r.dartsUsed == getOptimalDarts(r.originalScore),
    ).length;

    return (optimalCount / successResults.length) * 100;
  }

  double get currentEfficiency {
    if (!isCurrentFinished || currentProblem == null) return 0.0;
    final optimal = getOptimalDarts(currentProblem!.targetScore);
    return (optimal / dartCount) * 100;
  }

  int get currentOptimalDarts =>
      currentProblem != null ? getOptimalDarts(currentProblem!.targetScore) : 3;

  bool get isFinished => currentIndex >= problems.length;

  PracticeProblem? get currentProblem =>
      currentIndex < problems.length ? problems[currentIndex] : null;

  bool get isCurrentDoubleOut {
    if (currentDarts.isEmpty) return false;
    final last = currentDarts.last;
    return last.startsWith('D') || last == 'Bull';
  }

  bool get isCurrentFinished =>
      currentProblem != null && remainingScore == 0 && isCurrentDoubleOut;

  bool get canConfirm => isCurrentFinished && dartCount > 0;

  // ===========================================================
  //                      시작 / 종료
  // ===========================================================
  void startNewPractice({int problemCount = 10}) {
    _stopTimer();
    problems = _generateRandomProblems(problemCount);
    results.clear();
    currentIndex = 0;
    elapsedSeconds = 0;
    _resetCurrentTurn();
    _updateRemainingScore();
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds++;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Firestore에 기록 저장 + 종료
  /// notifyListeners() 제거 → dispose 후 호출 방지
  Future<void> finishPractice() async {
    _stopTimer();

    if (results.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final successCount = results.where((r) => r.success).length;
    final successRate = successCount / results.length;
    final successResults = results.where((r) => r.success).toList();
    final avgDarts = successResults.isEmpty
        ? 0.0
        : successResults.map((r) => r.dartsUsed).reduce((a, b) => a + b) / successResults.length;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('checkout_practice')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'elapsedSeconds': elapsedSeconds,
        'successRate': successRate,
        'avgDarts': avgDarts,
        'problemCount': results.length,
        'problems': results.map((r) => {
          'targetScore': r.problem.targetScore,
          'dartsUsed': r.dartsUsed,
          'success': r.success,
        }).toList(),
      });
    } catch (e) {
      debugPrint("체크아웃 연습 기록 저장 실패: $e");
    }

    // notifyListeners() 제거! → 크래시 방지
  }

  // ===========================================================
  //                      다트 입력 / 수정 / 확인
  // ===========================================================
  void inputDart(String segment) {
    if (isFinished || currentProblem == null || dartCount >= 3) return;
    if (segment == "0") return;

    final value = _segmentValue(segment);
    currentDarts.add(segment);
    remainingScore -= value;
    if (remainingScore < 0) remainingScore = 0;
    dartCount++;
    notifyListeners();
  }

  /// 직전 다트만 되돌리기
  void undoLastDart() {
    if (currentDarts.isEmpty || currentProblem == null) return;

    final lastSegment = currentDarts.removeLast();
    final value = _segmentValue(lastSegment);
    remainingScore += value;
    dartCount--;
    notifyListeners();
  }

  void clearCurrentTurn() {
    _resetCurrentTurn();
    _updateRemainingScore();
    notifyListeners();
  }

  void confirmCurrentProblem() {
    if (!isCurrentFinished || currentProblem == null) return;

    results.add(PracticeResult(
      problem: currentProblem!,
      dartsUsed: dartCount,
      success: true,
      originalScore: currentProblem!.targetScore,
    ));

    currentIndex++;
    _resetCurrentTurn();
    _updateRemainingScore();
    notifyListeners();
  }

  void failCurrentProblem() {
    if (currentProblem == null) return;

    results.add(PracticeResult(
      problem: currentProblem!,
      dartsUsed: 3,
      success: false,
      originalScore: currentProblem!.targetScore,
    ));

    currentIndex++;
    _resetCurrentTurn();
    _updateRemainingScore();
    notifyListeners();
  }

  void _resetCurrentTurn() {
    currentDarts.clear();
    dartCount = 0;
  }

  void _updateRemainingScore() {
    remainingScore = currentProblem?.targetScore ?? 0;
  }

  // ===========================================================
  //                      문제 생성
  // ===========================================================
  List<PracticeProblem> _generateRandomProblems(int count) {
    final rnd = Random();
    final keys = checkoutTable.keys
        .map(int.parse)
        .where((v) => v >= 61 && v <= 170)
        .toList();

    keys.shuffle(rnd);
    final selected = keys.take(count).toList();

    return selected.map((score) {
      final data = checkoutTable[score.toString()]!;
      return PracticeProblem(
        targetScore: score,
        recommendedRoute: data.primary,
      );
    }).toList();
  }

  // ===========================================================
  //                      유틸
  // ===========================================================
  int _segmentValue(String s) {
    if (s == 'Bull') return 50;
    if (s == 'SB') return 25;
    final match = RegExp(r'([STD])(\d+)').firstMatch(s);
    if (match == null) return 0;
    final type = match.group(1);
    final num = int.parse(match.group(2)!);
    return switch (type) {
      'S' => num,
      'D' => num * 2,
      'T' => num * 3,
      _ => 0,
    };
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}