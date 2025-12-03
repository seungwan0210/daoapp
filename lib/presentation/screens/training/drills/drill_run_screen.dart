// lib/presentation/screens/training/drills/drill_run_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/presentation/providers/training/training_drill_provider.dart';

import 'drill_result_screen.dart';
import 'widgets/core/drill_header_card.dart';
import 'widgets/core/drill_progress_card.dart';
import 'widgets/core/generic_hit_panel.dart';
import 'widgets/specialized/triple_switch_panel.dart';
import 'widgets/specialized/double_clock_panel.dart';
import 'widgets/specialized/random_checkout_panel.dart';
import 'widgets/specialized/full_cricket_panel.dart';
import 'widgets/specialized/t20_focus_panel.dart';
import 'widgets/specialized/fixed_route_panel.dart';

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

  @override
  void initState() {
    super.initState();
    _totalPlannedDarts = _calculateTotalPlannedDarts();
    Future.microtask(() => ref.read(trainingDrillProvider.notifier).clearSession());
  }

  int _calculateTotalPlannedDarts() {
    final extra = widget.drill.extraConfig ?? {};

    if (widget.drill.recommendedDarts != null) return widget.drill.recommendedDarts!;
    if (extra['totalDarts'] is num) return (extra['totalDarts'] as num).toInt();
    if (extra['sets'] is num && extra['dartsPerSet'] is num) {
      return (extra['sets'] as num).toInt() * (extra['dartsPerSet'] as num).toInt();
    }
    if (extra['rounds'] is num) {
      final dpr = (extra['dartsPerRound'] as num?)?.toInt() ?? 3;
      return (extra['rounds'] as num).toInt() * dpr;
    }
    return 60;
  }

  double get _progress => _totalPlannedDarts == 0 ? 0 : _totalAttempts / _totalPlannedDarts;
  double get _successRate => _totalAttempts == 0 ? 0 : _successCount / _totalAttempts;

  bool get _hasAnyRecord => _totalAttempts > 0 || _currentScore > 0 || _currentMarks > 0;

  Future<void> _ensureSessionStarted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isStartingSession || ref.read(trainingDrillProvider).activeSession != null) return;

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
            builder: (_) => DrillResultScreen(session: session, drill: widget.drill, tier: widget.tier),
          ),
        );
        ref.read(trainingDrillProvider.notifier).clearSession();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
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

    return switch (widget.drill.id) {
      'elite_t20_t19_triple_switch' => TripleSwitchPanel(
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      ),
      'chall_double_clock_full' => DoubleClockPanel(
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      ),
      'chall_checkout_60_100_random' => RandomCheckoutPanel(
        minScore: 60,
        maxScore: 100,
        maxDarts: 6,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      ),
      'chall_cricket_full_20_15_bull' => FullCricketPanel(
        onMarksRecorded: (marks) {
          setState(() => _currentMarks += marks);
          _recordHit(true);
        },
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      ),
      'pro_t20_focus_100' => T20FocusPanel(
        totalDarts: 100,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      ),
      'master_route_170' => FixedRoutePanel(
        route: ['T20', 'T20', 'Bull'],
        targetScore: "170",
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      ),
    // 모든 기본 드릴 → 새 GenericHitPanel 사용!
      _ => GenericHitPanel(
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
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasAnyRecord) {
          final exit = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("연습 종료"),
              content: const Text("기록이 저장되지 않습니다.\n계속하시겠습니까?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("종료", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (exit == true) ref.read(trainingDrillProvider.notifier).clearSession();
          return exit ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("드릴 진행", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: DrillHeaderCard(drill: widget.drill, tier: widget.tier),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DrillProgressCard(
                  progress: _progress,
                  thrownDarts: _totalAttempts,
                  totalDarts: _totalPlannedDarts,
                  successRate: _successRate,
                  currentRound: _currentRound,
                  totalRounds: (_totalPlannedDarts / 3).ceil(),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildDrillPanel(),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}