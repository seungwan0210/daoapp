// lib/presentation/providers/checkout_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math';

import 'package:daoapp/core/constants/checkout_table.dart';
import 'package:daoapp/data/models/checkout_route_model.dart';
import 'package:daoapp/data/models/practice_session_summary.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class CheckoutState {
  final int remainingScore;
  final List<CheckoutRoute> routes;
  final List<int> history;
  final List<Turn> practiceHistory;
  final List<String> currentTurn;
  final bool isPracticing;
  final int elapsedSeconds;

  const CheckoutState({
    required this.remainingScore,
    required this.routes,
    required this.history,
    required this.practiceHistory,
    required this.currentTurn,
    required this.isPracticing,
    this.elapsedSeconds = 0,
  });

  factory CheckoutState.initial() => const CheckoutState(
    remainingScore: 0,
    routes: [],
    history: [],
    practiceHistory: [],
    currentTurn: [],
    isPracticing: false,
  );

  CheckoutState copyWith({
    int? remainingScore,
    List<CheckoutRoute>? routes,
    List<int>? history,
    List<Turn>? practiceHistory,
    List<String>? currentTurn,
    bool? isPracticing,
    int? elapsedSeconds,
  }) {
    return CheckoutState(
      remainingScore: remainingScore ?? this.remainingScore,
      routes: routes ?? this.routes,
      history: history ?? this.history,
      practiceHistory: practiceHistory ?? this.practiceHistory,
      currentTurn: currentTurn ?? this.currentTurn,
      isPracticing: isPracticing ?? this.isPracticing,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  // 계산기에서 되돌리기 가능 여부
  bool get canUndo => history.isNotEmpty && !isPracticing;

  // 현재 남은 점수에 대한 최적 다트 수 (없으면 3다트 기준)
  int get currentOptimalDarts =>
      checkoutTable[remainingScore.toString()]?.primary.length ?? 3;

  // 간단 효율 지표 (최적/실제 다트 수 비율 → %)
  double get currentEfficiency =>
      currentTurn.isEmpty
          ? 0
          : (currentOptimalDarts / currentTurn.length)
          .clamp(0.0, 2.0) *
          100;

  // 1점이 남았거나, 0점인데 더블/불로 끝나지 않은 경우 BUST
  bool get isBust =>
      remainingScore == 1 ||
          (remainingScore == 0 &&
              !currentTurn.any(
                    (s) => s.startsWith('D') || s == 'Bull',
              ));
}

class Turn {
  final List<String> darts;
  final int scoreBefore;

  const Turn({
    required this.darts,
    required this.scoreBefore,
  });
}

class CheckoutProvider extends StateNotifier<CheckoutState> {
  CheckoutProvider() : super(CheckoutState.initial());

  Timer? _timer;

  // =========================
  // ✅ 계산기 전용 API
  // =========================

  void setInitialScore(int score) {
    if (score < 2 || score > 170) return;
    state = CheckoutState.initial().copyWith(remainingScore: score);
    _updateRoutes();
  }

  void subtractScore(int score) {
    if (score <= 0 || score > state.remainingScore) return;
    state = state.copyWith(
      remainingScore: state.remainingScore - score,
      history: [...state.history, score],
    );
    _updateRoutes();
  }

  void undoLast() {
    if (!state.canUndo) return;
    final last = state.history.last;
    final newHistory = List<int>.from(state.history)..removeLast();

    state = state.copyWith(
      remainingScore: state.remainingScore + last,
      history: newHistory,
    );
    _updateRoutes();
  }

  // =========================
  // ✅ 연습 모드 전용 API
  // =========================

  void startPractice() {
    state = CheckoutState.initial().copyWith(
      isPracticing: true,
      remainingScore: _randomScore(),
    );
    _startTimer();
    _updateRoutes();
  }

  void inputDart(String segment) {
    if (!state.isPracticing || state.currentTurn.length >= 3) return;
    final value = _segmentValue(segment);
    final newScore = state.remainingScore - value;
    if (newScore < 0) return;

    state = state.copyWith(
      remainingScore: newScore,
      currentTurn: [...state.currentTurn, segment],
    );
    _updateRoutes();
  }

  void finishTurn(BuildContext context) {
    if (state.currentTurn.isEmpty) return;

    final turnScore =
    state.currentTurn.map(_segmentValue).fold(0, (a, b) => a + b);
    final scoreBefore = state.remainingScore + turnScore;

    state = state.copyWith(
      practiceHistory: [
        ...state.practiceHistory,
        Turn(
          darts: List.from(state.currentTurn),
          scoreBefore: scoreBefore,
        ),
      ],
      currentTurn: [],
    );

    if (state.remainingScore <= 0) {
      _finishPractice(context);
    } else {
      state = state.copyWith(remainingScore: _randomScore());
    }
    _updateRoutes();
  }

  void _finishPractice(BuildContext context) {
    _timer?.cancel();

    final summary = PracticeSessionSummary(
      elapsedSeconds: state.elapsedSeconds,
      results: state.practiceHistory
          .map(
            (t) => PracticeResult(
          scoreBefore: t.scoreBefore,
          darts: t.darts,
          isSuccess: true,
          dartsUsed: t.darts.length,
        ),
      )
          .toList(),
    );

    if (context.mounted) {
      Navigator.pushReplacementNamed(
        context,
        // 🔥 여기만 새 피니쉬 루트 결과 라우트로 변경
        RouteConstants.finishRouteResult,
        arguments: summary,
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        elapsedSeconds: state.elapsedSeconds + 1,
      );
    });
  }

  int _randomScore() {
    final scores = checkoutTable.keys
        .map(int.parse)
        .where((s) => s >= 61 && s <= 170)
        .toList();
    return scores[Random().nextInt(scores.length)];
  }

  void _updateRoutes() {
    final routes = <CheckoutRoute>[];

    if (state.remainingScore >= 2 && state.remainingScore <= 170) {
      final data = checkoutTable[state.remainingScore.toString()];
      if (data != null) {
        routes.add(
          CheckoutRoute(
            primary: data.primary,
            alts: data.alts,
          ),
        );
      }
    }

    state = state.copyWith(routes: routes);
  }

  int _segmentValue(String s) {
    if (s == 'Bull') return 50;
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
    _timer?.cancel();
    super.dispose();
  }
}

final checkoutProvider =
StateNotifierProvider<CheckoutProvider, CheckoutState>(
      (ref) => CheckoutProvider(),
);
