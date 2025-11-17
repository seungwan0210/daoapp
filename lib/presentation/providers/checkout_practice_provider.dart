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
  final List<String> usedSegments;

  PracticeResult({
    required this.problem,
    required this.dartsUsed,
    required this.success,
    required this.originalScore,
    required this.usedSegments,
  });
}

class PracticeSessionSummary {
  final int elapsedSeconds;
  final List<PracticeResult> results;

  PracticeSessionSummary({
    required this.elapsedSeconds,
    required this.results,
  });
}

class CheckoutPracticeProvider extends ChangeNotifier {
  List<PracticeProblem> problems = [];
  int currentIndex = 0;
  int remainingScore = 0;
  List<String> currentDarts = [];
  int dartCount = 0;
  List<PracticeResult> results = [];

  int elapsedSeconds = 0;
  Timer? _timer;

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
    final optimalCount = successResults
        .where((r) => r.dartsUsed == getOptimalDarts(r.originalScore))
        .length;
    return optimalCount / successResults.length;
  }

  double get routeMatchRate {
    final successResults = results.where((r) => r.success).toList();
    if (successResults.isEmpty) return 0.0;

    int matchedCount = 0;
    for (final r in successResults) {
      final routeData = checkoutTable[r.originalScore.toString()];
      if (routeData == null) continue;

      final candidates = <List<String>>[
        routeData.primary,
        ...routeData.alts,
      ];

      for (final route in candidates) {
        if (route.length != r.usedSegments.length) continue;
        if (listEquals(route, r.usedSegments)) {
          matchedCount++;
          break;
        }
      }
    }
    return matchedCount / successResults.length;
  }

  double get currentEfficiency {
    if (dartCount == 0 || currentProblem == null) return 0.0;
    final optimal = getOptimalDarts(currentProblem!.targetScore);
    return (optimal / dartCount).clamp(0.0, 2.0) * 100; // 200% 이상도 허용 (3다트로 2다트 문제 풀면 150% 등)
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

  // 시작 / 종료
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

  double _calculateScoreRatio({
    required int elapsedSeconds,
    required double optimizationRate,
    required double routeMatchRate,
  }) {
    const int maxTimeSeconds = 600;
    double timeScore = 1 - (elapsedSeconds / maxTimeSeconds);
    if (timeScore < 0) timeScore = 0;
    return timeScore * 0.4 + optimizationRate * 0.3 + routeMatchRate * 0.3;
  }

  Future<void> finishPractice() async {
    _stopTimer();

    if (results.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final totalAttempts = results.length;
    final successCount = results.where((r) => r.success).length;
    final successRate = totalAttempts > 0 ? successCount / totalAttempts : 0.0;

    final successResults = results.where((r) => r.success).toList();
    final avgDarts = successResults.isEmpty
        ? 0.0
        : successResults.map((r) => r.dartsUsed).reduce((a, b) => a + b) / successResults.length;

    final optRate = optimizationRate;
    final routeRate = routeMatchRate;
    final scoreRatio = _calculateScoreRatio(
      elapsedSeconds: elapsedSeconds,
      optimizationRate: optRate,
      routeMatchRate: routeRate,
    );
    final score = (scoreRatio * 10000).round();

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      final recordData = {
        'timestamp': FieldValue.serverTimestamp(),
        'elapsedSeconds': elapsedSeconds,
        'successRate': successRate,
        'avgDarts': avgDarts,
        'problemCount': totalAttempts,
        'optimizationRate': optRate,
        'routeMatchRate': routeRate,
        'scoreRatio': scoreRatio,
        'score': score,
        'problems': results.map((r) => {
          'targetScore': r.problem.targetScore,
          'dartsUsed': r.dartsUsed,
          'success': r.success,
          'usedSegments': r.usedSegments,
          'recommendedRoute': r.problem.recommendedRoute,
        }).toList(),
      };

      // 두 컬렉션에 동일하게 저장
      await Future.wait([
        userRef.collection('checkout_practice').add(recordData),
        userRef.collection('checkout_practice_history').add({
          ...recordData,
          'createdAt': FieldValue.serverTimestamp(),
          'successCount': successCount,
          'totalAttempts': totalAttempts,
        }),
      ]);
    } catch (e) {
      debugPrint("체크아웃 연습 기록 저장 실패: $e");
    }
  }

  // 핵심 수정: Bust + 자동 성공
  void inputDart(String segment) {
    if (isFinished || currentProblem == null || dartCount >= 3) return;
    if (segment == "0") return;

    final value = _segmentValue(segment);
    final nextScore = remainingScore - value;

    // BUST 조건 (실제 다트 규칙 완벽 반영)
    final isDoubleOrBull = segment.startsWith('D') || segment == 'Bull';

    if (nextScore < 0 ||                     // 오버
        nextScore == 1 ||                     // 1점 남기기
        (nextScore == 0 && !isDoubleOrBull)) {// 더블 아닌데 0점
      failCurrentProblem();
      notifyListeners();
      return;
    }

    // 정상 입력
    currentDarts.add(segment);
    remainingScore = nextScore;
    dartCount++;

    // 정확히 0점 + 더블/불로 끝 → 자동 성공
    if (remainingScore == 0 && isDoubleOrBull) {
      Future.microtask(() => confirmCurrentProblem());
    }

    notifyListeners();
  }

  void undoLastDart() {
    if (currentDarts.isEmpty || currentProblem == null) return;

    final lastSegment = currentDarts.removeLast();
    final value = _segmentValue(lastSegment);
    remainingScore += value;
    dartCount--;
    notifyListeners();
  }

  void confirmCurrentProblem() {
    if (!isCurrentDoubleOut || remainingScore != 0 || currentProblem == null) return;

    results.add(PracticeResult(
      problem: currentProblem!,
      dartsUsed: dartCount,
      success: true,
      originalScore: currentProblem!.targetScore,
      usedSegments: List<String>.from(currentDarts),
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
      dartsUsed: dartCount,
      success: false,
      originalScore: currentProblem!.targetScore,
      usedSegments: List<String>.from(currentDarts), // 실패해도 기록 남김 (피드백용)
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

// Dart의 List == 비교를 위한 헬퍼 (routeMatchRate에서 사용)
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}