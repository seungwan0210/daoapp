// lib/presentation/screens/training/drills/drill_run_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/presentation/providers/training/training_drill_provider.dart';
// 🔹 임포트 경로 수정
import 'package:daoapp/l10n/app_localizations.dart';

import 'drill_result_screen.dart';
import 'widgets/core/drill_header_card.dart';
import 'widgets/core/generic_hit_panel.dart';

// specialized
import 'widgets/specialized/double_clock_panel.dart';
import 'widgets/specialized/checkout_practice_panel.dart';
import 'widgets/specialized/t20_focus_panel.dart';
import 'widgets/specialized/fixed_route_panel.dart';
import 'widgets/specialized/score_game_panel.dart';
import 'widgets/specialized/quadrant_board_panel.dart';
import 'widgets/specialized/top_bottom_board_panel.dart';
import 'widgets/specialized/around_board_panel.dart';
import 'widgets/specialized/countup_round_score_panel.dart';
import 'widgets/specialized/sector_cycle_panel.dart';
import 'widgets/specialized/full_cricket_training_panel.dart';
import 'widgets/specialized/bull_split_panel.dart';
import 'widgets/specialized/score_game_multi_set_panel.dart';

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

  int _effectiveRounds = 0;

  bool _isStartingSession = false;
  bool _isFinishing = false;

  late final int _totalPlannedDarts;
  late final ValueNotifier<int> _thrownDartsNotifier;
  Map<String, dynamic>? _sessionExtraData;
  final List<bool> _hitHistory = <bool>[];

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
    final mode = extra['mode'] as String?;
    final gameType = extra['gameType'] as String?;
    final targetArea = extra['targetArea'] as String?;

    if (targetArea == 'bull_split') {
      if (extra['totalDarts'] is num) {
        return (extra['totalDarts'] as num).toInt();
      }
      return 60;
    }

    if (widget.drill.inputMode == TrainingDrillInputMode.scoreOnly &&
        gameType != null &&
        gameType.startsWith('501_multi')) {
      final totalSets = (extra['totalSets'] as num?)?.toInt() ?? 10;
      return totalSets;
    }

    if (extra['segments'] is List && extra['dartsPerSegment'] is num) {
      final segments = (extra['segments'] as List).length;
      final perSeg = (extra['dartsPerSegment'] as num).toInt();
      if (segments > 0 && perSeg > 0) return segments * perSeg;
    }

    if (mode == 'checkout_practice') {
      if (extra['totalSets'] is num) return (extra['totalSets'] as num).toInt();
      return 20;
    }

    if (mode == 'top_bottom') {
      if (extra['totalDartsPerArea'] is num) {
        final perArea = (extra['totalDartsPerArea'] as num).toInt();
        if (perArea > 0) return perArea * 2;
      }
      return 60;
    }

    if (extra['totalDarts'] is num) return (extra['totalDarts'] as num).toInt();

    return 60;
  }

  double get _progress => _totalPlannedDarts == 0 ? 0 : _totalAttempts / _totalPlannedDarts;
  double get _successRate => _totalAttempts == 0 ? 0 : _successCount / _totalAttempts;
  bool get _hasAnyRecord => _totalAttempts > 0 || _currentScore > 0 || _currentMarks > 0;
  bool get _canUndoLastHit => !_isStartingSession && !_isFinishing && _hitHistory.isNotEmpty;

  void _recalcRoundDartFromAttempts() {
    _currentRound = (_totalAttempts ~/ 3) + 1;
    _currentDart = (_totalAttempts % 3) + 1;
  }

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
      _hitHistory.add(success);
      _totalAttempts++;
      if (success) _successCount++;
      _thrownDartsNotifier.value = _totalAttempts;
      _recalcRoundDartFromAttempts();
    });

    if (_totalAttempts >= _totalPlannedDarts) {
      await _finishDrill(earlyFinish: false);
    }
  }

  void _undoLastHit() {
    if (!_canUndoLastHit) return;
    setState(() {
      final bool last = _hitHistory.removeLast();
      if (_totalAttempts > 0) _totalAttempts--;
      if (last && _successCount > 0) _successCount--;
      _thrownDartsNotifier.value = _totalAttempts;
      _recalcRoundDartFromAttempts();
    });
  }

  Future<void> _submitScoreGame({required int value, required bool isDartsMode}) async {
    await _ensureSessionStarted();
    if (!mounted) return;
    setState(() {
      if (isDartsMode) {
        _totalAttempts = value;
        _currentScore = 501;
      } else {
        _currentScore = value;
        _totalAttempts = _totalPlannedDarts;
      }
      _thrownDartsNotifier.value = _totalAttempts;
      _recalcRoundDartFromAttempts();
    });
    await _finishDrill(earlyFinish: false);
  }

  Future<void> _finishDrill({required bool earlyFinish}) async {
    if (!mounted || _isFinishing) return;
    setState(() => _isFinishing = true);

    try {
      await _ensureSessionStarted();
      if (!mounted) return;

      final s = AppLocalizations.of(context)!;
      await ref.read(trainingDrillProvider.notifier).finishSession(
        inputMode: widget.drill.inputMode,
        totalRounds: _calculateRoundsToSave(),
        totalDarts: _totalAttempts,
        hitCount: _successCount,
        totalScore: _currentScore,
        totalMarks: _currentMarks,
        additionalExtra: {
          'finishedEarly': earlyFinish,
          'totalPlannedDarts': _totalPlannedDarts,
          ...?_sessionExtraData,
        },
      );

      final session = ref.read(trainingDrillProvider).activeSession;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.err_save_failed}: $e')));
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  int _calculateRoundsToSave() {
    if (_effectiveRounds > 0) return _effectiveRounds;
    final extra = widget.drill.extraConfig ?? {};
    if (widget.drill.inputMode == TrainingDrillInputMode.scoreOnly && (extra['gameType'] as String? ?? '').startsWith('501_multi')) {
      return _totalAttempts;
    }
    return (_totalAttempts + 2) ~/ 3;
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
    final s = AppLocalizations.of(context)!;

    if (mode == 'quadrant') {
      return QuadrantBoardPanel(
        totalDarts: _totalPlannedDarts,
        thrownDartsNotifier: _thrownDartsNotifier,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
        canUndo: _canUndoLastHit,
        onUndo: _undoLastHit,
      );
    }

    if (mode == 'top_bottom') {
      return TopBottomBoardPanel(
        totalDarts: _totalPlannedDarts,
        thrownDartsNotifier: _thrownDartsNotifier,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
        canUndo: _canUndoLastHit,
        onUndo: _undoLastHit,
      );
    }

    if (mode == 'around_board') {
      return AroundBoardPanel(
        sequence: ((extra['sequence'] as List?)?.map((e) => e.toString()).toList()) ?? (List.generate(20, (i) => '${i + 1}')..add('SB')),
        thrownDartsNotifier: _thrownDartsNotifier,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        canUndo: _canUndoLastHit,
        onUndo: _undoLastHit,
        onFinishPressed: _onManualFinish,
        onCompleted: () => _finishDrill(earlyFinish: false),
        isBusy: isBusy,
      );
    }

    if (mode == 'sector_cycle' || widget.drill.id.contains('loop') || widget.drill.id.contains('switch')) {
      final targets = ((extra['segments'] as List?)?.map((e) => e.toString()).toList()) ?? const <String>[];
      return SectorCyclePanel(
        title: widget.drill.titleKo, // 언어팩 translate 대신 모델 데이터 사용 권장
        targets: targets,
        loopSize: (extra['loopSize'] as num?)?.toInt() ?? targets.length,
        totalDarts: _totalPlannedDarts,
        thrownDartsNotifier: _thrownDartsNotifier,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
        canUndo: _canUndoLastHit,
        onUndo: _undoLastHit,
      );
    }

    if (widget.drill.id.contains('double_clock')) {
      return DoubleClockPanel(
        startFrom: widget.drill.id.contains('back') ? 11 : 1,
        reverse: false,
        includeBull: true,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onUndoResult: (bool wasSuccess) {
          setState(() {
            if (_totalAttempts > 0) _totalAttempts--;
            if (wasSuccess && _successCount > 0) _successCount--;
            _thrownDartsNotifier.value = _totalAttempts;
            _recalcRoundDartFromAttempts();
          });
        },
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    if (mode == 'bull_split' || extra['targetArea'] == 'bull_split') {
      return BullSplitPanel(
        title: widget.drill.targetLabel,
        totalDarts: _totalPlannedDarts,
        targetSbPlusDb: (extra['targetSbPlusDb'] as num?)?.toInt(),
        targetDb: (extra['targetDb'] as num?)?.toInt(),
        isBusy: isBusy,
        onProgress: (sHits, dHits, thrown) {
          setState(() {
            _totalAttempts = thrown;
            _successCount = sHits + dHits;
            _thrownDartsNotifier.value = _totalAttempts;
            _recalcRoundDartFromAttempts();
          });
        },
        onCompleted: (sHits, dHits, thrown) {
          setState(() {
            _totalAttempts = thrown;
            _successCount = sHits + dHits;
            _currentMarks = dHits;
            _recalcRoundDartFromAttempts();
            _sessionExtraData = {'sBullHits': sHits, 'dBullHits': dHits, 'totalDarts': thrown};
          });
        },
        onFinishPressed: _onManualFinish,
      );
    }

    if (mode == 'checkout_practice') {
      return CheckoutPracticePanel(
        minScore: (extra['minScore'] as num?)?.toInt() ?? 60,
        maxScore: (extra['maxScore'] as num?)?.toInt() ?? 100,
        maxDartsPerSet: (extra['maxDartsPerSet'] as num?)?.toInt() ?? 6,
        totalSets: (extra['totalSets'] as num?)?.toInt() ?? 30,
        requireDoubleOut: extra['requireDoubleOut'] as bool? ?? true,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onUndoSetResult: (bool wasSuccess) {
          setState(() {
            if (_totalAttempts > 0) _totalAttempts--;
            if (wasSuccess && _successCount > 0) _successCount--;
            _thrownDartsNotifier.value = _totalAttempts;
            _recalcRoundDartFromAttempts();
          });
        },
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    if (widget.drill.inputMode == TrainingDrillInputMode.cricketMarks) {
      return FullCricketTrainingPanel(
        isBusy: isBusy,
        title: widget.drill.titleKo,
        onRoundUpdated: (marks, rounds) {
          setState(() {
            _currentMarks = marks;
            _totalAttempts = rounds * 3;
            _effectiveRounds = rounds;
            _thrownDartsNotifier.value = _totalAttempts;
            _recalcRoundDartFromAttempts();
          });
        },
        onCompleted: (marks, rounds) {
          setState(() {
            _currentMarks = marks;
            _totalAttempts = rounds * 3;
            _effectiveRounds = rounds;
            _thrownDartsNotifier.value = _totalAttempts;
            _recalcRoundDartFromAttempts();
          });
        },
        onFinishPressed: _onManualFinish,
      );
    }

    if (widget.drill.inputMode == TrainingDrillInputMode.scoreOnly) {
      final is501Multi = (extra['gameType'] as String? ?? '').startsWith('501_multi');
      if (is501Multi) {
        return ScoreGameMultiSetPanel(
          title: widget.drill.titleKo,
          totalSets: (extra['totalSets'] as num?)?.toInt() ?? 10,
          // 🔹 누락된 파라미터 추가
          minDartsPerLeg: (extra['minDartsPerLeg'] as num?)?.toInt() ?? 9,
          maxDartsPerLeg: (extra['maxDartsPerLeg'] as num?)?.toInt() ?? 30,
          successThresholdDarts: (extra['successThresholdDarts'] as num?)?.toInt() ?? 18,
          onProgress: (perLeg, success, played) {
            setState(() {
              _totalAttempts = played;
              _successCount = success;
              _currentScore = perLeg.fold<int>(0, (sum, d) => sum + d);
              _thrownDartsNotifier.value = _totalAttempts;
              _recalcRoundDartFromAttempts();
            });
          },
          onCompleted: (perLeg, success, played) async {
            await _ensureSessionStarted();
            setState(() {
              _totalAttempts = played;
              _successCount = success;
              _currentScore = perLeg.fold<int>(0, (sum, d) => sum + d);
              _recalcRoundDartFromAttempts();
            });
            _sessionExtraData = {'perLegDarts': perLeg, 'successSets': success};
            await _finishDrill(earlyFinish: false);
          },
          onFinishPressed: _onManualFinish,
          isBusy: isBusy,
        );
      }
      return ScoreGamePanel(
        title: s.calc_title,
        valueLabel: s.drill_stat_darts,
        // 🔹 누락된 파라미터 추가
        helperText: s.drill_hint_score_input,
        initialValue: 0,
        minValue: 0,      // 🔹 추가
        maxValue: 1440,   // 🔹 추가 (카운트업 최대치 고려)
        onSubmit: (value) => _submitScoreGame(value: value, isDartsMode: false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    return GenericHitPanel(
      targetLabel: widget.drill.targetLabel,
      currentRound: _currentRound,
      totalRounds: (_totalPlannedDarts / 3).ceil(),
      thrownDarts: _totalAttempts,
      totalDarts: _totalPlannedDarts,
      onHitSuccess: () => _recordHit(true),
      onHitFail: () => _recordHit(false),
      onFinishPressed: _onManualFinish,
      isBusy: isBusy,
      canUndo: _canUndoLastHit,
      onUndo: _undoLastHit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final extra = widget.drill.extraConfig ?? {};
    final bool isSetMode = extra['mode'] == 'checkout_practice' || (extra['gameType'] as String? ?? '').startsWith('501_multi');

    return WillPopScope(
      onWillPop: () async {
        if (_hasAnyRecord) {
          final exit = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(s.exit_drill_title),
              content: Text(s.exit_drill_msg),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.common_cancel)),
                TextButton(onPressed: () => Navigator.pop(context, true), child: Text(s.common_delete, style: const TextStyle(color: Colors.red))),
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
        appBar: AppBar(title: Text(s.drill_run_title), centerTitle: true, elevation: 0.5),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              DrillHeaderCard(drill: widget.drill, tier: widget.tier),
              const SizedBox(height: 16),
              _InlineProgressCard(
                progress: _progress,
                totalAttempts: _totalAttempts,
                totalPlannedDarts: _totalPlannedDarts,
                currentRound: isSetMode ? (_totalAttempts + 1) : _currentRound,
                totalRounds: isSetMode ? _totalPlannedDarts : (_totalPlannedDarts / 3).ceil(),
                successRate: _successRate,
                attemptsUnitLabel: isSetMode ? s.drill_stat_rounds : s.drill_stat_darts,
              ),
              const SizedBox(height: 4),
              _buildDrillPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineProgressCard extends StatelessWidget {
  final double progress;
  final int totalAttempts;
  final int totalPlannedDarts;
  final int currentRound;
  final int totalRounds;
  final double successRate;
  final String attemptsUnitLabel;

  const _InlineProgressCard({
    required this.progress,
    required this.totalAttempts,
    required this.totalPlannedDarts,
    required this.currentRound,
    required this.totalRounds,
    required this.successRate,
    required this.attemptsUnitLabel,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.drill_progress_title, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              Text("${(progress * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 6, backgroundColor: Colors.grey.shade200),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(label: attemptsUnitLabel, value: "$totalAttempts / $totalPlannedDarts"),
              _StatItem(label: s.drill_stat_rounds, value: "ROUND $currentRound / $totalRounds"),
              _StatStatItem(label: s.drill_stat_success, value: "${(successRate * 100).toStringAsFixed(1)}%"),
            ],
          ),
        ],
      ),
    );
  }
}

// 🔹 _StatStatItem 오타 수정 (전 코드에서 오타 발생)
class _StatStatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatStatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}