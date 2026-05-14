// lib/presentation/screens/training/drills/widgets/specialized/double_clock_panel.dart

import 'package:flutter/material.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 임포트 경로 수정

class DoubleClockPanel extends StatefulWidget {
  final int startFrom;
  final bool reverse;
  final bool includeBull;

  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final void Function(bool wasSuccess)? onUndoResult;
  final VoidCallback? onFinishPressed;
  final bool isBusy;

  const DoubleClockPanel({
    super.key,
    this.startFrom = 1,
    this.reverse = false,
    this.includeBull = true,
    this.onHitSuccess,
    this.onHitFail,
    this.onUndoResult,
    this.onFinishPressed,
    this.isBusy = false,
  });

  @override
  State<DoubleClockPanel> createState() => _DoubleClockPanelState();
}

class _DoubleClockPanelState extends State<DoubleClockPanel> {
  late List<String> _targets;
  int _currentIndex = 0;
  bool _finished = false;
  final List<bool> _history = <bool>[];

  @override
  void initState() {
    super.initState();
    _buildTargetList();
  }

  void _buildTargetList() {
    final List<String> doubles = [];
    if (widget.reverse) {
      for (int i = 20; i >= 1; i--) {
        if (i >= widget.startFrom) doubles.add('D$i');
      }
    } else {
      for (int i = widget.startFrom; i <= 20; i++) {
        doubles.add('D$i');
      }
    }
    if (widget.includeBull) {
      doubles.add('DBull');
    }
    _targets = doubles;
  }

  int get totalTargets => _targets.length;
  String get currentTarget => _targets.isEmpty ? '-' : _targets[_currentIndex.clamp(0, totalTargets - 1)];
  bool get isFinished => _finished;
  bool get _canUndo => !widget.isBusy && _history.isNotEmpty && totalTargets > 0;

  int get displayStep => totalTargets == 0 ? 0 : (_finished ? totalTargets : (_currentIndex.clamp(0, totalTargets - 1)) + 1);

  double get progress => totalTargets == 0 ? 0.0 : ((_finished ? totalTargets : _currentIndex) / totalTargets).clamp(0.0, 1.0);

  void _record(bool success) {
    if (widget.isBusy || _finished || totalTargets == 0) return;
    _history.add(success);

    if (success) {
      widget.onHitSuccess?.call();
      setState(() {
        if (_currentIndex < totalTargets - 1) {
          _currentIndex++;
        } else {
          _finished = true;
        }
      });
    } else {
      widget.onHitFail?.call();
      setState(() {});
    }
  }

  void _undoLast() {
    if (!_canUndo) return;
    final bool last = _history.removeLast();

    setState(() {
      if (last) {
        if (_finished) {
          _finished = false;
        } else if (_currentIndex > 0) {
          _currentIndex--;
        }
      }
    });
    widget.onUndoResult?.call(last);
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 S 대신 AppLocalizations 사용
    final s = AppLocalizations.of(context)!;

    // 🔹 제목 구성 (다국어 키 조합)
    final String title = widget.startFrom > 1
        ? "${s.drill_clock_title} (${s.filter_upcoming})" // '뒤 절반' 키가 없을 경우 '예정/다음' 키 등으로 대체 가능
        : s.drill_clock_title;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),

          // 상단 진행 정보
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              "$title · $displayStep / $totalTargets",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // 원형 프로그레스 + 타겟
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 9,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan.shade600),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(color: Colors.cyan, width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    currentTarget,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ✅ Undo 버튼
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: _canUndo ? _undoLast : null,
              icon: const Icon(Icons.undo),
              tooltip: s.calc_undo,
            ),
          ),

          const SizedBox(height: 8),

          // 성공 / 실패 버튼
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy || isFinished ? null : () => _record(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(s.drill_btn_success, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy || isFinished ? null : () => _record(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(s.drill_btn_fail, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 결과 확인 / 저장 버튼
          if (isFinished)
            ElevatedButton(
              onPressed: widget.onFinishPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(s.drill_check_result, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            )
          else
            TextButton(
              onPressed: widget.isBusy ? null : widget.onFinishPressed,
              child: Text(s.drill_btn_finish_save, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.cyan)),
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}