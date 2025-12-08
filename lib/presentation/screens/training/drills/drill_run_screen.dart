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
  int _totalAttempts = 0; // ✅ "시도 수" (다트 or 세트)
  int _successCount = 0;
  int _currentScore = 0;
  int _currentMarks = 0;

  bool _isStartingSession = false;
  bool _isFinishing = false;

  /// 진행률의 분모 (대부분 "총 다트 수", checkout_practice는 "총 세트 수")
  late final int _totalPlannedDarts;

  /// 패널들이 공통으로 참조하는 다트 수
  late final ValueNotifier<int> _thrownDartsNotifier;

  /// ✅ 특수 드릴에서 추가로 기록하고 싶은 정보(SBull/DBull 등)를 담는 용도
  Map<String, dynamic>? _sessionExtraData;

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

    // ✅ Bull SBull/DBull 분리 기록 드릴
    if (targetArea == 'bull_split') {
      if (extra['totalDarts'] is num) {
        return (extra['totalDarts'] as num).toInt(); // 예: 60, 90
      }
      if (widget.drill.recommendedDarts != null &&
          widget.drill.recommendedDarts! > 0) {
        return widget.drill.recommendedDarts!;
      }
      return 60; // fallback
    }

    // ✅ 0) 501 멀티 세트 드릴: "세트 수" 기준으로 진행률 계산
    if (widget.drill.inputMode == TrainingDrillInputMode.scoreOnly &&
        gameType != null &&
        gameType.startsWith('501_multi')) {
      final totalSets =
          (extra['totalSets'] as num?)?.toInt() ??
              (extra['suggestedSets'] as num?)?.toInt() ??
              10; // 기본 10세트
      return totalSets;
    }

    // ✅ 0) 세그먼트 + dartsPerSegment 기반 드릴 (예: D16/D20 각 60발)
    if (extra['segments'] is List && extra['dartsPerSegment'] is num) {
      final segments = (extra['segments'] as List).length;
      final perSeg = (extra['dartsPerSegment'] as num).toInt();
      if (segments > 0 && perSeg > 0) {
        return segments * perSeg;
      }
    }

    // ✅ 1) 체크아웃 연습: "세트 수" 기준으로 진행률 계산
    if (mode == 'checkout_practice') {
      if (extra['totalSets'] is num) {
        return (extra['totalSets'] as num).toInt();
      }
      return 20; // 기본값
    }

    // ✅ 2) Top / Bottom 전용: 영역당 다트 수 * 2
    if (mode == 'top_bottom') {
      if (extra['totalDartsPerArea'] is num) {
        final perArea = (extra['totalDartsPerArea'] as num).toInt();
        if (perArea > 0) return perArea * 2;
      }
      if (widget.drill.recommendedDarts != null &&
          widget.drill.recommendedDarts! > 0) {
        return widget.drill.recommendedDarts!;
      }
      return 60;
    }

    // ✅ 3) 나머지 일반 드릴들
    if (widget.drill.recommendedDarts != null &&
        widget.drill.recommendedDarts! > 0) {
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

      // 패널들에 공유 (다트/세트 공용 카운트)
      _thrownDartsNotifier.value = _totalAttempts;

      // 기본 라운드/다트 진행 (대부분의 드릴에서 사용)
      if (_currentDart < 3) {
        _currentDart++;
      } else {
        _currentDart = 1;
        _currentRound++;
      }

      // ✅ attempts 기준으로 종료 체크
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
      // ✅ 어떤 패널이든 finish 전에 세션은 반드시 시작
      await _ensureSessionStarted();

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
          // ✅ Bull 드릴 등에서 세팅한 추가 데이터(SBull/DBull 등)도 같이 저장
          ...?_sessionExtraData,
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
    final targetArea = extra['targetArea'] as String?; // 🔹 이 줄 추가

    // 4분할 보드
    if (mode == 'quadrant') {
      return QuadrantBoardPanel(
        key: const ValueKey('quadrant_panel'),
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
        key: const ValueKey('top_bottom_panel'),
        totalDarts: _totalPlannedDarts,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
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

    // ✅ 공통 SectorCyclePanel (mode 기반)
    if (mode == 'sector_cycle') {
      final targets =
          ((extra['targets'] as List?)?.map((e) => e.toString()).toList()) ??
              const <String>[];

      final displayLabel =
          (extra['label'] as String?) ?? widget.drill.targetLabel;
      final loopSize = (extra['loopSize'] as num?)?.toInt() ?? targets.length;

      return SectorCyclePanel(
        title: displayLabel,
        targets: targets,
        totalDarts: _totalPlannedDarts,
        loopSize: loopSize,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // learner_20_19_switch : 상단 3섹터 루프 (20/19/18)
    if (widget.drill.id == 'learner_20_19_switch') {
      return SectorCyclePanel(
        title: '상단 3섹터 루프 (20/19/18)',
        targets: const ['20', '19', '18'],
        loopSize: 3,
        totalDarts: _totalPlannedDarts,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // learner_17_16_15_line : 중단 3섹터 루프 (17/16/15)
    if (widget.drill.id == 'learner_17_16_15_line') {
      return SectorCyclePanel(
        title: '중단 3섹터 루프 (17/16/15)',
        targets: const ['17', '16', '15'],
        loopSize: 3,
        totalDarts: _totalPlannedDarts,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // comp_triple_20_19_18_line : 트리플 루프 (T20/T19/T18)
    if (widget.drill.id == 'comp_triple_20_19_18_line') {
      return SectorCyclePanel(
        title: '트리플 루프 (T20/T19/T18)',
        targets: const ['T20', 'T19', 'T18'],
        loopSize: 3,
        totalDarts: _totalPlannedDarts,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // elite_t20_t19_triple_switch
    if (widget.drill.id == 'elite_t20_t19_triple_switch') {
      return SectorCyclePanel(
        title: '트리플 스위치',
        targets: const ['T20', 'T19', 'T18'],
        totalDarts: _totalPlannedDarts,
        loopSize: 3,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // 챌린저: 더블 시계 풀 (D1 → D20 → DBull)
    if (widget.drill.id == 'chall_double_clock_full') {
      return DoubleClockPanel(
        startFrom: 1, // D1부터
        reverse: false,
        includeBull: true,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // 컴페티터: 더블 시계 전반부 (D1 → D10)
    if (widget.drill.id == 'comp_double_clock_half') {
      return DoubleClockPanel(
        startFrom: 1,
        reverse: false,
        includeBull: true,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // 컴페티터: 더블 시계 후반부 (D11 → D20)
    if (widget.drill.id == 'comp_double_clock_back') {
      return DoubleClockPanel(
        startFrom: 11,
        reverse: false,
        includeBull: true,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // ✅ Bull SBull / DBull 분리 기록 드릴
    if (mode == 'bull_split' || targetArea == 'bull_split') {
      final targetSbPlusDb = (extra['targetSbPlusDb'] as num?)?.toInt();
      final targetDb = (extra['targetDb'] as num?)?.toInt();
      final int totalDarts =
          (extra['totalDarts'] as num?)?.toInt() ?? _totalPlannedDarts;

      return BullSplitPanel(
        title: widget.drill.targetLabel.isNotEmpty
            ? widget.drill.targetLabel
            : widget.drill.titleKo,
        totalDarts: totalDarts,
        targetSbPlusDb: targetSbPlusDb,
        targetDb: targetDb,
        isBusy: isBusy,
        onProgress: (int sBullHits, int dBullHits, int thrownDarts) {
          setState(() {
            _totalAttempts = thrownDarts;
            _successCount = sBullHits + dBullHits;
            _thrownDartsNotifier.value = _totalAttempts;
          });
        },
        onCompleted: (int sBullHits, int dBullHits, int thrownDarts) {
          setState(() {
            _totalAttempts = thrownDarts;
            _successCount = sBullHits + dBullHits;
            _currentMarks = dBullHits;

            _sessionExtraData = {
              'sBullHits': sBullHits,
              'dBullHits': dBullHits,
              'totalDarts': thrownDarts,
              if (targetSbPlusDb != null) 'targetSbPlusDb': targetSbPlusDb,
              if (targetDb != null) 'targetDb': targetDb,
            };
          });
        },
        onFinishPressed: _onManualFinish,
      );
    }

    // 체크아웃 연습 패널 (실제 점수 입력 + 버튼 방식)
    if (mode == 'checkout_practice') {
      return CheckoutPracticePanel(
        minScore: (extra['minScore'] as num?)?.toInt() ?? 60,
        maxScore: (extra['maxScore'] as num?)?.toInt() ?? 100,
        maxDartsPerSet: (extra['maxDartsPerSet'] as num?)?.toInt() ?? 6,
        totalSets: (extra['totalSets'] as num?)?.toInt() ?? 30,
        requireDoubleOut: extra['requireDoubleOut'] as bool? ?? true,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // ==========================
    // T20 / 멀티 세그먼트 집중 패널
    // ==========================
    final segments = (extra['segments'] as List?)?.cast<String>();
    final dartsPerSegment = (extra['dartsPerSegment'] as num?)?.toInt();

    // 🔹 1) 단일 T20 포커스 드릴 (기존과 동일)
    final isSingleT20 =
        segments != null && segments.length == 1 && segments.first == 'T20';

    if (isSingleT20 && dartsPerSegment == null) {
      final totalDarts =
          (extra['totalDarts'] as num?)?.toInt() ?? _totalPlannedDarts;
      return T20FocusPanel(
        totalDarts: totalDarts,
        targetLabel: 'T20',
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // 🔹 2) 멀티 세그먼트 집중 드릴 (예: D16/D20 각 60발)
    if (segments != null &&
        segments.isNotEmpty &&
        dartsPerSegment != null &&
        dartsPerSegment > 0) {
      return T20FocusPanel(
        totalDarts: _totalPlannedDarts,
        segments: segments,
        dartsPerSegment: dartsPerSegment,
        onHitSuccess: () => _recordHit(true),
        onHitFail: () => _recordHit(false),
        onFinishPressed: _onManualFinish,
        isBusy: isBusy,
      );
    }

    // 1) 20↔19 체인지 전용 크리켓 드릴
    if (widget.drill.id == 'comp_cricket_20_19') {
      return FullCricketTrainingPanel(
        isBusy: isBusy,
        title: widget.drill.titleKo, // '크리켓 20↔19 실전 훈련'

        // 🔹 1~7R: 20 → 19 → 20 → 19 → 20 → 19 → 20
        fixedTargets: const ['20', '19', '20', '19', '20', '19', '20'],

        // 🔹 8R 자유 라운드: 20 또는 19 중 선택
        freeRoundChoices: const ['20', '19'],

        // 🔹 라운드 하나 확정될 때마다 진행률/통계 갱신
        onRoundUpdated: (int totalMarks, int playedRounds) {
          setState(() {
            _currentMarks = totalMarks;
            _totalAttempts = playedRounds * 3; // 1R = 3다트
            _thrownDartsNotifier.value = _totalAttempts;
          });
        },

        // 🔥 8R까지 다 채우거나 "드릴 종료" 눌렀을 때 최종 결과
        onCompleted: (int totalMarks, int playedRounds) {
          setState(() {
            _currentMarks = totalMarks; // 총 마크
            _totalAttempts = playedRounds * 3;
            _thrownDartsNotifier.value = _totalAttempts;
          });
        },
        onFinishPressed: _onManualFinish,
      );
    }

    // 2) 풀 크리켓 8R + 엘리트/프로/마스터 MPR 드릴 (기본 패턴 사용)
    if (widget.drill.id == 'chall_cricket_full_20_15_bull' ||
        widget.drill.id == 'elite_cricket_power_marks_15r' ||
        widget.drill.id == 'pro_cricket_high_mpr_marks_15r' ||
        widget.drill.id == 'master_cricket_4mpr_15r') {
      return FullCricketTrainingPanel(
        isBusy: isBusy,
        title: widget.drill.titleKo,
        onRoundUpdated: (int totalMarks, int playedRounds) {
          setState(() {
            _currentMarks = totalMarks;
            _totalAttempts = playedRounds * 3;
            _thrownDartsNotifier.value = _totalAttempts;
          });
        },
        onCompleted: (int totalMarks, int playedRounds) {
          setState(() {
            _currentMarks = totalMarks;
            _totalAttempts = playedRounds * 3;
            _thrownDartsNotifier.value = _totalAttempts;
          });
        },
        onFinishPressed: _onManualFinish,
      );
    }

    // 🔥 scoreOnly 드릴 공통 처리
    if (widget.drill.inputMode == TrainingDrillInputMode.scoreOnly) {
      final gameType = (extra['gameType'] as String?) ?? '';

      final is501Multi = gameType.startsWith('501_multi'); // 501 멀티 세트 모드
      final is501Mode = gameType.startsWith('501') && !is501Multi;
      // final isCountUpMode = gameType.startsWith('countup'); // 필요 시 확장용

      if (is501Multi) {
        final totalSets = (extra['totalSets'] as num?)?.toInt() ?? 10;
        final minDarts = (extra['minDartsPerLeg'] as num?)?.toInt() ?? 9;
        final maxDarts = (extra['maxDartsPerLeg'] as num?)?.toInt() ?? 30;
        final threshold =
            (extra['successThresholdDarts'] as num?)?.toInt() ?? 18;

        return ScoreGameMultiSetPanel(
          title: widget.drill.titleKo,
          totalSets: totalSets,
          minDartsPerLeg: minDarts,
          maxDartsPerLeg: maxDarts,
          successThresholdDarts: threshold,
          isBusy: isBusy,
          onProgress: (List<int> perLegDarts, int successSets, int playedSets) {
            setState(() {
              _totalAttempts = playedSets; // 시도 = 완료된 세트 수
              _successCount = successSets; // 성공 세트 수

              // 지금까지 사용한 총 다트 수 (참고용)
              _currentScore =
                  perLegDarts.fold<int>(0, (sum, d) => sum + d);

              _thrownDartsNotifier.value = _totalAttempts;
            });
          },
          onCompleted:
              (List<int> perLegDarts, int successSets, int playedSets) async {
            await _ensureSessionStarted();
            if (!mounted) return;

            final int totalDarts =
            perLegDarts.fold<int>(0, (sum, d) => sum + d);

            setState(() {
              _totalAttempts = playedSets; // 총 세트 수
              _successCount = successSets; // 성공 세트 수
              _currentScore = totalDarts; // 전체 사용 다트 수
            });

            _sessionExtraData = {
              'perLegDarts': perLegDarts,
              'totalDarts': totalDarts,
              'successSets': successSets,
              'totalSets': playedSets,
              'successThresholdDarts': threshold,
            };

            await _finishDrill(earlyFinish: false);
          },
          onFinishPressed: _onManualFinish,
        );
      }

      // 2) 501 계열 → 다트 수 입력 패널
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
      }

      // 3) 기타 scoreOnly 백업용
      final targetScore = (extra['targetScore'] as num?)?.toInt() ?? 700;
      final maxScore = (extra['maxScore'] as num?)?.toInt() ?? 1500;

      return ScoreGamePanel(
        title: '최종 값 입력',
        valueLabel: '최종 점수',
        minValue: 0,
        maxValue: maxScore,
        initialValue: targetScore,
        helperText: '게임 한 판을 끝낸 후 최종 값을 입력하세요.',
        isBusy: isBusy,
        onSubmit: (value) =>
            _submitScoreGame(value: value, isDartsMode: false),
        onFinishPressed: _onManualFinish,
      );
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
    final extra = widget.drill.extraConfig ?? {};
    final mode = extra['mode'] as String?;
    final String? gameType = extra['gameType'] as String?;
    final bool isCheckoutPractice = mode == 'checkout_practice';

    // ✅ 501 멀티 세트 드릴 여부
    final bool isMulti501 =
        widget.drill.inputMode == TrainingDrillInputMode.scoreOnly &&
            gameType != null &&
            gameType.startsWith('501_multi');

    // ✅ 라운드 개수
    final int totalRounds =
    (isCheckoutPractice || isMulti501)
        ? _totalPlannedDarts
        : (_totalPlannedDarts / 3).ceil();

    // ✅ 현재 라운드 표시
    final int displayRound =
    (isCheckoutPractice || isMulti501)
        ? (_totalAttempts + 1).clamp(1, totalRounds)
        : _currentRound;

    // ✅ 단위 라벨
    final String attemptsUnitLabel =
    (isCheckoutPractice || isMulti501) ? '세트' : '다트';

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

              // 인라인 진행 카드
              _InlineProgressCard(
                progress: _progress,
                totalAttempts: _totalAttempts,
                totalPlannedDarts: _totalPlannedDarts,
                currentRound: displayRound,
                totalRounds: totalRounds,
                successRate: _successRate,
                attemptsUnitLabel: attemptsUnitLabel,
              ),

              const SizedBox(height: 4),

              // 메인 패널
              _buildDrillPanel(),

              const SizedBox(height: 4),
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
  final String attemptsUnitLabel; // ✅ "다트" or "세트"

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
    final percentText =
        "${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%";
    final successText = totalAttempts == 0
        ? "--"
        : "${(successRate * 100).clamp(0, 100).toStringAsFixed(1)}%";

    final String attemptsLabel =
    attemptsUnitLabel == '세트' ? '세트 수' : '다트 수';

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
          // 하단: 다트/세트 수 / 라운드 / 성공률
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                label: attemptsLabel,
                value:
                "$totalAttempts / $totalPlannedDarts $attemptsUnitLabel",
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
