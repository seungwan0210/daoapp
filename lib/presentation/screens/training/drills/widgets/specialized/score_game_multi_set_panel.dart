import 'package:flutter/material.dart';

/// 501 멀티 세트용 패널
/// - 예: 10세트 501 Double-Out
/// - 각 세트마다 "사용한 다트 수"만 입력
/// - successThresholdDarts 이하 → 성공 세트로 집계
class ScoreGameMultiSetPanel extends StatefulWidget {
  final String title;

  /// 총 세트 수 (예: 10)
  final int totalSets;

  /// 한 leg에서 허용하는 최소/최대 다트 수
  final int minDartsPerLeg; // 예: 9
  final int maxDartsPerLeg; // 예: 30

  /// 이 값 이하면 "성공"으로 본다. (예: 18다트)
  final int successThresholdDarts;

  /// 상위에서 세션 저장 중일 때 true
  final bool isBusy;

  /// 세트가 하나 기록될 때마다 상위로 프로그레스 전달
  /// - dartsPerSet: 지금까지 기록된 각 세트의 다트 수
  /// - successCount: 지금까지 성공 세트 수
  /// - playedSets: 기록된 세트 수
  final void Function(
      List<int> dartsPerSet,
      int successCount,
      int playedSets,
      )? onProgress;

  /// 모든 세트가 끝나거나, 사용자가 중간에 종료를 선택했을 때 최종 결과 전달
  final void Function(
      List<int> dartsPerSet,
      int successCount,
      int playedSets,
      )? onCompleted;

  /// "드릴 종료하고 결과 저장" / "결과 확인하기" 눌렀을 때 상위에서 처리할 콜백
  final VoidCallback? onFinishPressed;

  const ScoreGameMultiSetPanel({
    super.key,
    required this.title,
    required this.totalSets,
    required this.minDartsPerLeg,
    required this.maxDartsPerLeg,
    required this.successThresholdDarts,
    this.isBusy = false,
    this.onProgress,
    this.onCompleted,
    this.onFinishPressed,
  });

  @override
  State<ScoreGameMultiSetPanel> createState() => _ScoreGameMultiSetPanelState();
}

class _ScoreGameMultiSetPanelState extends State<ScoreGameMultiSetPanel> {
  int _currentSet = 1;
  late int _currentDarts;
  late TextEditingController _dartsController;

  final List<int> _dartsPerSet = [];
  int _successCount = 0;
  bool _finishedAllSets = false;

  @override
  void initState() {
    super.initState();
    // 기본값: 성공 기준(예: 18다트)에서 시작, 범위 밖이면 min으로 보정
    _currentDarts = widget.successThresholdDarts.clamp(
      widget.minDartsPerLeg,
      widget.maxDartsPerLeg,
    );
    _dartsController = TextEditingController(text: _currentDarts.toString());
  }

  @override
  void dispose() {
    _dartsController.dispose();
    super.dispose();
  }

  int get _playedSets => _dartsPerSet.length;

  int get _totalDartsUsed => _dartsPerSet.fold(0, (sum, v) => sum + v);

  double get _avgDartsPerLeg => _playedSets == 0 ? 0 : _totalDartsUsed / _playedSets;

  double get _successRate => _playedSets == 0 ? 0 : _successCount / _playedSets;

  bool get _isCompleted => _finishedAllSets;

  // ✅ 되돌리기 가능 여부 (완료 전 + 최소 1세트 기록됨)
  bool get _canUndo => _dartsPerSet.isNotEmpty && !_isCompleted;

  void _submitCurrentSet() {
    if (widget.isBusy || _isCompleted) return;

    final raw = _dartsController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용한 다트 수를 입력하세요.')),
      );
      return;
    }

    final parsed = int.tryParse(raw);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('숫자로만 입력해주세요.')),
      );
      return;
    }

    if (parsed < widget.minDartsPerLeg || parsed > widget.maxDartsPerLeg) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.minDartsPerLeg} ~ ${widget.maxDartsPerLeg} 다트 사이에서 입력해주세요.'),
        ),
      );
      return;
    }

    setState(() {
      _currentDarts = parsed;

      // 현재 세트 기록
      _dartsPerSet.add(_currentDarts);
      if (_currentDarts <= widget.successThresholdDarts) {
        _successCount++;
      }

      // 상위에 진행 상황 전달
      widget.onProgress?.call(
        List<int>.from(_dartsPerSet),
        _successCount,
        _playedSets,
      );

      // 마지막 세트인지 체크
      if (_currentSet >= widget.totalSets) {
        _finishedAllSets = true;

        // 최종 완료 콜백
        widget.onCompleted?.call(
          List<int>.from(_dartsPerSet),
          _successCount,
          _playedSets,
        );
      } else {
        // 다음 세트로 이동
        _currentSet++;
        _currentDarts = widget.successThresholdDarts.clamp(
          widget.minDartsPerLeg,
          widget.maxDartsPerLeg,
        );
        _dartsController.text = _currentDarts.toString();
      }
    });
  }

  // ✅ 마지막 기록 세트 되돌리기
  void _undoLastSet() {
    if (widget.isBusy || !_canUndo) return;

    setState(() {
      final last = _dartsPerSet.removeLast();

      // 성공 카운트 복구
      if (last <= widget.successThresholdDarts) {
        _successCount--;
      }

      // 완료 상태 해제
      _finishedAllSets = false;

      // 현재 세트 번호는 "기록된 세트 + 1"
      _currentSet = _playedSets + 1;

      // 입력값은 되돌린 값으로 복원 (바로 수정 가능하게)
      _currentDarts = last.clamp(widget.minDartsPerLeg, widget.maxDartsPerLeg);
      _dartsController.text = _currentDarts.toString();

      // 상위에도 되돌린 진행상황 전달
      widget.onProgress?.call(
        List<int>.from(_dartsPerSet),
        _successCount,
        _playedSets,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이전 세트를 되돌렸습니다.')),
    );
  }

  void _onTapFinish() {
    // 중간 종료 시에도 현재까지의 결과를 상위로 전달
    widget.onCompleted?.call(
      List<int>.from(_dartsPerSet),
      _successCount,
      _playedSets,
    );

    widget.onFinishPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final successPercent = (_successRate * 100).toStringAsFixed(1);
    final avgDartsText = _playedSets == 0 ? '--' : _avgDartsPerLeg.toStringAsFixed(1);
    final successText = _playedSets == 0 ? '--' : '$successPercent%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),

          // ===================== 상단 카드 (타이틀 + 세트 진행) =====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.shade900,
                  Colors.black,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.blueGrey.shade800,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '세트 $_currentSet / ${widget.totalSets}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '이 세트 목표: ${widget.successThresholdDarts}다트 이내',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                if (_playedSets > 0)
                  Text(
                    '지금까지 ${_playedSets}세트 중 $_successCount세트 성공',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white60,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ===================== 통계 카드 =====================
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
                      '세트 $_playedSets / ${widget.totalSets}',
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
                    value: widget.totalSets == 0 ? 0 : (_playedSets / widget.totalSets).clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.cyanAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        label: '성공 세트',
                        value: '$_successCount세트',
                        color: Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _StatChip(
                        label: '성공률',
                        value: successText,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _StatChip(
                        label: '평균 다트',
                        value: avgDartsText,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ===================== 현재 세트 입력 영역 =====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '현재 세트 사용 다트 수',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _dartsController,
                  enabled: !widget.isBusy && !_isCompleted,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: '예: 18',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _submitCurrentSet(),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.minDartsPerLeg} ~ ${widget.maxDartsPerLeg} 다트 사이에서 입력',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // ✅ 기록 + 되돌리기(Undo) 버튼 묶음
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.isBusy || _isCompleted ? null : _submitCurrentSet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _currentSet >= widget.totalSets ? '마지막 세트 기록' : '세트 $_currentSet 기록',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: (widget.isBusy || !_canUndo) ? null : _undoLastSet,
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text('되돌리기'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orangeAccent,
                          side: BorderSide(color: Colors.orangeAccent.withOpacity(0.7)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ===================== 종료/저장 버튼 =====================
          if (_isCompleted) ...[
            ElevatedButton(
              onPressed: widget.isBusy ? null : _onTapFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade600,
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
              onPressed: widget.isBusy ? null : _onTapFinish,
              child: const Text(
                '드릴 종료하고 결과 저장',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
