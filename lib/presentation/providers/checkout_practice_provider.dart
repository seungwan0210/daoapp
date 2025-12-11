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

  PracticeProblem({required this.targetScore, required this.recommendedRoute});
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

  PracticeSessionSummary({required this.elapsedSeconds, required this.results});
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

  // ✅ 이번 턴 상태 플래그
  bool _isBust = false;
  bool _isCurrentSuccess = false;

  CheckoutPracticeProvider() {
    _optimalDartsCount = _buildOptimalDartsFromTable();
  }

  // 최적 다트 수 테이블
  Map<int, int> _buildOptimalDartsFromTable() {
    final map = <int, int>{};
    checkoutTable.forEach((scoreStr, route) {
      final score = int.parse(scoreStr);
      map[score] = route.primary.length;
    });
    return map;
  }

  int getOptimalDarts(int score) => _optimalDartsCount[score] ?? 3;

  // 통계 계산
  double get optimizationRate {
    final success = results.where((r) => r.success).toList();
    if (success.isEmpty) return 0.0;
    final optimal = success
        .where((r) => r.dartsUsed == getOptimalDarts(r.originalScore))
        .length;
    return optimal / success.length;
  }

  double get routeMatchRate {
    final success = results.where((r) => r.success).toList();
    if (success.isEmpty) return 0.0;

    int matched = 0;
    for (final r in success) {
      final data = checkoutTable[r.originalScore.toString()];
      if (data == null) continue;
      final candidates = [data.primary, ...data.alts];
      for (final route in candidates) {
        if (route.length == r.usedSegments.length &&
            listEquals(route, r.usedSegments)) {
          matched++;
          break;
        }
      }
    }
    return matched / success.length;
  }

  double get currentEfficiency {
    if (dartCount == 0 || currentProblem == null) return 0.0;
    final optimal = getOptimalDarts(currentProblem!.targetScore);
    return (optimal / dartCount).clamp(0.0, 2.0) * 100;
  }

  int get currentOptimalDarts =>
      currentProblem != null ? getOptimalDarts(currentProblem!.targetScore) : 3;

  bool get isFinished => currentIndex >= problems.length;

  PracticeProblem? get currentProblem =>
      currentIndex < problems.length ? problems[currentIndex] : null;

  // 마지막 다트가 더블/불인지
  bool get isCurrentDoubleOut {
    if (currentDarts.isEmpty) return false;
    final last = currentDarts.last;
    return last.startsWith('D') || last == 'Bull';
  }

  // ✅ 성공/BUST 상태 getter (UI에서 사용)
  bool get isBust => _isBust;
  bool get isCurrentSuccess => _isCurrentSuccess;

  // ✅ 확인 버튼 활성화 조건:
  //    - 최소 한 발은 던졌고
  //    - 성공이거나 BUST가 난 상태일 때만
  bool get canConfirm => dartCount > 0 && (_isCurrentSuccess || _isBust);

  // 시작 / 종료
  void startNewPractice({int problemCount = 10}) {
    _stopTimer();
    problems = _generateRandomProblems(problemCount);
    results.clear();
    currentIndex = 0;
    elapsedSeconds = 0;
    _resetCurrentTurn(resetScore: true);
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
    const maxTime = 600;
    final timeScore = (1 - elapsedSeconds / maxTime).clamp(0.0, 1.0);
    return timeScore * 0.4 + optimizationRate * 0.3 + routeMatchRate * 0.3;
  }

  Future<void> finishPractice() async {
    _stopTimer();
    if (results.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final totalAttempts = results.length;
    final successCount = results.where((r) => r.success).length;
    final successRate =
    totalAttempts > 0 ? successCount / totalAttempts : 0.0;

    final successResults = results.where((r) => r.success).toList();
    final avgDarts = successResults.isEmpty
        ? 0.0
        : successResults
        .map((r) => r.dartsUsed)
        .reduce((a, b) => a + b) /
        successResults.length;

    final optRate = optimizationRate;
    final routeRate = routeMatchRate;
    final scoreRatio = _calculateScoreRatio(
      elapsedSeconds: elapsedSeconds,
      optimizationRate: optRate,
      routeMatchRate: routeRate,
    );
    final score = (scoreRatio * 10000).round();

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
      'problems': results
          .map((r) => {
        'targetScore': r.problem.targetScore,
        'dartsUsed': r.dartsUsed,
        'success': r.success,
        'usedSegments': r.usedSegments,
        'recommendedRoute': r.problem.recommendedRoute,
      })
          .toList(),
    };

    final userRef =
    FirebaseFirestore.instance.collection('users').doc(user.uid);
    await Future.wait([
      userRef.collection('checkout_practice').add(recordData),
      userRef.collection('checkout_practice_history').add({
        ...recordData,
        'createdAt': FieldValue.serverTimestamp(),
        'successCount': successCount,
        'totalAttempts': totalAttempts,
      }),
    ]);
  }

  // =============================
  // 🔹 다트 입력 (판정만, 자동 진행 없음)
  // =============================
  void inputDart(String segment) {
    if (isFinished || currentProblem == null || dartCount >= 3) return;
    if (segment == "0") return;

    // 이미 성공 or BUST 상태면 더 이상 입력 안 받음
    if (_isBust || _isCurrentSuccess) return;

    final value = _segmentValue(segment);
    final prevScore = remainingScore;
    final nextScore = prevScore - value;
    final isDoubleOrBull = segment.startsWith('D') || segment == 'Bull';

    // 다트 반영
    currentDarts.add(segment);
    dartCount++;

    // 기본: 점수는 줄여놓고, 아래에서 bust/성공에 따라 보정
    int newScore = nextScore;

    bool bust = false;
    bool success = false;

    // BUST 조건: 음수 / 1점 / 0점인데 더블/불이 아님
    if (nextScore < 0 || nextScore == 1 || (nextScore == 0 && !isDoubleOrBull)) {
      bust = true;
      newScore = prevScore; // 화면에는 이전 점수 유지 (마이너스 안 보이게)
    } else if (nextScore == 0 && isDoubleOrBull) {
      success = true;
    }

    remainingScore = newScore;
    _isBust = bust;
    _isCurrentSuccess = success;

    notifyListeners();
  }

  // 되돌리기 → 판정도 초기화
  void undoLastDart() {
    if (currentDarts.isEmpty) return;

    final last = currentDarts.removeLast();
    remainingScore += _segmentValue(last);
    dartCount--;

    // 이 턴 판정 리셋
    _isBust = false;
    _isCurrentSuccess = false;

    notifyListeners();
  }

  // =============================
  // 🔹 확인 버튼 → 이때만 문제 종료 & 다음 문제
  // =============================
  void confirmCurrentProblem() {
    if (currentProblem == null) return;
    if (!_isBust && !_isCurrentSuccess) return; // 아직 판정 안 난 상태

    results.add(
      PracticeResult(
        problem: currentProblem!,
        dartsUsed: dartCount,
        success: _isCurrentSuccess, // 성공이면 true, BUST면 false
        originalScore: currentProblem!.targetScore,
        usedSegments: List<String>.from(currentDarts),
      ),
    );

    currentIndex++;
    _resetCurrentTurn(resetScore: true);
    notifyListeners();
  }

  // (필요하면 외부에서 강제로 실패 처리할 때 사용 가능, 지금은 안 씀)
  void failCurrentProblem() {
    if (currentProblem == null) return;

    results.add(
      PracticeResult(
        problem: currentProblem!,
        dartsUsed: dartCount,
        success: false,
        originalScore: currentProblem!.targetScore,
        usedSegments: List<String>.from(currentDarts),
      ),
    );

    currentIndex++;
    _resetCurrentTurn(resetScore: true);
    notifyListeners();
  }

  void _resetCurrentTurn({bool resetScore = false}) {
    currentDarts.clear();
    dartCount = 0;
    _isBust = false;
    _isCurrentSuccess = false;
    if (resetScore) {
      _updateRemainingScore();
    }
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
    return keys.take(count).map((score) {
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

// Flutter foundation 에 있는 listEquals 대신 간단 구현
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
