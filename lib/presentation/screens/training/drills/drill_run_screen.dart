// lib/presentation/screens/training/drills/drill_run_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/presentation/providers/training/training_drill_provider.dart';

import 'drill_result_screen.dart';
import 'widgets/core/drill_header_card.dart';
import 'widgets/core/generic_hit_panel.dart';

// specialized
import 'widgets/specialized/triple_switch_panel.dart';
import 'widgets/specialized/double_clock_panel.dart';
import 'widgets/specialized/random_checkout_panel.dart';
import 'widgets/specialized/full_cricket_panel.dart';
import 'widgets/specialized/t20_focus_panel.dart';
import 'widgets/specialized/fixed_route_panel.dart';
import 'widgets/specialized/score_game_panel.dart';
import 'widgets/specialized/quadrant_board_panel.dart';
import 'widgets/specialized/top_bottom_board_panel.dart';
import 'widgets/specialized/around_board_panel.dart';

class DrillRunScreen extends ConsumerStatefulWidget {
  final TrainingDrillDefinition drill;
  final DaoTrainingTier tier;

  const DrillRunScreen({
    super.key,
    required this.drill,
    required this.tier,
  });

  @override
  ConsumerState<DrillRunScreen> createState() => _DrillRunScreenState();
}

class _DrillRunScreenState extends ConsumerState<DrillRunScreen> {
  int _currentRound = 1;
  int _currentDart = 1;
  int _totalAttempts = 0;
  int _successCount = 0;
  int _currentScore = 0;
  int _currentMarks = 0;

  bool _isStartingSession = false;
  bool _isFinishing = false;

  late final int _totalPlannedDarts;

  /// 패널들이 공통으로 참조하는 다트 수
  late final ValueNotifier<int> _thrownDartsNotifier;

  @override
  void initState() {
    super.initState();
    _totalPlannedDarts = _calculateTotalPlannedDarts();
    _thrownDartsNotifier = ValueNotifier<int>(0);

    Future.microtask(
          () => ref.read(trainingDrillProvider.notifier).clearSession(),
    );
  }

  @override
  void dispose() {
    _thrownDartsNotifier.dispose();
    super.dispose();
  }

  int _calculateTotalPlannedDarts() {
    final extra = widget.drill.extraConfig ?? {};

    // 🔹 Top / Bottom 전용: 영역당 다트 수 * 2
    if (extra['mode'] == 'top_bottom' && extra['totalDartsPerArea'] is num) {
      return ((extra['totalDartsPerArea'] as num).toInt() * 2);
    }

    if (widget.drill.recommendedDarts != null) {
      return widget.drill.recommendedDarts!;
    }

    if (extra['totalDarts'] is num) {
      return (extra['totalDarts'] as num).toInt();
    }

    if (extra['sets'] is num && extra['dartsPerSet'] is num) {
      return (extra['sets'] as num).toInt() *
          (extra['dartsPerSet'] as num).toInt();
    }

    if (extra['rounds'] is num) {
      final dpr = (extra['dartsPerRound'] as num?)?.toInt() ?? 3;
      return (extra['rounds'] as num).toInt() * dpr;
    }

    // 기본 60다트
    return 60;
  }

  double get _progress =>
      _totalPlannedDarts == 0 ? 0 : _totalAttempts / _totalPlannedDarts;

  double get _successRate =>
      _totalAttempts == 0 ? 0 : _successCount / _totalAttempts;

  bool get _hasAnyRecord =>
      _totalAttempts > 0 || _currentScore > 0 || _currentMarks > 0;

  Future<void> _ensureSessionStarted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        _isStartingSession ||
        ref.read(trainingDrillProvider).activeSession != null) {
      return;
    }

    setState(() => _isStartingSession = true);
    try {
      await ref.read(trainingDrillProvider.notifier).startSession(
        userId: user.uid,
        drill: widget.drill,
        tierAtThatTime: widget.tier,
      );
    } finally {
      if (mounted) setState(() => _isStartingSession = false);
    }
  }

  Future<void> _recordHit(bool success) async {
    await _ensureSessionStarted();
    if (!mounted) return;

    setState(() {
      _totalAttempts++;
      if (success) _successCount++;

      // 패널들에 공유
      _thrownDartsNotifier.value = _totalAttempts;

      if (_currentDart < 3) {
        _currentDart++;
      } else {
        _currentDart = 1;
        _currentRound++;
      }

      if (_totalAttempts >= _totalPlannedDarts) {
        _finishDrill(earlyFinish: false);
      }
    });
  }

  Future<void> _submitScoreGame({
    required int value,
    required bool isDartsMode,
  }) async {
    await _ensureSessionStarted();
    if (!mounted) return;

    setState(() {
      if (isDartsMode) {
        _totalAttempts = value; // 사용 다트 수
        _currentScore = 501;
      } else {
        _currentScore = value; // 최종 점수
        _totalAttempts = _totalPlannedDarts;
      }
      _thrownDartsNotifier.value = _totalAttempts;
    });

    await _finishDrill(earlyFinish: false);
  }

  Future<void> _finishDrill({required bool earlyFinish}) async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    try {
      await ref.read(trainingDrillProvider.notifier).finishSession(
        inputMode: widget.drill.inputMode,
        totalRounds: _currentRound,
        totalDarts: _totalAttempts,
        hitCount: _successCount,
        totalScore: _currentScore,
        totalMarks: _currentMarks,
        additionalExtra: {
          'finishedEarly': earlyFinish,
          'totalPlannedDarts': _totalPlannedDarts,
        },
      );

      final session = ref.read(trainingDrillProvider).activeSession;
      if (!mounted) return;

      if (session != null) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DrillResultScreen(
              session: session,
              drill: widget.drill,
              tier: widget.tier,
            ),
          ),
        );
        ref.read(trainingDrillProvider.notifier).clearSession();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  void _onManualFinish() {
    if (!_hasAnyRecord) {
      Navigator.pop(context);
      return;
    }
    _finishDrill(earlyFinish: true);
  }

  Widget _buildDrillPanel() {
    final isBusy = _isStartingSession || _isFinishing;
    final extra = widget.drill.extraConfig ?? {};
    final mode = extra['mode'] as String?;

    // 4분할 보드
    if (mode == 'quadrant') {
      return QuadrantBoardPanel(
        key: const ValueKey('quadrant_panel'),  // ← 추가!!
        totalDarts: _totalPlannedDarts,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // 상단/하단 보드
    if (mode == 'top_bottom') {
      return TopBottomBoardPanel(
        key: const ValueKey('top_bottom_panel'),  // ← 추가!!
        totalDarts: _totalPlannedDarts,          // 🔹 총 계획 다트 수 전달
        onHitSuccess: () => _recordHit(true),    // 🔹 성공 → 런스크린 공통 로직
        onHitFail: () => _recordHit(false),      // 🔹 실패 → 런스크린 공통 로직
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // 싱글 한 바퀴
    if (mode == 'around_board') {
      final seq =
          ((extra['sequence'] as List?)?.map((e) => e.toString()).toList()) ??
              (List.generate(20, (i) => '${i + 1}')..add('SB'));

      return AroundBoardPanel(
        sequence: seq,
        thrownDartsNotifier: _thrownDartsNotifier,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        onCompleted: () => _finishDrill(earlyFinish: false),
        isBusy: isBusy,
      );
    }

    // 트리플 스위치
    if (widget.drill.id == 'elite_t20_t19_triple_switch') {
      return TripleSwitchPanel(
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // 더블 시계
    if (widget.drill.id.contains('double_clock')) {
      return DoubleClockPanel(
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // 랜덤 체크아웃
    if (mode == 'random_range') {
      final minScore = (extra['minScore'] as num?)?.toInt() ?? 61;
      final maxScore = (extra['maxScore'] as num?)?.toInt() ?? 120;
      final maxDarts = (extra['maxDartsPerScore'] as num?)?.toInt() ?? 6;

      return RandomCheckoutPanel(
        minScore: minScore,
        maxScore: maxScore,
        maxDarts: maxDarts,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // 170 고정 루트
    if (widget.drill.id == 'master_170_route_focused_30') {
      return FixedRoutePanel(
        route: const ['T20', 'T20', 'Bull'],
        targetScore: '170',
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // T20 집중
    final segments = (extra['segments'] as List?)?.cast<String>();
    final isT20Only =
        segments != null && segments.length == 1 && segments.first == 'T20';
    if (isT20Only) {
      final totalDarts =
          (extra['totalDarts'] as num?)?.toInt() ?? _totalPlannedDarts;
      return T20FocusPanel(
        totalDarts: totalDarts,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // 크리켓 MPR
    if (widget.drill.inputMode == TrainingDrillInputMode.cricketMarks) {
      return FullCricketPanel(
        onMarksRecorded: (marks) {
          setState(() => _currentMarks += marks);
          _recordHit(true);
        },
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // Count-Up / 501
    if (widget.drill.inputMode == TrainingDrillInputMode.scoreOnly) {
      final gameType = (extra['gameType'] as String?) ?? '';
      final is501Mode = gameType.startsWith('501');

      if (is501Mode) {
        final threshold =
            (extra['successThresholdDarts'] as num?)?.toInt() ?? 18;
        return ScoreGamePanel(
          title: '501 Double-Out',
          valueLabel: '사용한 다트 수',
          minValue: 9,
          maxValue: 30,
          initialValue: threshold,
          helperText: '1 leg에서 사용한 총 다트 수를 입력하세요.',
          isBusy: isBusy,
          onSubmit: (value) =>
              _submitScoreGame(value: value, isDartsMode: true),
          onFinishPressed: _onManualFinish,
        );
      } else {
        final targetScore = (extra['targetScore'] as num?)?.toInt() ?? 700;
        final maxScore = (extra['maxScore'] as num?)?.toInt() ?? 1500;
        return ScoreGamePanel(
          title: 'Count-Up 최종 점수',
          valueLabel: '최종 점수',
          minValue: 0,
          maxValue: maxScore,
          initialValue: targetScore,
          helperText: '게임 한 판을 끝낸 후 최종 점수를 입력하세요.',
          isBusy: isBusy,
          onSubmit: (value) =>
              _submitScoreGame(value: value, isDartsMode: false),
          onFinishPressed: _onManualFinish,
        );
      }
    }

    // 기본 패널
    return GenericHitPanel(
      targetLabel: widget.drill.targetLabel,
      subTarget: null,
      currentRound: _currentRound,
      totalRounds: (_totalPlannedDarts / 3).ceil(),
      thrownDarts: _totalAttempts,
      totalDarts: _totalPlannedDarts,
      onHitSuccess: () => _recordHit(true),
      onHitFail: () => _recordHit(false),
      onFinishPressed: _onManualFinish,
      isBusy: isBusy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalRounds = (_totalPlannedDarts / 3).ceil();

    return WillPopScope(
      onWillPop: () async {
        if (_hasAnyRecord) {
          final exit = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('연습 종료'),
              content: const Text('기록이 저장되지 않습니다.\n계속하시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    '종료',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
          if (exit == true) {
            ref.read(trainingDrillProvider.notifier).clearSession();
          }
          return exit ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            '드릴 진행',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
        ),
        body: SafeArea(
          // 🔹 SingleChildScrollView 대신 ListView 하나로 정리
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            children: [
              // 상단 헤더 카드
              DrillHeaderCard(
                drill: widget.drill,
                tier: widget.tier,
              ),
              const SizedBox(height: 16),

              // 🔹 인라인 진행 카드 (스크린 공통)
              _InlineProgressCard(
                progress: _progress,
                totalAttempts: _totalAttempts,
                totalPlannedDarts: _totalPlannedDarts,
                currentRound: _currentRound,
                totalRounds: totalRounds,
                successRate: _successRate,
              ),

              const SizedBox(height: 24),

              // 메인 패널
              _buildDrillPanel(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// 상단에 들어가는 깔끔한 진행 카드
class _InlineProgressCard extends StatelessWidget {
  final double progress;
  final int totalAttempts;
  final int totalPlannedDarts;
  final int currentRound;
  final int totalRounds;
  final double successRate;

  const _InlineProgressCard({
    required this.progress,
    required this.totalAttempts,
    required this.totalPlannedDarts,
    required this.currentRound,
    required this.totalRounds,
    required this.successRate,
  });

  @override
  Widget build(BuildContext context) {
    final percentText = "${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%";
    final successText = totalAttempts == 0
        ? "--"
        : "${(successRate * 100).clamp(0, 100).toStringAsFixed(1)}%";

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 진행률 텍스트 + 숫자
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "진행률",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                percentText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.cyan.shade600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 하단: 다트 수 / 라운드 / 성공률
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                label: "다트 수",
                value: "$totalAttempts / $totalPlannedDarts 다트",
              ),
              _StatItem(
                label: "라운드",
                value: "ROUND $currentRound / $totalRounds",
              ),
              _StatItem(
                label: "성공률",
                value: successText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
