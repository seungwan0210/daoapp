// lib/presentation/screens/training/drills/widgets/specialized/checkout_practice_panel.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class CheckoutPracticePanel extends StatefulWidget {
  final int minScore;
  final int maxScore;
  final int maxDartsPerSet;
  final int totalSets;
  final bool requireDoubleOut;

  /// ✅ 세트 성공/실패 카운트 (DrillRunScreen에서 _recordHit(true/false)로 연결)
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;

  /// ✅ Undo 시 “방금 카운트한 세트 1회”를 되돌리기 위해 추가
  /// - wasSuccess = true  → 성공 세트 1회 취소
  /// - wasSuccess = false → 실패 세트 1회 취소
  final void Function(bool wasSuccess)? onUndoSetResult;

  final VoidCallback? onFinishPressed;
  final bool isBusy;

  const CheckoutPracticePanel({
    super.key,
    required this.minScore,
    required this.maxScore,
    this.maxDartsPerSet = 6,
    this.totalSets = 30,
    this.requireDoubleOut = true,
    this.onHitSuccess,
    this.onHitFail,
    this.onUndoSetResult,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<CheckoutPracticePanel> createState() => _CheckoutPracticePanelState();
}

class _SetSnapshot {
  final int currentSet;
  final int? currentScore;
  final int dartsThrown;

  /// ✅ 이 입력이 “세트 종료(성공/실패)”를 발생시켰는지
  final bool endedSet;

  /// ✅ endedSet = true일 때만 의미 있음
  final bool wasSuccessSet;

  _SetSnapshot({
    required this.currentSet,
    required this.currentScore,
    required this.dartsThrown,
    required this.endedSet,
    required this.wasSuccessSet,
  });
}

class _CheckoutPracticePanelState extends State<CheckoutPracticePanel> {
  int currentSet = 1;
  int? currentScore;
  int dartsThrown = 0;
  final TextEditingController _controller = TextEditingController();

  final List<_SetSnapshot> _history = [];
  Timer? _nextTimer;

  @override
  void initState() {
    super.initState();
    _newSet();
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  bool get _canUndo => !widget.isBusy && _history.isNotEmpty;

  void _newSet() {
    final random = Random();
    currentScore = widget.minScore +
        random.nextInt(widget.maxScore - widget.minScore + 1);
    dartsThrown = 0;
    _controller.clear();
    setState(() {});
  }

  void _scheduleNextSetOrFinish() {
    _nextTimer?.cancel();
    _nextTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      if (currentSet >= widget.totalSets) {
        widget.onFinishPressed?.call();
      } else {
        setState(() {
          currentSet++;
          _newSet();
        });
      }
    });
  }

  void _submitScore() {
    if (widget.isBusy ||
        currentScore == null ||
        dartsThrown >= widget.maxDartsPerSet) return;

    final input = _controller.text.trim();
    if (input.isEmpty) return;

    final score = int.tryParse(input);
    if (score == null || score < 0 || score > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('0~180 사이 숫자를 입력하세요')),
      );
      return;
    }

    final int beforeSet = currentSet;
    final int? beforeScore = currentScore;
    final int beforeDarts = dartsThrown;

    bool endedSet = false;
    bool wasSuccessSet = false;

    setState(() {
      dartsThrown++;
      currentScore = (currentScore ?? 0) - score;
      _controller.clear();

      // === 성공 체크 (DBull 포함!) ===
      if (currentScore == 0) {
        final bool isDoubleFinish =
            (score >= 2 && score <= 40 && score.isEven) || // D1~D20
                score == 50; // DBull

        if (!widget.requireDoubleOut || isDoubleFinish) {
          endedSet = true;
          wasSuccessSet = true;

          // ✅ 세트 성공 카운트 (런스크린)
          widget.onHitSuccess?.call();

          // ✅ 히스토리 저장 (세트 종료 발생)
          _history.add(
            _SetSnapshot(
              currentSet: beforeSet,
              currentScore: beforeScore,
              dartsThrown: beforeDarts,
              endedSet: true,
              wasSuccessSet: true,
            ),
          );

          _scheduleNextSetOrFinish();
          return;
        }
      }

      // === 실패 체크 ===
      if ((currentScore != null && currentScore! <= 1) ||
          dartsThrown >= widget.maxDartsPerSet) {
        endedSet = true;
        wasSuccessSet = false;

        // ✅ 세트 실패 카운트 (런스크린)
        widget.onHitFail?.call();

        // ✅ 히스토리 저장 (세트 종료 발생)
        _history.add(
          _SetSnapshot(
            currentSet: beforeSet,
            currentScore: beforeScore,
            dartsThrown: beforeDarts,
            endedSet: true,
            wasSuccessSet: false,
          ),
        );

        _scheduleNextSetOrFinish();
        return;
      }

      // ✅ 일반 입력 (세트 유지)
      _history.add(
        _SetSnapshot(
          currentSet: beforeSet,
          currentScore: beforeScore,
          dartsThrown: beforeDarts,
          endedSet: false,
          wasSuccessSet: false,
        ),
      );
    });

    // endedSet 처리들은 setState 안에서 return으로 끝남
  }

  void _undoLast() {
    if (!_canUndo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('되돌릴 기록이 없습니다.')),
      );
      return;
    }

    // ✅ 다음 세트로 넘어가는 타이머가 걸려있으면 취소
    _nextTimer?.cancel();
    _nextTimer = null;

    final snap = _history.removeLast();

    setState(() {
      currentSet = snap.currentSet;
      currentScore = snap.currentScore;
      dartsThrown = snap.dartsThrown;
      _controller.clear();
    });

    // ✅ “세트 종료를 발생시킨 입력”을 Undo하는 경우,
    // 런스크린에 세트 카운트 되돌리라고 알려야 함
    if (snap.endedSet) {
      widget.onUndoSetResult?.call(snap.wasSuccessSet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingDarts = widget.maxDartsPerSet - dartsThrown;
    final isBust =
        currentScore != null && currentScore! <= 1 && currentScore! > 0;
    final scoreText = currentScore?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),

          // 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade700, Colors.purple.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "세트 $currentSet / ${widget.totalSets}",
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  scoreText,
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  isBust ? "버스트!" : "$remainingDarts 다트 남음",
                  style: TextStyle(
                    fontSize: 14,
                    color: isBust ? Colors.redAccent : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: List.generate(widget.maxDartsPerSet, (i) {
                    final used = i < dartsThrown;
                    return Icon(
                      used ? Icons.circle : Icons.circle_outlined,
                      color: used ? Colors.green.shade400 : Colors.white30,
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ✅ Undo 버튼
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _canUndo ? _undoLast : null,
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: const Text(
                '1회 되돌리기',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          ),

          const SizedBox(height: 10),

          // 입력창 + 전송
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !widget.isBusy,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: "맞춘 점수 입력",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _submitScore(),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: widget.isBusy ? null : _submitScore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade600,
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                ),
                child: const Icon(
                  Icons.send,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: widget.isBusy ? null : widget.onFinishPressed,
            child: const Text(
              "드릴 종료하고 결과 저장",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.cyan,
              ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
