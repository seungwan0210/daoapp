import 'package:flutter/material.dart';

class T20FocusPanel extends StatefulWidget {
  /// 🔹 단일 타겟 모드용 (기존 T20 모드)
  final int totalDarts;
  final String targetLabel;

  /// 🔹 멀티 세그먼트 모드용 (예: ['D16', 'D20'])
  final List<String>? segments;
  final int? dartsPerSegment;

  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;
  final bool isBusy;

  const T20FocusPanel({
    super.key,
    required this.totalDarts,
    this.targetLabel = 'T20',
    this.segments,
    this.dartsPerSegment,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<T20FocusPanel> createState() => _T20FocusPanelState();
}

class _T20FocusPanelState extends State<T20FocusPanel> {
  int dartsThrown = 0;
  int totalHitCount = 0;

  // 멀티 세그먼트용
  late final bool _isMultiSegment;
  late final int _effectiveTotalDarts;
  late List<int> _segmentHits;
  late List<int> _segmentDarts;

  @override
  void initState() {
    super.initState();

    _isMultiSegment =
        widget.segments != null && widget.dartsPerSegment != null;

    if (_isMultiSegment) {
      final segCount = widget.segments!.length;
      _effectiveTotalDarts = segCount * widget.dartsPerSegment!;
      _segmentHits = List.filled(segCount, 0);
      _segmentDarts = List.filled(segCount, 0);
    } else {
      _effectiveTotalDarts = widget.totalDarts;
      _segmentHits = const [];
      _segmentDarts = const [];
    }
  }

  double get successRate =>
      dartsThrown == 0 ? 0 : totalHitCount / dartsThrown;

  int get remainingDarts => _effectiveTotalDarts - dartsThrown;
  bool get isFinished => dartsThrown >= _effectiveTotalDarts;

  int get _currentSegmentIndex {
    if (!_isMultiSegment) return 0;
    final segLen = widget.segments!.length;
    final dartsPerSeg = widget.dartsPerSegment!;
    final idx = dartsThrown ~/ dartsPerSeg;
    return idx.clamp(0, segLen - 1);
  }

  String get _currentLabel {
    if (_isMultiSegment) {
      return widget.segments![_currentSegmentIndex];
    }
    return widget.targetLabel;
  }

  int get _currentSegmentDarts {
    if (!_isMultiSegment) return 0;
    return _segmentDarts[_currentSegmentIndex];
  }

  void _record(bool isHit) {
    if (widget.isBusy || isFinished) return;

    setState(() {
      dartsThrown++;
      if (isHit) {
        totalHitCount++;
      }

      if (_isMultiSegment) {
        _segmentDarts[_currentSegmentIndex]++;
        if (isHit) {
          _segmentHits[_currentSegmentIndex]++;
        }
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
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black,
                  Colors.grey.shade900,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.grey.shade800, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isMultiSegment
                      ? '멀티 더블 집중 연습'
                      : '${_currentLabel} 집중 연습',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _currentLabel,
                  style: const TextStyle(
                    fontSize: 40, // 🔻 64 → 40 (가독성 위해 축소)
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '총 $_effectiveTotalDarts발',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),

                // 🔹 멀티 세그먼트일 때: 현재 세그먼트 정보 표기
                if (_isMultiSegment) ...[
                  const SizedBox(height: 8),
                  Text(
                    '세그먼트 ${_currentSegmentIndex + 1}/${widget.segments!.length} · '
                        '${_currentLabel} ${_currentSegmentDarts}/${widget.dartsPerSegment}발',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ===================== 진행/통계 카드 =====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(18),
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
                        fontSize: 12,
                        color: Colors.grey.shade300,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$dartsThrown / $_effectiveTotalDarts 발',
                      style: TextStyle(
                        fontSize: 11,
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
                    value: _effectiveTotalDarts == 0
                        ? 0
                        : (dartsThrown / _effectiveTotalDarts).clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.cyanAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 통계 칩들 (전체 기준)
                Row(
                  children: [
                    Expanded(
                      child: _InfoStat(
                        label: '던진',
                        value: '$dartsThrown',
                        color: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _InfoStat(
                        label: '명중',
                        value: '$totalHitCount',
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
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
                      const SizedBox(width: 6),
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

                const SizedBox(height: 8),

                // 🔹 세그먼트별 통계 (D16 / D20 각각)
                if (_isMultiSegment) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(widget.segments!.length, (i) {
                      final segLabel = widget.segments![i];
                      final darts = _segmentDarts[i];
                      final hits = _segmentHits[i];
                      final rate =
                      darts == 0 ? 0.0 : (hits / darts) * 100.0;
                      final rateText = rate.toStringAsFixed(1);

                      return _InfoStat(
                        label: segLabel,
                        value: '$hits/$darts ($rateText%)',
                        color: Colors.lightBlueAccent,
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ===================== 명중 / 미스 버튼 =====================
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isBusy || isFinished
                      ? null
                      : () => _record(true),
                  icon: const Icon(Icons.check_circle, size: 22),
                  label: const Text(
                    '명중',
                    style: TextStyle(
                      fontSize: 16, // 🔻 18 → 16
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isBusy || isFinished
                      ? null
                      : () => _record(false),
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text(
                    '미스',
                    style: TextStyle(
                      fontSize: 16, // 🔻 18 → 16
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ===================== 종료/저장 버튼 =====================
          if (isFinished) ...[
            ElevatedButton(
              onPressed: widget.onFinishPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 32,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '결과 확인하기',
                style: TextStyle(
                  fontSize: 16, // 🔻 18 → 16
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
                  fontSize: 13,
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
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 10, // 🔻 11 → 10
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13, // 🔻 14 → 13
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
