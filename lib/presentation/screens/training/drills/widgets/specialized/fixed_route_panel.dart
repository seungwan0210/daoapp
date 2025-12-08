import 'package:flutter/material.dart';

/// 170 / 167 같은 특정 점수에서
/// 고정 루트(예: T20 → T20 → Bull)를 반복 연습하는 패널.
///
/// - 한 세트 = 같은 루트를 3다트 던지는 1번의 찬스
/// - 이 위젯 자체는 "성공/실패"만 판단하고,
///   세트 수 / 성공 세트 수 카운트는 상위(DrillRunScreen)에서 처리하도록 단순화.
class FixedRoutePanel extends StatefulWidget {
  /// 예: ['T20', 'T20', 'Bull']
  final List<String> route;

  /// 예: "170"
  final String targetScore;

  /// 세트 1회 성공 시 호출 (상위에서 _recordHit(true) 같은 거 연결)
  final VoidCallback? onHitSuccess;

  /// 세트 1회 실패 시 호출
  final VoidCallback? onHitFail;

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
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<FixedRoutePanel> createState() => _FixedRoutePanelState();
}

class _FixedRoutePanelState extends State<FixedRoutePanel> {
  /// 현재 세트에서 몇 번째 다트까지 진행했는지 (0~route.length)
  int _currentDartIndex = 0;

  /// 세트 직후에 잠깐 띄워줄 성공/실패 플래그
  bool _justSucceeded = false;
  bool _justFailed = false;

  void _resetSet() {
    setState(() {
      _currentDartIndex = 0;
      _justSucceeded = false;
      _justFailed = false;
    });
  }

  void _onMarkSuccess() {
    if (widget.isBusy) return;

    setState(() {
      _justSucceeded = true;
      _justFailed = false;
      _currentDartIndex = widget.route.length; // 세 다트 완료 상태로
    });

    widget.onHitSuccess?.call();

    // 짧게 성공 상태 보여주고 다음 세트로 리셋
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _resetSet();
    });
  }

  void _onMarkFail() {
    if (widget.isBusy) return;

    setState(() {
      _justSucceeded = false;
      _justFailed = true;
      _currentDartIndex = widget.route.length;
    });

    widget.onHitFail?.call();

    // 짧게 실패 상태 보여주고 다음 세트로 리셋
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _resetSet();
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

          // 🔹 현재 세트 진행 표시 (각 다트칸)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.route.length, (index) {
              final isDone = index < _currentDartIndex;
              final isCurrent = index == _currentDartIndex;

              Color bg;
              Color fg;
              if (isDone) {
                bg = Colors.cyan.shade600;
                fg = Colors.white;
              } else if (isCurrent) {
                bg = Colors.white;
                fg = Colors.cyan.shade700;
              } else {
                bg = Colors.grey.shade100;
                fg = Colors.grey.shade600;
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isCurrent
                        ? Colors.cyan.shade600
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  widget.route[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 10),

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

          const SizedBox(height: 12),

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
