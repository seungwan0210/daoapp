// lib/presentation/screens/training/drills/widgets/specialized/t20_focus_panel.dart

import 'package:flutter/material.dart';

class T20FocusPanel extends StatefulWidget {
  final int totalDarts;              // 예: 60, 90, 120
  final VoidCallback? onHitSuccess;  // 명중 1회
  final VoidCallback? onHitFail;     // 미스 1회
  final VoidCallback? onFinishPressed;
  final bool isBusy;

  /// 🔹 공용 패널로 쓰기 위한 표시 라벨
  ///  - 기본: 'T20'
  ///  - 나중에 '20', '19', 'Bull' 등으로 바꿔서 재사용 가능
  final String targetLabel;

  const T20FocusPanel({
    super.key,
    required this.totalDarts,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.isBusy = false,
    this.targetLabel = 'T20',
  });

  @override
  State<T20FocusPanel> createState() => _T20FocusPanelState();
}

class _T20FocusPanelState extends State<T20FocusPanel> {
  int dartsThrown = 0;
  int hitCount = 0;

  double get successRate =>
      dartsThrown == 0 ? 0 : hitCount / dartsThrown;

  int get remainingDarts => widget.totalDarts - dartsThrown;
  bool get isFinished => dartsThrown >= widget.totalDarts;

  void _record(bool isHit) {
    if (widget.isBusy || isFinished) return;

    setState(() {
      dartsThrown++;
      if (isHit) {
        hitCount++;
      }
    });

    if (isHit) {
      widget.onHitSuccess?.call();
    } else {
      widget.onHitFail?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final successPercent = (successRate * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ===================== 상단 타겟 카드 =====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black,
                  Colors.grey.shade900,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.grey.shade800, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.targetLabel} 집중 연습',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.targetLabel,
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -3,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '총 ${widget.totalDarts}발',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ===================== 진행/통계 카드 =====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 진행 바
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '진행 상황',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade300,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$dartsThrown / ${widget.totalDarts} 발',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.cyan.shade300,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: widget.totalDarts == 0
                        ? 0
                        : (dartsThrown / widget.totalDarts).clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.cyanAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 통계 칩들
                Row(
                  children: [
                    Expanded(
                      child: _InfoStat(
                        label: '던진',
                        value: '$dartsThrown',
                        color: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoStat(
                        label: '명중',
                        value: '$hitCount',
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoStat(
                        label: '성공률',
                        value: '$successPercent%',
                        color: successRate >= 0.5
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                      ),
                    ),
                    if (!isFinished) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoStat(
                          label: '남은',
                          value: '$remainingDarts',
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ===================== 명중 / 미스 버튼 =====================
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isBusy || isFinished
                      ? null
                      : () => _record(true),
                  icon: const Icon(Icons.check_circle, size: 24),
                  label: const Text(
                    '명중',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isBusy || isFinished
                      ? null
                      : () => _record(false),
                  icon: const Icon(Icons.close, size: 22),
                  label: const Text(
                    '미스',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ===================== 종료/저장 버튼 =====================
          if (isFinished) ...[
            ElevatedButton(
              onPressed: widget.onFinishPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 40,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                '결과 확인하기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ] else ...[
            TextButton(
              onPressed: widget.isBusy ? null : widget.onFinishPressed,
              child: const Text(
                '드릴 종료하고 결과 저장',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
