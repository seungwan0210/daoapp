// lib/presentation/screens/training/drills/widgets/specialized/t20_focus_panel.dart

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

  /// ✅ RunScreen의 thrownDarts를 그대로 받아서 UI 표시/세그먼트 계산 동기화
  final ValueNotifier<int>? thrownDartsNotifier;

  /// ✅ Undo 지원 (선택)
  final bool canUndo;
  final VoidCallback? onUndo;

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
    this.thrownDartsNotifier,
    this.canUndo = false,
    this.onUndo,
  });

  @override
  State<T20FocusPanel> createState() => _T20FocusPanelState();
}

class _T20FocusPanelState extends State<T20FocusPanel> {
  // 멀티 세그먼트용
  late final bool _isMultiSegment;
  late final int _effectiveTotalDarts;

  late List<int> _segmentHits;  // 세그별 명중 수
  late List<int> _segmentDarts; // 세그별 던진 수

  /// ✅ Undo를 위해 "마지막 입력" 히스토리 저장
  /// - each: { segIndex, isHit }
  final List<_T20HitRecord> _hitHistory = <_T20HitRecord>[];

  @override
  void initState() {
    super.initState();

    _isMultiSegment = widget.segments != null && widget.dartsPerSegment != null;

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

  int _currentSegmentIndex(int thrown) {
    if (!_isMultiSegment) return 0;
    final segLen = widget.segments!.length;
    final dartsPerSeg = widget.dartsPerSegment!;
    final idx = thrown ~/ dartsPerSeg;
    return idx.clamp(0, segLen - 1);
  }

  String _currentLabel(int thrown) {
    if (_isMultiSegment) {
      return widget.segments![_currentSegmentIndex(thrown)];
    }
    return widget.targetLabel;
  }

  int _currentSegmentDarts(int thrown) {
    if (!_isMultiSegment) return 0;
    final segIdx = _currentSegmentIndex(thrown);
    return _segmentDarts[segIdx];
  }

  int _totalHitCount() {
    if (!_isMultiSegment) {
      // 단일 모드에서는 성공수 누적을 따로 들고 있지 않으니,
      // 히스토리 기반으로 계산
      return _hitHistory.where((e) => e.isHit).length;
    }
    return _segmentHits.fold<int>(0, (sum, v) => sum + v);
  }

  double _successRate(int thrown) {
    if (thrown == 0) return 0;
    final hits = _totalHitCount();
    return hits / thrown;
  }

  bool _isFinished(int thrown) => thrown >= _effectiveTotalDarts;

  int _remainingDarts(int thrown) => (_effectiveTotalDarts - thrown).clamp(0, 999999);

  void _record(bool isHit, int thrown) {
    if (widget.isBusy) return;
    if (_isFinished(thrown)) return;

    final segIdx = _currentSegmentIndex(thrown);

    setState(() {
      _hitHistory.add(_T20HitRecord(segIndex: segIdx, isHit: isHit));

      if (_isMultiSegment) {
        _segmentDarts[segIdx] += 1;
        if (isHit) _segmentHits[segIdx] += 1;
      }
    });

    if (isHit) {
      widget.onHitSuccess?.call();
    } else {
      widget.onHitFail?.call();
    }
  }

  void _handleUndo(int thrown) {
    if (widget.isBusy) return;
    if (!widget.canUndo) return;
    if (_hitHistory.isEmpty) return;
    if (thrown <= 0) return;

    setState(() {
      final last = _hitHistory.removeLast();

      if (_isMultiSegment) {
        final segIdx = last.segIndex.clamp(0, _segmentDarts.length - 1);
        if (_segmentDarts[segIdx] > 0) _segmentDarts[segIdx] -= 1;
        if (last.isHit && _segmentHits[segIdx] > 0) _segmentHits[segIdx] -= 1;
      }
      // 단일 모드는 히스토리만 줄이면 OK (성공률/명중수는 히스토리로 계산)
    });

    widget.onUndo?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget content(int thrown) {
      final isFinished = _isFinished(thrown);
      final hits = _totalHitCount();
      final successRate = _successRate(thrown);
      final successPercent = (successRate * 100).toStringAsFixed(1);

      final currentLabel = _currentLabel(thrown);
      final currentSegDarts = _currentSegmentDarts(thrown);

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
                    _isMultiSegment ? '멀티 더블 집중 연습' : '$currentLabel 집중 연습',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentLabel,
                    style: const TextStyle(
                      fontSize: 40,
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
                      '세그먼트 ${_currentSegmentIndex(thrown) + 1}/${widget.segments!.length} · '
                          '$currentLabel ${currentSegDarts}/${widget.dartsPerSegment}발',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  // ✅ Undo (선택)
                  if (widget.onUndo != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: (widget.isBusy || !widget.canUndo)
                            ? null
                            : () => _handleUndo(thrown),
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text(
                          'UNDO',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
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
                        '$thrown / $_effectiveTotalDarts 발',
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
                          : (thrown / _effectiveTotalDarts).clamp(0, 1),
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
                          value: '$thrown',
                          color: Colors.cyanAccent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _InfoStat(
                          label: '명중',
                          value: '$hits',
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
                            value: '${_remainingDarts(thrown)}',
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // 🔹 세그먼트별 통계 (D16 / D20 각각)
                  if (_isMultiSegment) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(widget.segments!.length, (i) {
                        final segLabel = widget.segments![i];
                        final darts = _segmentDarts[i];
                        final hits = _segmentHits[i];
                        final rate = darts == 0 ? 0.0 : (hits / darts) * 100.0;
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
                        : () => _record(true, thrown),
                    icon: const Icon(Icons.check_circle, size: 22),
                    label: const Text(
                      '명중',
                      style: TextStyle(
                        fontSize: 16,
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
                        : () => _record(false, thrown),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text(
                      '미스',
                      style: TextStyle(
                        fontSize: 16,
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
                    fontSize: 16,
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

    // ✅ notifier가 있으면 UI 완전 동기화
    if (widget.thrownDartsNotifier != null) {
      return ValueListenableBuilder<int>(
        valueListenable: widget.thrownDartsNotifier!,
        builder: (_, thrown, __) => content(thrown),
      );
    }

    // ✅ notifier가 없으면 (구버전 호환) 0으로 표시 (권장: notifier 넘겨라)
    return content(0);
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
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _T20HitRecord {
  final int segIndex;
  final bool isHit;

  const _T20HitRecord({
    required this.segIndex,
    required this.isHit,
  });
}
