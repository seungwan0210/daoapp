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
  final List<String> usedSegments; // 실제로 던진 세그먼트 기록

  PracticeResult({
    required this.problem,
    required this.dartsUsed,
    required this.success,
    required this.originalScore,
    required this.usedSegments,
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

  /// 최적 다트 비율 (0.0 ~ 1.0) – 성공한 문제 중에서,
  /// "최적 다트 수"로 끝낸 비율
  double get optimizationRate {
    final successResults = results.where((r) => r.success).toList();
    if (successResults.isEmpty) return 0.0;

    final optimalCount = successResults
        .where((r) => r.dartsUsed == getOptimalDarts(r.originalScore))
        .length;

    return optimalCount / successResults.length;
  }

  /// 정석 루트 비율 (0.0 ~ 1.0)
  /// - checkout_table 의 primary + alts 중 하나를
  ///   "순서까지 정확히" 따라간 비율
  double get routeMatchRate {
    final successResults = results.where((r) => r.success).toList();
    if (successResults.isEmpty) return 0.0;

    int matchedCount = 0;

    for (final r in successResults) {
      final score = r.originalScore;
      final routeData = checkoutTable[score.toString()];
      if (routeData == null) continue;

      final candidates = <List<String>>[
        routeData.primary,
        ...routeData.alts,
      ];

      bool problemMatched = false;

      for (final route in candidates) {
        if (route.length != r.usedSegments.length) continue;

        bool allMatch = true;
        for (int i = 0; i < route.length; i++) {
          if (route[i] != r.usedSegments[i]) {
            allMatch = false;
            break;
          }
        }

        if (allMatch) {
          problemMatched = true;
          break;
        }
      }

      if (problemMatched) {
        matchedCount++;
      }
    }

    return matchedCount / successResults.length;
  }

  /// 현재 문제에서의 효율 (예전 UI용)
  /// - 최적 다트 수 / 실제 사용 다트 수 * 100 (%)
  double get currentEfficiency {
    if (!isCurrentFinished || currentProblem == null || dartCount == 0) {
      return 0.0;
    }
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

  /// Flutter 쪽에서도 점수 계산해서 저장 (UI, 히스토리용)
  /// Cloud Functions 의 calculateCheckoutScore 와 같은 로직
  double _calculateScoreRatio({
    required int elapsedSeconds,
    required double optimizationRate,
    required double routeMatchRate,
  }) {
    const int maxTimeSeconds = 600; // 10분 기준
    double timeScore = 1 - (elapsedSeconds / maxTimeSeconds);
    if (timeScore < 0) timeScore = 0;
    if (timeScore > 1) timeScore = 1;

    return timeScore * 0.4 +
        optimizationRate * 0.3 +
        routeMatchRate * 0.3;
  }

  /// Firestore에 기록 저장 + 종료
  /// - users/{uid}/checkout_practice           : 랭킹용 (Cloud Functions 트리거)
  /// - users/{uid}/checkout_practice_history  : 히스토리/디테일 화면용
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
        : successResults
        .map((r) => r.dartsUsed)
        .reduce((a, b) => a + b) /
        successResults.length;

    final optRate = optimizationRate; // 0.0 ~ 1.0
    final routeRate = routeMatchRate; // 0.0 ~ 1.0

    final scoreRatio = _calculateScoreRatio(
      elapsedSeconds: elapsedSeconds,
      optimizationRate: optRate,
      routeMatchRate: routeRate,
    );
    final score = (scoreRatio * 10000).round(); // 0 ~ 10000

    try {
      final userRef =
      FirebaseFirestore.instance.collection('users').doc(user.uid);

      // 1) 랭킹용 원본 기록 (Cloud Functions 트리거 대상)
      await userRef.collection('checkout_practice').add({
        'timestamp': FieldValue.serverTimestamp(),
        'elapsedSeconds': elapsedSeconds,
        'successRate': successRate,
        'avgDarts': avgDarts,
        'problemCount': totalAttempts,
        // 새 점수/지표
        'optimizationRate': optRate,
        'routeMatchRate': routeRate,
        'scoreRatio': scoreRatio,
        'score': score,
        // 문제별 기록
        'problems': results.map((r) {
          return {
            'targetScore': r.problem.targetScore,
            'dartsUsed': r.dartsUsed,
            'success': r.success,
            'usedSegments': r.usedSegments,
            'recommendedRoute': r.problem.recommendedRoute,
          };
        }).toList(),
      });

      // 2) 내 히스토리용 요약 기록
      await userRef.collection('checkout_practice_history').add({
        'createdAt': FieldValue.serverTimestamp(),
        'elapsedSeconds': elapsedSeconds,
        'successRate': successRate,
        'avgDarts': avgDarts,
        'totalAttempts': totalAttempts,
        'successCount': successCount,
        'optimizationRate': optRate,
        'routeMatchRate': routeRate,
        'scoreRatio': scoreRatio,
        'score': score,
        // 디테일 화면에서 문제별 기록도 보고 싶다면 그대로 저장
        'problems': results.map((r) {
          return {
            'targetScore': r.problem.targetScore,
            'dartsUsed': r.dartsUsed,
            'success': r.success,
            'usedSegments': r.usedSegments,
            'recommendedRoute': r.problem.recommendedRoute,
          };
        }).toList(),
      });
    } catch (e) {
      debugPrint("체크아웃 연습 기록 저장 실패: $e");
    }
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

    results.add(
      PracticeResult(
        problem: currentProblem!,
        dartsUsed: dartCount,
        success: true,
        originalScore: currentProblem!.targetScore,
        usedSegments: List<String>.from(currentDarts),
      ),
    );

    currentIndex++;
    _resetCurrentTurn();
    _updateRemainingScore();
    notifyListeners();
  }

  void failCurrentProblem() {
    if (currentProblem == null) return;

    results.add(
      PracticeResult(
        problem: currentProblem!,
        dartsUsed: 3,
        success: false,
        originalScore: currentProblem!.targetScore,
        usedSegments:
        const [], // 실패는 정석루트율 계산에 포함 X (routeMatchRate에서 success=false 필터됨)
      ),
    );

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
