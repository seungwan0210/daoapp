// lib/presentation/screens/training/drills/widgets/specialized/fixed_route_panel.dart

import 'package:flutter/material.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 임포트 경로 수정

class FixedRoutePanel extends StatefulWidget {
  final List<String> route;
  final String targetScore;
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final ValueChanged<bool>? onUndoSetResult;
  final VoidCallback? onFinishPressed;
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
  bool _hasLastSet = false;
  bool _lastWasSuccess = false;
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

    Future.delayed(const Duration(milliseconds: 500), () {
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
      _clearJustFlags();
    });
  }

  void _undoLastSet() {
    if (widget.isBusy || !_hasLastSet) return;

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
    // 🔹 S 대신 AppLocalizations 사용
    final s = AppLocalizations.of(context)!;
    final routeText = widget.route.join(' → ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          // 🔹 상단: 목표 점수 (CHECKOUT 텍스트 다국어화)
          Text(
            '${widget.targetScore} CHECKOUT', // '계산기' replace 대신 직관적인 영문 혹은 s.result_title 등 활용
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

          // 🔹 루트 칩
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

          // 🔹 안내 메시지 (상태별 피드백)
          if (_justSucceeded || _justFailed) ...[
            Text(
              _justSucceeded
                  ? s.practice_msg_success
                  : s.practice_msg_bust,
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
            Text(
              s.drill_guide_hit_miss,
              style: const TextStyle(
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
                  label: Text(
                    s.drill_btn_success,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
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
                  label: Text(
                    s.drill_btn_fail,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ✅ 되돌리기 버튼
          if (_hasLastSet)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.isBusy ? null : _undoLastSet,
                icon: const Icon(Icons.undo, size: 18, color: Colors.black54),
                label: Text(
                  s.calc_undo, // 🔹 좀 더 짧은 '되돌리기' 키 사용
                  style: const TextStyle(
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
            child: Text(
              s.drill_btn_finish_save,
              style: const TextStyle(
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