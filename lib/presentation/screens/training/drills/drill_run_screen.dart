// lib/presentation/screens/training/drills/drill_run_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/presentation/providers/training/training_drill_provider.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

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
  int _currentRound = 1;
  int _currentDart = 1;

  int _totalAttempts = 0;
  int _successCount = 0;
  int _failCount = 0;

  bool _isStartingSession = false;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    // 혹시 남아있던 세션 초기화
    ref.read(trainingDrillProvider.notifier).clearSession();
  }

  Future<bool> _onWillPop() async {
    // 시도한 다트가 없으면 그냥 나가도 됨
    if (_totalAttempts == 0) {
      ref.read(trainingDrillProvider.notifier).clearSession();
      return true;
    }

    // 이미 저장 중이면 뒤로가기 막기
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

    setState(() {
      _isStartingSession = true;
    });

    try {
      await ref.read(trainingDrillProvider.notifier).startSession(
        userId: user.uid,
        drill: widget.drill,
        tierAtThatTime: widget.tier,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStartingSession = false;
        });
      }
    }
  }

  Future<void> _recordHit(bool isSuccess) async {
    // 세션이 아직 없으면 먼저 생성
    await _ensureSessionStarted();

    if (!mounted) return;

    setState(() {
      _totalAttempts++;
      if (isSuccess) {
        _successCount++;
      } else {
        _failCount++;
      }

      // 다음 다트 / 다음 라운드로 진행
      if (_currentDart < widget.drill.dartsPerRound) {
        _currentDart++;
      } else {
        // 라운드 종료
        if (_currentRound < widget.drill.rounds) {
          _currentRound++;
          _currentDart = 1;
        } else {
          // 모든 라운드 & 다트 소진 → 자동 종료
          _finishDrill(earlyFinish: false);
        }
      }
    });
  }

  Future<void> _finishDrill({required bool earlyFinish}) async {
    if (_isFinishing) return;
    final sessionState = ref.read(trainingDrillProvider);
    if (sessionState.activeSession == null) {
      // 세션이 없고, 시도도 없으면 그냥 나가기
      if (_totalAttempts == 0) {
        if (mounted) {
          ref.read(trainingDrillProvider.notifier).clearSession();
          Navigator.pop(context);
        }
      }
      return;
    }

    setState(() {
      _isFinishing = true;
    });

    try {
      await ref.read(trainingDrillProvider.notifier).finishSession(
        totalAttempts: _totalAttempts,
        successCount: _successCount,
        failCount: _failCount,
        additionalExtra: {
          'finishedEarly': earlyFinish,
          'totalRoundsPlanned': widget.drill.rounds,
          'totalDartsPlanned':
          widget.drill.rounds * widget.drill.dartsPerRound,
          'roundsCompleted': _currentRound,
          'lastDartIndex': _currentDart,
        },
      );

      final updatedSession = ref.read(trainingDrillProvider).activeSession;

      if (!mounted) return;

      if (updatedSession != null) {
        // 결과 화면으로 이동 (Run 화면을 대체)
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DrillResultScreen(
              session: updatedSession,
              drill: widget.drill,
              tier: widget.tier,
            ),
          ),
        );
        // 결과에서 돌아온 뒤에는 세션 클리어
        ref.read(trainingDrillProvider.notifier).clearSession();
      } else {
        // 세션이 없으면 그냥 나감
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('세션 저장 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFinishing = false;
        });
      }
    }
  }

  void _onManualFinishPressed() {
    if (_totalAttempts == 0) {
      // 시도 기록이 없으면 저장 없이 종료할지 물어봄
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("연습 종료"),
          content: const Text(
            "아직 기록된 다트가 없습니다.\n"
                "이번 세션을 저장하지 않고 종료할까요?",
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

  @override
  Widget build(BuildContext context) {
    final drill = widget.drill;
    final progressRoundsText = '라운드 $_currentRound / ${drill.rounds}';
    final progressDartsText =
        '현재 다트 $_currentDart / ${drill.dartsPerRound}';

    final successRate =
    _totalAttempts == 0 ? 0.0 : _successCount / _totalAttempts;
    final successRateText = (successRate * 100).toStringAsFixed(1);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white, // 🔹 라이트 모드 배경
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
                            Text(
                              "목표: ${drill.targetLabel}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
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
                        const SizedBox(height: 6),
                        Text(
                          progressDartsText,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 🔹 Row → Wrap 로 변경해서 가로 오버플로우 방지
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Chip(
                              label: const Text(
                                "성공:",
                                style: TextStyle(color: Colors.black87),
                              ),
                              avatar: Text(
                                '$_successCount',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor:
                              Colors.green.withOpacity(0.15),
                            ),
                            Chip(
                              label: const Text(
                                "실패:",
                                style: TextStyle(color: Colors.black87),
                              ),
                              avatar: Text(
                                '$_failCount',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor:
                              Colors.red.withOpacity(0.12),
                            ),
                            Chip(
                              label: const Text(
                                "성공률:",
                                style: TextStyle(color: Colors.black87),
                              ),
                              avatar: Text(
                                '$successRateText%',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor:
                              Colors.blueGrey.withOpacity(0.10),
                            ),
                          ],
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
                      child: CircularProgressIndicator(
                        color: Colors.cyan,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // 중앙에 큼직하게 현재 라운드/다트 안내
                Expanded(
                  child: Center(
                    child: Column(
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
                    ),
                  ),
                ),

                // 성공 / 실패 버튼
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.shade200,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
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
            ),
          ),
        ),
      ),
    );
  }
}
