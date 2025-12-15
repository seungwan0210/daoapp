import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ listEquals
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/core/constants/checkout_table.dart';

class PracticeProblem {
  final int targetScore;
  final List<String> recommendedRoute;

  PracticeProblem({required this.targetScore, required this.recommendedRoute});
}

class PracticeResult {
  final PracticeProblem problem;
  final int dartsUsed;
  final bool success;

  /// ✅ "문제 시작 점수"(기록용) - 절대 변하지 않게
  final int originalScore;

  /// ✅ 유저가 실제로 입력한 루트(최대 3개)
  final List<String> usedSegments;

  PracticeResult({
    required this.problem,
    required this.dartsUsed,
    required this.success,
    required this.originalScore,
    required this.usedSegments,
  });
}

/// ✅ 피니시 루트 연습 결과 화면으로 넘길 Summary
class FinishRoutePracticeSessionSummary {
  final int elapsedSeconds;
  final List<PracticeResult> results;

  FinishRoutePracticeSessionSummary({
    required this.elapsedSeconds,
    required this.results,
  });
}

enum FinishRouteTurnState {
  playing,
  pendingSuccess,
  pendingBust,
}

class FinishRoutePracticeProvider extends ChangeNotifier {
  // ================================================================
  // 상태
  // ================================================================
  List<PracticeProblem> problems = [];
  int currentIndex = 0;

  /// ✅ 문제 시작 점수(기록/표시 기준)
  int startingScore = 0;

  /// ✅ 남은 점수(진행 중 감소)
  int remainingScore = 0;

  List<String> currentDarts = [];
  int dartCount = 0;

  List<PracticeResult> results = [];

  int elapsedSeconds = 0;
  Timer? _timer;

  late final Map<int, int> _optimalDartsCount;

  FinishRouteTurnState _turnState = FinishRouteTurnState.playing;
  FinishRouteTurnState get turnState => _turnState;

  bool get isFinished => currentIndex >= problems.length;
  PracticeProblem? get currentProblem =>
      currentIndex < problems.length ? problems[currentIndex] : null;

  FinishRoutePracticeProvider() {
    _optimalDartsCount = _buildOptimalDartsFromTable();
  }

  // ================================================================
  // Firestore
  // ================================================================
  CollectionReference<Map<String, dynamic>> _historyRef(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('finish_route_practice');
  }

  // ================================================================
  // 최적 다트 수 테이블
  // ================================================================
  Map<int, int> _buildOptimalDartsFromTable() {
    final map = <int, int>{};
    checkoutTable.forEach((scoreStr, route) {
      final score = int.tryParse(scoreStr);
      if (score != null) map[score] = route.primary.length;
    });
    return map;
  }

  int getOptimalDarts(int score) => _optimalDartsCount[score] ?? 3;

  // ================================================================
  // 통계
  // ================================================================
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

      final candidates = <List<String>>[data.primary, ...data.alts];
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
    if (dartCount == 0) return 0.0;
    final optimal = getOptimalDarts(startingScore);
    return (optimal / dartCount).clamp(0.0, 2.0) * 100;
  }

  int get currentOptimalDarts => getOptimalDarts(startingScore);

  bool get canConfirm =>
      _turnState == FinishRouteTurnState.pendingSuccess ||
          _turnState == FinishRouteTurnState.pendingBust;

  bool get isBust => _turnState == FinishRouteTurnState.pendingBust;

  // ================================================================
  // 시작/종료
  // ================================================================
  void startNewPractice({int problemCount = 10}) {
    _stopTimer();

    problems = _generateRandomProblems(problemCount);
    results.clear();

    currentIndex = 0;
    elapsedSeconds = 0;

    _turnState = FinishRouteTurnState.playing;

    _resetCurrentTurn();
    _updateStartingAndRemainingScore();

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

  /// ✅ 최종 방향:
  /// - 기록 저장: 로그인 유저만
  /// - 랭킹 write: 클라이언트에서 절대 하지 않음 (Cloud Function만)
  Future<void> finishPractice() async {
    _stopTimer();
    if (results.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('FinishRoutePractice: user is null (login required).');
      return;
    }

    final totalAttempts = results.length;
    final successCount = results.where((r) => r.success).length;
    final successRate =
    totalAttempts > 0 ? successCount / totalAttempts : 0.0;

    final successResults = results.where((r) => r.success).toList();
    final avgDarts = successResults.isEmpty
        ? 0.0
        : successResults.map((r) => r.dartsUsed).reduce((a, b) => a + b) /
        successResults.length;

    final optRate = optimizationRate;
    final routeRate = routeMatchRate;

    final scoreRatio = _calculateScoreRatio(
      elapsedSeconds: elapsedSeconds,
      optimizationRate: optRate,
      routeMatchRate: routeRate,
    );
    final score = (scoreRatio * 10000).round();

    // ✅ 이름: users 문서에서 가져오기
    String koreanName = '이름 없음';
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      koreanName = (userData['koreanName'] ?? '이름 없음').toString().trim();
    } catch (e) {
      debugPrint('FinishRoutePractice: failed to load koreanName: $e');
    }

    final recordData = <String, dynamic>{
      // ✅ 서버 시간(정렬/월키는 Cloud Function에서 이걸 활용)
      'timestamp': FieldValue.serverTimestamp(),

      // ✅ 정렬 안정화용(항상 존재)
      'clientTimestamp': DateTime.now().millisecondsSinceEpoch,

      'elapsedSeconds': elapsedSeconds,
      'successRate': successRate,
      'avgDarts': avgDarts,
      'problemCount': totalAttempts,
      'successCount': successCount,
      'optimizationRate': optRate,

      // ✅ 키 혼용 대비
      'routeMatchRate': routeRate,
      'routeAccuracy': routeRate,

      // 계산값(선택)
      'scoreRatio': scoreRatio,
      'score': score,

      // 표시용(선택)
      'uid': user.uid,
      'koreanName': koreanName,

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

    try {
      await _historyRef(user.uid).add(recordData);
    } on FirebaseException catch (e) {
      debugPrint('FinishRoutePractice: save failed: ${e.code} ${e.message}');
    } catch (e) {
      debugPrint('FinishRoutePractice: save failed (unknown): $e');
    }
  }

  // ================================================================
  // 턴 입력 로직
  // ================================================================
  void inputDart(String segment) {
    if (isFinished || currentProblem == null) return;
    if (_turnState != FinishRouteTurnState.playing) return;
    if (dartCount >= 3) return;

    final value = _segmentValue(segment);
    final nextScore = remainingScore - value;
    final isDoubleOrBull = segment.startsWith('D') || segment == 'Bull';

    final bust =
        nextScore < 0 || nextScore == 1 || (nextScore == 0 && !isDoubleOrBull);

    // ✅ bust여도 "던진 세그먼트"는 기록에 남기는게 맞음
    currentDarts.add(segment);
    dartCount++;

    if (bust) {
      _turnState = FinishRouteTurnState.pendingBust;
      notifyListeners();
      return;
    }

    remainingScore = nextScore;

    if (remainingScore == 0 && isDoubleOrBull) {
      _turnState = FinishRouteTurnState.pendingSuccess;
    }

    notifyListeners();
  }

  void undoLastDart() {
    // ✅ bust/pending 상태에서는 undo를 막는 게 안전(상태 깨짐 방지)
    if (_turnState != FinishRouteTurnState.playing) return;
    if (currentDarts.isEmpty) return;

    final last = currentDarts.removeLast();

    // ✅ remainingScore는 bust 때도 감소시키지 않기 때문에
    // playing 중에만 되돌리기 로직 유지
    remainingScore += _segmentValue(last);
    dartCount--;
    notifyListeners();
  }

  void confirmCurrentProblem() {
    if (!canConfirm) return;
    if (currentProblem == null) return;

    final success = _turnState == FinishRouteTurnState.pendingSuccess;

    results.add(
      PracticeResult(
        problem: currentProblem!,
        dartsUsed: dartCount,
        success: success,
        originalScore: startingScore, // ✅ 문제 시작 점수로 고정
        usedSegments: List<String>.from(currentDarts),
      ),
    );

    currentIndex++;
    _turnState = FinishRouteTurnState.playing;

    _resetCurrentTurn();
    _updateStartingAndRemainingScore();
    notifyListeners();
  }

  void failCurrentProblem() {
    if (currentProblem == null) return;

    results.add(
      PracticeResult(
        problem: currentProblem!,
        dartsUsed: dartCount,
        success: false,
        originalScore: startingScore, // ✅ 문제 시작 점수로 고정
        usedSegments: List<String>.from(currentDarts),
      ),
    );

    currentIndex++;
    _turnState = FinishRouteTurnState.playing;

    _resetCurrentTurn();
    _updateStartingAndRemainingScore();
    notifyListeners();
  }

  void _resetCurrentTurn() {
    currentDarts.clear();
    dartCount = 0;
    _turnState = FinishRouteTurnState.playing;
  }

  void _updateStartingAndRemainingScore() {
    startingScore = currentProblem?.targetScore ?? 0;
    remainingScore = startingScore;
  }

  // ================================================================
  // 문제 생성/점수 변환
  // ================================================================
  List<PracticeProblem> _generateRandomProblems(int count) {
    final rnd = Random();
    final keys = checkoutTable.keys
        .map((e) => int.tryParse(e))
        .whereType<int>()
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

    switch (type) {
      case 'S':
        return num;
      case 'D':
        return num * 2;
      case 'T':
        return num * 3;
      default:
        return 0;
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
