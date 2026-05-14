// lib/presentation/screens/training/drills/widgets/specialized/around_board_panel.dart

import 'package:flutter/material.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 임포트 경로 수정

enum _AroundThrowResult { success, fail }

class AroundBoardPanel extends StatefulWidget {
  final List<String> sequence;
  final ValueNotifier<int> thrownDartsNotifier;
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;
  final VoidCallback? onCompleted;
  final bool isBusy;

  final bool canUndo;
  final VoidCallback? onUndo;

  const AroundBoardPanel({
    super.key,
    required this.sequence,
    required this.thrownDartsNotifier,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.onCompleted,
    this.isBusy = false,
    this.canUndo = false,
    this.onUndo,
  });

  @override
  State<AroundBoardPanel> createState() => _AroundBoardPanelState();
}

class _AroundBoardPanelState extends State<AroundBoardPanel> {
  int currentIndex = 0;
  final List<_AroundThrowResult> _history = [];

  String get currentTarget => widget.sequence[currentIndex];
  int get totalTargets => widget.sequence.length;

  bool get _canUndo =>
      !widget.isBusy && widget.canUndo && _history.isNotEmpty;

  double get progress {
    if (totalTargets <= 1) return 0;
    return currentIndex / (totalTargets - 1);
  }

  void _record(bool success) {
    if (widget.isBusy) return;

    setState(() {
      _history.add(success ? _AroundThrowResult.success : _AroundThrowResult.fail);

      if (success) {
        widget.onHitSuccess?.call();

        if (currentIndex < totalTargets - 1) {
          currentIndex++;
        } else {
          if (widget.onCompleted != null) {
            widget.onCompleted!.call();
          } else {
            widget.onFinishPressed?.call();
          }
        }
      } else {
        widget.onHitFail?.call();
      }
    });
  }

  void _onUndo() {
    final s = AppLocalizations.of(context)!;
    if (!_canUndo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.drill_msg_no_undo)),
      );
      return;
    }

    setState(() {
      final last = _history.removeLast();
      if (last == _AroundThrowResult.success && currentIndex > 0) {
        currentIndex--;
      }
    });

    widget.onUndo?.call();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 S 대신 AppLocalizations 사용
    final bool isBull = currentTarget == 'SB' || currentTarget == 'DBull' || currentTarget == 'SBull';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 진행 정보
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            // 🔹 함수형 인자 호출로 수정 ({count}, {total} 값 전달)
            s.drill_around_title((currentIndex + 1).toString(), totalTargets.toString()),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 16),

        // 2. 원형 진행 + 현재 타겟
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: progress.clamp(0, 1),
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isBull ? Colors.purple.shade600 : Colors.cyan.shade600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(
                    color: isBull ? Colors.purpleAccent : Colors.cyan,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentTarget,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBull ? "BULL" : s.drill_label_single,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ✅ Undo 버튼
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _canUndo ? _onUndo : null,
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: Text(
              s.drill_btn_undo_last,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
          ),
        ),

        const SizedBox(height: 6),

        // 3. 성공 / 실패 버튼
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.isBusy ? null : () => _record(true),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  s.drill_btn_success,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.isBusy ? null : () => _record(false),
                icon: const Icon(Icons.close),
                label: Text(
                  s.drill_btn_fail,
                  style: const TextStyle(
                    fontSize: 18,
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
          ],
        ),

        const SizedBox(height: 12),

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
    );
  }
}