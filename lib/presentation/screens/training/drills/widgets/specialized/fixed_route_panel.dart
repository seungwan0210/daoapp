import 'package:flutter/material.dart';

/// 170 / 167 같은 특정 점수에서
/// 고정 루트(예: T20 → T20 → Bull)를 반복 연습하는 패널.
///
/// - 한 세트 = 루트 1회(3다트 찬스)
/// - 이 위젯은 "세트 성공/실패"만 입력받고,
///   세트 수/성공 수 카운트는 상위(DrillRunScreen)가 관리.
/// - ✅ 되돌리기(Undo): 방금 입력한 1세트 결과를 취소(상위 카운트도 되돌림)
class FixedRoutePanel extends StatefulWidget {
  /// 예: ['T20', 'T20', 'Bull']
  final List<String> route;

  /// 예: "170"
  final String targetScore;

  /// 세트 1회 성공 시 호출 (상위에서 _recordHit(true) 연결)
  final VoidCallback? onHitSuccess;

  /// 세트 1회 실패 시 호출 (상위에서 _recordHit(false) 연결)
  final VoidCallback? onHitFail;

  /// ✅ 방금 입력한 세트 결과 되돌리기
  /// - wasSuccess: true면 성공을 취소, false면 실패를 취소
  final ValueChanged<bool>? onUndoSetResult;

  /// "드릴 종료하고 결과 저장" 눌렀을 때 호출
  final VoidCallback? onFinishPressed;

  /// 저장/네트워크 작업 중 비활성화 용
  final bool isBusy;

  const FixedRoutePanel({
    super.key,
    required this.route,
    required this.targetScore,
    this.onHitSuccess,
    this.onHitFail,
    this.onUndoSetResult,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<FixedRoutePanel> createState() => _FixedRoutePanelState();
}

class _FixedRoutePanelState extends State<FixedRoutePanel> {
  /// 직전 세트 입력이 있었는지
  bool _hasLastSet = false;

  /// 직전 세트가 성공이었는지
  bool _lastWasSuccess = false;

  /// 세트 직후에 잠깐 띄워줄 성공/실패 플래그
  bool _justSucceeded = false;
  bool _justFailed = false;

  void _clearJustFlags() {
    if (!mounted) return;
    setState(() {
      _justSucceeded = false;
      _justFailed = false;
    });
  }

  void _onMarkSuccess() {
    if (widget.isBusy) return;

    setState(() {
      _hasLastSet = true;
      _lastWasSuccess = true;
      _justSucceeded = true;
      _justFailed = false;
    });

    widget.onHitSuccess?.call();

    // 짧게 상태 보여주고 메시지만 내려줌(다음 세트 입력 준비)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _clearJustFlags();
    });
  }

  void _onMarkFail() {
    if (widget.isBusy) return;

    setState(() {
      _hasLastSet = true;
      _lastWasSuccess = false;
      _justSucceeded = false;
      _justFailed = true;
    });

    widget.onHitFail?.call();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _clearJustFlags();
    });
  }

  void _undoLastSet() {
    if (widget.isBusy) return;
    if (!_hasLastSet) return;

    // 상위 카운트(세트/성공수) 되돌리기
    widget.onUndoSetResult?.call(_lastWasSuccess);

    setState(() {
      _hasLastSet = false;
      _lastWasSuccess = false;
      _justSucceeded = false;
      _justFailed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final routeText = widget.route.join(' → ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔹 상단: 목표 점수
          Text(
            '${widget.targetScore} CHECKOUT',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            routeText,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // 🔹 루트 칩(표시용)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: widget.route.map((seg) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  seg,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // 🔹 안내 메시지 (성공/실패 플래그)
          if (_justSucceeded || _justFailed) ...[
            Text(
              _justSucceeded
                  ? '성공! 다음 세트로 넘어갑니다.'
                  : '실패! 다음 세트로 넘어갑니다.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _justSucceeded
                    ? Colors.green.shade600
                    : Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            const Text(
              '이 세트의 결과를 성공 / 실패로 기록하세요.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 🔹 성공 / 실패 버튼
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isBusy ? null : _onMarkSuccess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text(
                    '성공',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isBusy ? null : _onMarkFail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text(
                    '실패',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ✅ 되돌리기 버튼 (직전 입력이 있을 때만)
          if (_hasLastSet)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.isBusy ? null : _undoLastSet,
                icon: const Icon(Icons.undo, size: 18, color: Colors.black54),
                label: const Text(
                  '방금 입력 되돌리기',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 2),

          // 🔹 드릴 종료 버튼
          TextButton(
            onPressed: widget.isBusy ? null : widget.onFinishPressed,
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
      ),
    );
  }
}
