// lib/presentation/screens/training/drills/widgets/specialized/checkout_practice_panel.dart

import 'dart:math';
import 'package:flutter/material.dart';

class CheckoutPracticePanel extends StatefulWidget {
  final int minScore;
  final int maxScore;
  final int maxDartsPerSet;
  final int totalSets;
  final bool requireDoubleOut;

  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
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
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<CheckoutPracticePanel> createState() => _CheckoutPracticePanelState();
}

class _CheckoutPracticePanelState extends State<CheckoutPracticePanel> {
  int currentSet = 1;
  int? currentScore;
  int dartsThrown = 0;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _newSet();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _newSet() {
    final random = Random();
    currentScore = widget.minScore +
        random.nextInt(widget.maxScore - widget.minScore + 1);
    dartsThrown = 0;
    _controller.clear();
    setState(() {});
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

    setState(() {
      dartsThrown++;
      currentScore = currentScore! - score;
      _controller.clear();

      // === 성공 체크 (DBull 포함!) ===
      if (currentScore == 0) {
        final bool isDoubleFinish =
            (score >= 2 && score <= 40 && score.isEven) || // D1~D20
                score == 50; // DBull

        if (!widget.requireDoubleOut || isDoubleFinish) {
          widget.onHitSuccess?.call();
          _nextSetOrFinish(isSuccess: true);
          return;
        }
      }

      // === 실패 체크 ===
      if (currentScore! <= 1 || dartsThrown >= widget.maxDartsPerSet) {
        widget.onHitFail?.call();
        _nextSetOrFinish(isSuccess: false);
      }
    });
  }

  void _nextSetOrFinish({required bool isSuccess}) {
    Future.delayed(const Duration(milliseconds: 600), () {
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

          // 좌우 꽉 차는 보라색 카드 (세트 + 점수 + 남은 다트)
          Container(
            width: double.infinity, // ← 좌우 끝까지 꽉!
            padding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade700,
                  Colors.purple.shade900
                ],
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
                // 세트 정보
                Text(
                  "세트 $currentSet / ${widget.totalSets}",
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // 남은 점수 (크게!)
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

                // 상태 메시지
                Text(
                  isBust
                      ? "버스트!"
                      : "$remainingDarts 다트 남음", // 띄어쓰기 추가
                  style: TextStyle(
                    fontSize: 14,
                    color:
                    isBust ? Colors.redAccent : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                // 남은 다트 아이콘 (Wrap으로 감싸서 오버플로우 방지)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: List.generate(widget.maxDartsPerSet, (i) {
                    final used = i < dartsThrown;
                    return Icon(
                      used ? Icons.circle : Icons.circle_outlined,
                      color:
                      used ? Colors.green.shade400 : Colors.white30,
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 점수 입력창 + 전송 버튼
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
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 16),
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

          // 종료 버튼
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
