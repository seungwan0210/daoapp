// lib/presentation/screens/training/drills/drill_run_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/presentation/providers/training/training_drill_provider.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

import '../widgets/round_input_panel.dart'; // ⬅️ 새 위젯
import 'drill_result_screen.dart';

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
  late final TrainingDrillInputMode _mode;

  // 공통 진행 정보
  late final int _plannedRounds;
  late final int _dartsPerRound;
  int _currentRound = 1;

  // hitCount 모드용
  int _currentDart = 1;
  int _totalAttempts = 0;
  int _successCount = 0;

  // scoreOnly 모드용 (Count-Up 등)
  int _scoreTotal = 0;          // 누적 점수
  int _scoreRoundsCompleted = 0;
  int _currentRoundScore = 0;

  // cricketMarks 모드용 (크리켓 MPR 드릴)
  int _marksTotal = 0;          // 누적 마크
  int _marksRoundsCompleted = 0;
  int _currentRoundMarks = 0;

  bool _isStartingSession = false;
  bool _isFinishing = false;

  bool get _isHitMode => _mode == TrainingDrillInputMode.hitCount;
  bool get _isScoreMode => _mode == TrainingDrillInputMode.scoreOnly;
  bool get _isCricketMode => _mode == TrainingDrillInputMode.cricketMarks;

  int get _failCount => _totalAttempts - _successCount;

  bool get _hasAnyRecord {
    if (_isHitMode) return _totalAttempts > 0;
    if (_isScoreMode) return _scoreRoundsCompleted > 0;
    if (_isCricketMode) return _marksRoundsCompleted > 0;
    return false;
  }

  int _resolveRounds(TrainingDrillDefinition drill) {
    final extra = drill.extraConfig;
    final v = extra?['plannedRounds'] ?? extra?['rounds'];
    if (v is int && v > 0) return v;

    // 정의가 없으면 기본 8라운드
    return 8;
  }

  int _resolveDartsPerRound(TrainingDrillDefinition drill) {
    final extra = drill.extraConfig;
    final v = extra?['dartsPerRound'];
    if (v is int && v > 0) return v;

    // 정의가 없으면 기본 3다트
    return 3;
  }

  @override
  void initState() {
    super.initState();
    _mode = widget.drill.inputMode;
    _plannedRounds = _resolveRounds(widget.drill);
    _dartsPerRound = _resolveDartsPerRound(widget.drill);

    Future.microtask(() {
      if (!mounted) return;
      ref.read(trainingDrillProvider.notifier).clearSession();
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasAnyRecord) {
      ref.read(trainingDrillProvider.notifier).clearSession();
      return true;
    }

    if (_isFinishing || _isStartingSession) {
      return false;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("연습 종료"),
        content: const Text(
          "아직 결과 저장을 하지 않았습니다.\n"
              "이대로 나가면 이번 연습 기록은 저장되지 않습니다.\n\n"
              "그래도 종료할까요?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("계속 연습"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "저장 없이 종료",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      ref.read(trainingDrillProvider.notifier).clearSession();
      return true;
    }
    return false;
  }

  Future<void> _ensureSessionStarted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 정보가 없습니다. 다시 로그인 해주세요.')),
      );
      return;
    }

    final state = ref.read(trainingDrillProvider);
    if (state.activeSession != null || _isStartingSession) {
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
      if (mounted) {
        setState(() => _isStartingSession = false);
      }
    }
  }

  // =========================
  // hitCount 모드: 성공/실패
  // =========================
  Future<void> _recordHit(bool isSuccess) async {
    if (!_isHitMode) return;

    await _ensureSessionStarted();
    if (!mounted) return;

    setState(() {
      _totalAttempts++;
      if (isSuccess) _successCount++;

      if (_currentDart < _dartsPerRound) {
        _currentDart++;
      } else {
        if (_currentRound < _plannedRounds) {
          _currentRound++;
          _currentDart = 1;
        } else {
          _finishDrill(earlyFinish: false);
        }
      }
    });
  }

  // =========================
  // scoreOnly 모드: 점수 입력
  // =========================
  Future<void> _confirmScoreRound() async {
    if (!_isScoreMode) return;
    if (_currentRoundScore < 0) _currentRoundScore = 0;

    await _ensureSessionStarted();
    if (!mounted) return;

    setState(() {
      _scoreRoundsCompleted++;
      _scoreTotal += _currentRoundScore;

      if (_currentRound < _plannedRounds) {
        _currentRound++;
        _currentRoundScore = 0;
      } else {
        _finishDrill(earlyFinish: false);
      }
    });
  }

  // =========================
  // cricketMarks 모드: 마크 입력
  // =========================
  Future<void> _confirmMarksRound() async {
    if (!_isCricketMode) return;
    if (_currentRoundMarks < 0) _currentRoundMarks = 0;

    await _ensureSessionStarted();
    if (!mounted) return;

    setState(() {
      _marksRoundsCompleted++;
      _marksTotal += _currentRoundMarks;

      if (_currentRound < _plannedRounds) {
        _currentRound++;
        _currentRoundMarks = 0;
      } else {
        _finishDrill(earlyFinish: false);
      }
    });
  }

  // =========================
  // 세션 종료 / 저장
  // =========================
  Future<void> _finishDrill({required bool earlyFinish}) async {
    if (_isFinishing) return;

    final sessionState = ref.read(trainingDrillProvider);
    if (sessionState.activeSession == null && !_hasAnyRecord) {
      if (mounted) {
        ref.read(trainingDrillProvider.notifier).clearSession();
        Navigator.pop(context);
      }
      return;
    }

    setState(() => _isFinishing = true);

    try {
      final mode = _mode;

      late final int totalRounds;
      late final int totalDarts;
      int hitCount = 0;
      int totalMarks = 0;
      int totalScore = 0;

      if (_isHitMode) {
        final roundsByDarts =
            _totalAttempts ~/ _dartsPerRound; // 대략 라운드 수
        totalRounds =
            roundsByDarts.clamp(0, _plannedRounds); // 0~planned
        totalDarts = _totalAttempts;
        hitCount = _successCount;
      } else if (_isScoreMode) {
        totalRounds = _scoreRoundsCompleted;
        totalDarts = totalRounds * _dartsPerRound;
        totalScore = _scoreTotal;
      } else {
        totalRounds = _marksRoundsCompleted;
        totalDarts = totalRounds * _dartsPerRound;
        totalMarks = _marksTotal;
      }

      await ref.read(trainingDrillProvider.notifier).finishSession(
        inputMode: mode,
        totalRounds: totalRounds,
        totalDarts: totalDarts,
        hitCount: hitCount,
        totalMarks: totalMarks,
        totalScore: totalScore,
        additionalExtra: {
          'finishedEarly': earlyFinish,
          'plannedRounds': _plannedRounds,
          'plannedDartsPerRound': _dartsPerRound,
          'lastRoundIndex': _currentRound,
          'lastDartIndex': _currentDart,
          'hit_totalAttempts': _totalAttempts,
          'hit_successCount': _successCount,
          'score_roundsCompleted': _scoreRoundsCompleted,
          'score_total': _scoreTotal,
          'marks_roundsCompleted': _marksRoundsCompleted,
          'marks_total': _marksTotal,
        },
      );

      final updatedSession = ref.read(trainingDrillProvider).activeSession;
      if (!mounted) return;

      if (updatedSession != null) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DrillResultScreen(
              session: updatedSession,
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('세션 저장 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isFinishing = false);
      }
    }
  }

  void _onManualFinishPressed() {
    if (!_hasAnyRecord) {
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("연습 종료"),
          content: const Text(
            "아직 기록된 데이터가 없습니다.\n"
                "이번 세션을 저장하지 않고 종료할까요?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("계속 연습"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("저장 없이 종료"),
            ),
          ],
        ),
      ).then((confirm) {
        if (confirm == true) {
          ref.read(trainingDrillProvider.notifier).clearSession();
          Navigator.pop(context);
        }
      });
    } else {
      _finishDrill(earlyFinish: true);
    }
  }

  // =========================
  // UI 조각들
  // =========================
  List<Widget> _buildStatusChips() {
    if (_isHitMode) {
      final successRate =
      _totalAttempts == 0 ? 0.0 : _successCount / _totalAttempts;
      final successRateText = (successRate * 100).toStringAsFixed(1);

      return [
        Chip(
          label: const Text("성공:", style: TextStyle(color: Colors.black87)),
          avatar: Text(
            '$_successCount',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.green.withOpacity(0.15),
        ),
        Chip(
          label: const Text("실패:", style: TextStyle(color: Colors.black87)),
          avatar: Text(
            '$_failCount',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red.withOpacity(0.12),
        ),
        Chip(
          label: const Text("성공률:", style: TextStyle(color: Colors.black87)),
          avatar: Text(
            '$successRateText%',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.blueGrey.withOpacity(0.10),
        ),
      ];
    }

    if (_isScoreMode) {
      final darts = _scoreRoundsCompleted * _dartsPerRound;
      final ppd = darts == 0 ? 0.0 : _scoreTotal / darts;
      final threeAvg = ppd * 3;

      return [
        Chip(
          label: const Text("총 점수:", style: TextStyle(color: Colors.black87)),
          avatar: Text(
            '$_scoreTotal',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.indigo.withOpacity(0.12),
        ),
        Chip(
          label: const Text("진행 라운드:", style: TextStyle(color: Colors.black87)),
          avatar: Text(
            '$_scoreRoundsCompleted',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.blueGrey.withOpacity(0.10),
        ),
        Chip(
          label: const Text("PPD / 3다트:", style: TextStyle(color: Colors.black87)),
          avatar: Text(
            darts == 0
                ? '0.00'
                : '${ppd.toStringAsFixed(2)}/${threeAvg.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.teal.withOpacity(0.12),
        ),
      ];
    }

    if (_isCricketMode) {
      final mpr = _marksRoundsCompleted == 0
          ? 0.0
          : _marksTotal / _marksRoundsCompleted;

      return [
        Chip(
          label: const Text("총 마크:", style: TextStyle(color: Colors.black87)),
          avatar: Text(
            '$_marksTotal',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.deepPurple.withOpacity(0.12),
        ),
        Chip(
          label: const Text("진행 라운드:", style: TextStyle(color: Colors.black87)),
          avatar: Text(
            '$_marksRoundsCompleted',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.blueGrey.withOpacity(0.10),
        ),
        Chip(
          label: const Text("MPR:", style: TextStyle(color: Colors.black87)),
          avatar: Text(
            mpr.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.green.withOpacity(0.12),
        ),
      ];
    }

    return const [];
  }

  Widget _buildCenterContent() {
    if (_isHitMode) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "이번 다트 결과를 선택하세요",
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "ROUND $_currentRound · DART $_currentDart",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.cyan[700],
            ),
          ),
        ],
      );
    }

    if (_isScoreMode) {
      return RoundInputPanel(
        title: "Count-Up / 스코어 입력",
        currentRound: _currentRound,
        totalRounds: _plannedRounds,
        valueLabel: "이번 라운드 점수",
        currentValue: _currentRoundScore,
        onChanged: (v) {
          setState(() => _currentRoundScore = v);
        },
        onConfirm: (_isStartingSession || _isFinishing)
            ? null
            : _confirmScoreRound,
      );
    }

    if (_isCricketMode) {
      return RoundInputPanel(
        title: "크리켓 마크 입력",
        currentRound: _currentRound,
        totalRounds: _plannedRounds,
        valueLabel: "이번 라운드 마크 수",
        currentValue: _currentRoundMarks,
        onChanged: (v) {
          setState(() => _currentRoundMarks = v);
        },
        onConfirm: (_isStartingSession || _isFinishing)
            ? null
            : _confirmMarksRound,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBottomButtons() {
    if (_isHitMode) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_isStartingSession || _isFinishing)
                      ? null
                      : () => _recordHit(true),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    "성공",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_isStartingSession || _isFinishing)
                      ? null
                      : () => _recordHit(false),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text(
                    "실패",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade200,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: (_isStartingSession || _isFinishing)
                ? null
                : _onManualFinishPressed,
            child: Text(
              "드릴 종료하고 결과 저장",
              style: TextStyle(
                color: Colors.cyan[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    // scoreOnly / cricket 는 라운드별 [확정] 버튼으로만 진행하니까
    // 아래에는 "강제 종료 후 저장" 버튼만 두면 됨
    return Column(
      children: [
        const SizedBox(height: 10),
        TextButton(
          onPressed:
          (_isStartingSession || _isFinishing) ? null : _onManualFinishPressed,
          child: Text(
            "드릴 종료하고 결과 저장",
            style: TextStyle(
              color: Colors.cyan[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final drill = widget.drill;

    final progressRoundsText = '라운드 $_currentRound / $_plannedRounds';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          title: const Text(
            "드릴 진행",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 드릴 정보 카드
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drill.titleKo,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          drill.shortDescriptionKo,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.radio_button_checked,
                              size: 18,
                              color: Colors.cyan[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "목표: ${drill.targetLabel}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 진행 상황 카드
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          progressRoundsText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _buildStatusChips(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (_isStartingSession)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.cyan),
                    ),
                  ),

                const SizedBox(height: 8),

                // 중앙 영역 (스크롤 가능)
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _buildCenterContent(),
                      ),
                    ),
                  ),
                ),

                // 하단 버튼들
                _buildBottomButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
