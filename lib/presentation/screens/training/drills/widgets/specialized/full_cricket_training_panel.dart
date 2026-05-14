// lib/presentation/screens/training/drills/widgets/specialized/full_cricket_training_panel.dart

import 'package:flutter/material.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 임포트 경로 수정

class FullCricketTrainingPanel extends StatefulWidget {
  final bool isBusy;
  final void Function(int totalMarks, int playedRounds)? onCompleted;
  final void Function(int totalMarks, int playedRounds)? onRoundUpdated;
  final String? title;
  final List<String>? fixedTargets;
  final List<String>? freeRoundChoices;
  final VoidCallback? onFinishPressed;

  const FullCricketTrainingPanel({
    super.key,
    this.isBusy = false,
    this.onCompleted,
    this.onRoundUpdated,
    this.title,
    this.fixedTargets,
    this.freeRoundChoices,
    this.onFinishPressed,
  });

  @override
  State<FullCricketTrainingPanel> createState() =>
      _FullCricketTrainingPanelState();
}

class _FullCricketTrainingPanelState extends State<FullCricketTrainingPanel> {
  static const int _totalRounds = 8;

  static const List<String> _defaultFixedOrder = [
    '20', '19', '18', '17', '16', '15', 'Bull',
  ];

  late final List<String> _fixedOrder;
  late final List<String> _freeChoices;

  int _currentRound = 1;
  int _playedRounds = 0;
  int _totalMarks = 0;

  final List<int> _roundMarks = List<int>.filled(_totalRounds, 0);
  int _selectedMarks = 0;
  String? _freeTarget;

  bool get _isFreeRound => _currentRound == _totalRounds;

  String _currentTarget(BuildContext context) {
    if (_isFreeRound) {
      return _freeTarget ?? AppLocalizations.of(context)!.drill_cricket_free;
    }
    return _fixedOrder[_currentRound - 1];
  }

  bool get _isFinished => _playedRounds >= _totalRounds;

  double get _currentMpr {
    if (_playedRounds == 0) return 0;
    return _totalMarks / _playedRounds;
  }

  @override
  void initState() {
    super.initState();
    final inputFixed = widget.fixedTargets;
    if (inputFixed != null && inputFixed.length >= 7) {
      _fixedOrder = inputFixed.sublist(0, 7);
    } else {
      _fixedOrder = _defaultFixedOrder;
    }

    final inputFree = widget.freeRoundChoices;
    if (inputFree != null && inputFree.isNotEmpty) {
      _freeChoices = List<String>.from(inputFree);
    } else {
      _freeChoices = {..._fixedOrder}.toList();
    }
  }

  void _selectMarks(int marks) {
    if (widget.isBusy || _isFinished) return;
    setState(() => _selectedMarks = marks);
  }

  void _submitCurrentRound() {
    if (widget.isBusy || _isFinished) return;
    final s = AppLocalizations.of(context)!;

    if (_isFreeRound && _freeTarget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.drill_cricket_select_hint)),
      );
      return;
    }

    setState(() {
      _roundMarks[_currentRound - 1] = _selectedMarks;
      _totalMarks = _roundMarks.fold<int>(0, (sum, v) => sum + v);

      if (_playedRounds < _currentRound) {
        _playedRounds = _currentRound;
      }

      if (widget.onRoundUpdated != null) {
        widget.onRoundUpdated!(_totalMarks, _playedRounds);
      }

      if (_currentRound < _totalRounds) {
        _currentRound++;
        _selectedMarks = 0;
      } else {
        _notifyCompletedIfNeeded();
        widget.onFinishPressed?.call();
      }
    });
  }

  void _undoLastRound() {
    if (widget.isBusy) return;
    final s = AppLocalizations.of(context)!;

    if (_playedRounds == 0 || (_currentRound == 1 && _roundMarks[0] == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.drill_msg_no_undo)),
      );
      return;
    }

    setState(() {
      int targetRound = _currentRound;
      if (_currentRound > _playedRounds) {
        targetRound = _playedRounds;
      }

      final idx = targetRound - 1;
      _roundMarks[idx] = 0;
      _totalMarks = _roundMarks.fold<int>(0, (sum, v) => sum + v);

      final completedCount = _roundMarks.where((v) => v > 0).length;
      _playedRounds = completedCount > _totalRounds ? _totalRounds : completedCount;

      if (targetRound < 1) {
        _currentRound = 1;
      } else if (targetRound > _totalRounds) {
        _currentRound = _totalRounds;
      } else {
        _currentRound = targetRound;
      }

      _selectedMarks = 0;
      if (_isFreeRound) _freeTarget = null;

      if (widget.onRoundUpdated != null) {
        widget.onRoundUpdated!(_totalMarks, _playedRounds);
      }
    });
  }

  void _notifyCompletedIfNeeded() {
    if (widget.onCompleted != null) {
      widget.onCompleted!(_totalMarks, _playedRounds);
    }
  }

  void _onTapSaveAndFinish() {
    if (widget.isBusy) return;
    if (_playedRounds == 0) {
      widget.onFinishPressed?.call();
      return;
    }
    _notifyCompletedIfNeeded();
    widget.onFinishPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 S 대신 AppLocalizations 사용
    final currentTarget = _currentTarget(context);
    final isBull = currentTarget == 'Bull';
    final titleText = widget.title ?? s.drill_cricket_8r_title;
    final mprText = _currentMpr.toStringAsFixed(2);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade700, Colors.teal.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(titleText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  // 🔹 인자를 받는 함수형 호출로 수정 ({count}, {total})
                  s.drill_stat_rounds_count(_currentRound.toString(), _totalRounds.toString()),
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Text(_isFreeRound ? s.drill_cricket_free : s.drill_panel_target, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  currentTarget,
                  style: TextStyle(
                    fontSize: _isFreeRound ? 28 : (isBull ? 52 : 64),
                    fontWeight: FontWeight.w900,
                    color: isBull ? Colors.yellow.shade300 : Colors.white,
                  ),
                ),
                if (_isFreeRound && _freeTarget == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(s.drill_cricket_select_hint, style: const TextStyle(fontSize: 12, color: Colors.white60), textAlign: TextAlign.center),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.cyanAccent, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bar_chart_rounded, color: Colors.cyanAccent, size: 18),
                      const SizedBox(width: 6),
                      Text('MPR: $mprText', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                      const SizedBox(width: 10),
                      Text('(${s.drill_unit_marks}: $_totalMarks)', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 자유 타겟 선택
          if (_isFreeRound) ...[
            Align(alignment: Alignment.centerLeft, child: Text(s.drill_cricket_free, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _freeChoices.map((t) {
                final selected = _freeTarget == t;
                return ChoiceChip(
                  label: Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? Colors.black : Colors.white)),
                  selected: selected,
                  selectedColor: t == 'Bull' ? Colors.amber.shade400 : Colors.cyanAccent,
                  backgroundColor: t == 'Bull' ? Colors.amber.shade700 : Colors.teal.shade600,
                  onSelected: widget.isBusy ? null : (val) { if (val) setState(() => _freeTarget = t); },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
          ],

          // 마크 선택
          Align(alignment: Alignment.centerLeft, child: Text(s.drill_unit_marks, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(10, (index) {
              final selected = _selectedMarks == index;
              return GestureDetector(
                onTap: widget.isBusy ? null : () => _selectMarks(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: selected ? Colors.cyan.shade600 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selected ? Colors.cyan.shade800 : Colors.grey.shade300, width: selected ? 2 : 1),
                  ),
                  child: Center(child: Text('$index', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: selected ? Colors.white : Colors.grey.shade800))),
                ),
              );
            }),
          ),

          const SizedBox(height: 18),

          // 확정 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isBusy ? null : _submitCurrentRound,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(
                _currentRound < _totalRounds ? s.drill_confirm_score : s.drill_btn_finish_save,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Undo 버튼
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.isBusy ? null : _undoLastRound,
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: Text(s.drill_btn_undo_round, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          ),

          const SizedBox(height: 8),

          TextButton(
            onPressed: widget.isBusy ? null : _onTapSaveAndFinish,
            child: Text(s.drill_btn_finish_save, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.cyan)),
          ),
        ],
      ),
    );
  }
}