// lib/presentation/screens/training/drills/widgets/specialized/full_cricket_training_panel.dart

import 'package:flutter/material.dart';

/// 8R 크리켓 실전 훈련 공용 패널
///
/// - 1R당 3다트 고정
/// - 각 라운드에 0~9 마크 버튼으로 입력
/// - 실시간 MPR = 총 마크 / 완료 라운드 수 (최대 9.0)
/// - Undo 버튼으로 직전 라운드 되돌리기 가능
/// - 모든 입력이 끝나거나, 사용자가 저장 버튼을 누르면
///   onCompleted(totalMarks, playedRounds) 콜백으로 최종 결과 전달
class FullCricketTrainingPanel extends StatefulWidget {
  /// 로딩/저장 중일 때 버튼 비활성화용
  final bool isBusy;

  /// 최종 결과를 부모(DrillRunScreen)로 전달
  /// totalMarks: 전체 8R(또는 완료된 R) 동안의 총 마크 수
  /// playedRounds: 실제로 완료된 라운드 수 (최대 8)
  final void Function(int totalMarks, int playedRounds)? onCompleted;

  /// 🔹 라운드 하나 확정될 때마다 현재 totalMarks / playedRounds를 부모로 전달
  /// - 상단 진행률 카드 갱신용
  final void Function(int totalMarks, int playedRounds)? onRoundUpdated;

  /// 상단 타이틀 (없으면 기본 텍스트)
  final String? title;

  /// 1~7R에 사용할 기본 타겟 순서
  /// - 예: 20↔19 전용: ['20','19','20','19','20','19','20']
  /// - 풀보드: ['20','19','18','17','16','15','Bull']
  /// 길이가 7 미만이면 내부에서 기본값으로 보정
  final List<String>? fixedTargets;

  /// 8R 자유 라운드에서 선택 가능한 타겟 리스트
  /// null이면 fixedTargets(또는 기본값)를 그대로 사용
  final List<String>? freeRoundChoices;

  /// 사용자가 도중에 “드릴 종료하고 결과 저장”을 눌렀을 때
  /// (부모에서는 이 콜백 안에서 onCompleted 결과를 받아 finishDrill 호출하는 식으로 사용)
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
  static const int _dartsPerRound = 3;

  // 기본: 풀보드 크리켓 (20→19→18→17→16→15→Bull)
  static const List<String> _defaultFixedOrder = [
    '20',
    '19',
    '18',
    '17',
    '16',
    '15',
    'Bull',
  ];

  late final List<String> _fixedOrder;
  late final List<String> _freeChoices;

  int _currentRound = 1; // 1 ~ 8
  int _playedRounds = 0; // 실제로 확정된 라운드 수
  int _totalMarks = 0; // 전체 마크 합

  // 각 라운드별 입력된 마크 수 (0~9)
  final List<int> _roundMarks = List<int>.filled(_totalRounds, 0);

  // 현재 라운드에서 선택된 마크 (0~9)
  int _selectedMarks = 0;

  // 8R(자유 라운드)에서 선택된 타겟
  String? _freeTarget;

  bool get _isFreeRound => _currentRound == _totalRounds;

  String get _currentTarget {
    if (_isFreeRound) {
      return _freeTarget ?? '자유 선택';
    }
    // 1~7R은 고정 순서
    return _fixedOrder[_currentRound - 1];
  }

  bool get _isFinished => _playedRounds >= _totalRounds;

  double get _currentMpr {
    if (_playedRounds == 0) return 0;
    // MPR = 총 마크 / 완료 라운드 수
    // 1R = 3다트이므로, 이 값의 이론상 최대는 9.0 (T×3 모두 적중)
    return _totalMarks / _playedRounds;
  }

  @override
  void initState() {
    super.initState();

    // 1) 고정 타겟 리스트 결정
    final inputFixed = widget.fixedTargets;
    if (inputFixed != null && inputFixed.length >= 7) {
      _fixedOrder = inputFixed.sublist(0, 7);
    } else {
      _fixedOrder = _defaultFixedOrder;
    }

    // 2) 자유 라운드에서 선택 가능한 타겟 리스트
    final inputFree = widget.freeRoundChoices;
    if (inputFree != null && inputFree.isNotEmpty) {
      _freeChoices = List<String>.from(inputFree);
    } else {
      // 기본: 고정 순서의 유니크 값 사용
      _freeChoices = {
        ..._fixedOrder,
      }.toList();
    }
  }

  void _selectMarks(int marks) {
    if (widget.isBusy || _isFinished) return;
    setState(() => _selectedMarks = marks);
  }

  void _submitCurrentRound() {
    if (widget.isBusy || _isFinished) return;

    // 마지막 라운드(8R)인데 타겟을 아직 안 골랐다면
    if (_isFreeRound && _freeTarget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('자유 라운드 타겟을 먼저 선택해 주세요.'),
        ),
      );
      return;
    }

    setState(() {
      _roundMarks[_currentRound - 1] = _selectedMarks;
      _totalMarks = _roundMarks.fold<int>(0, (sum, v) => sum + v);

      if (_playedRounds < _currentRound) {
        _playedRounds = _currentRound;
      }

      // 🔹 라운드 하나 확정될 때마다 부모에 현재 상태 전달
      if (widget.onRoundUpdated != null) {
        widget.onRoundUpdated!(_totalMarks, _playedRounds);
      }

      if (_currentRound < _totalRounds) {
        // 다음 라운드로 이동
        _currentRound++;
        _selectedMarks = 0;
      } else {
        // 🔥 8R 완료 — 결과 부모로 전달 + 자동 종료
        _notifyCompletedIfNeeded();
        widget.onFinishPressed?.call();
      }
    });
  }

  void _undoLastRound() {
    if (widget.isBusy) return;
    if (_playedRounds == 0 || (_currentRound == 1 && _roundMarks[0] == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('되돌릴 라운드가 없습니다.')),
      );
      return;
    }

    setState(() {
      int targetRound = _currentRound;
      if (_currentRound > _playedRounds) {
        targetRound = _playedRounds;
      }

      final idx = targetRound - 1;

      final removed = _roundMarks[idx];
      // removed 변수가 현재는 안 쓰이지만, 추후 디버깅이나 애니메이션에 활용 가능
      _roundMarks[idx] = 0;

      // 총 마크 재계산
      _totalMarks = _roundMarks.fold<int>(0, (sum, v) => sum + v);

      // 완료된 라운드 수 재계산
      final completedCount = _roundMarks.where((v) => v > 0).length;
      _playedRounds =
      completedCount > _totalRounds ? _totalRounds : completedCount;

      // 현재 라운드 index 보정
      if (targetRound < 1) {
        _currentRound = 1;
      } else if (targetRound > _totalRounds) {
        _currentRound = _totalRounds;
      } else {
        _currentRound = targetRound;
      }

      _selectedMarks = 0;

      // 자유 라운드를 되돌린 경우 타겟도 초기화
      if (_isFreeRound) {
        _freeTarget = null;
      }

      // 🔹 Undo 후에도 부모 진행률 갱신
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

    // 아직 한 라운드도 안 했으면 그냥 onFinishPressed만 호출
    if (_playedRounds == 0) {
      widget.onFinishPressed?.call();
      return;
    }

    // 현재까지 기록된 값으로 최종 전달
    _notifyCompletedIfNeeded();
    widget.onFinishPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final currentTarget = _currentTarget;
    final isBull = currentTarget == 'Bull';

    final titleText = widget.title ?? '크리켓 8R 실전 훈련';

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
                colors: [
                  Colors.teal.shade700,
                  Colors.teal.shade900,
                ],
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '라운드 $_currentRound / $_totalRounds',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isFreeRound ? '자유 타겟' : '타겟',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentTarget,
                  style: TextStyle(
                    fontSize: _isFreeRound
                        ? 28 // 자유 선택일 때만 글자 크기 다운
                        : (isBull ? 52 : 64),
                    fontWeight: FontWeight.w900,
                    color: isBull ? Colors.yellow.shade300 : Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                if (_isFreeRound && _freeTarget == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '아래에서 자유 라운드 타겟을 선택하세요',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 12),
                // 현재 MPR + 총 마크
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(999),
                    border:
                    Border.all(color: Colors.cyanAccent, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.cyanAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '현재 MPR: $mprText',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '(총 마크: $_totalMarks)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 8R 자유 타겟 선택 (8R일 때만)
          if (_isFreeRound)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '자유 라운드 타겟 선택',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          if (_isFreeRound) const SizedBox(height: 8),
          if (_isFreeRound)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _freeChoices.map((t) {
                final selected = _freeTarget == t;
                return ChoiceChip(
                  label: Text(
                    t,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.black : Colors.white,
                    ),
                  ),
                  selected: selected,
                  selectedColor: t == 'Bull'
                      ? Colors.amber.shade400
                      : Colors.cyanAccent,
                  backgroundColor: t == 'Bull'
                      ? Colors.amber.shade700
                      : Colors.teal.shade600,
                  onSelected: widget.isBusy
                      ? null
                      : (val) {
                    if (!val) return;
                    setState(() => _freeTarget = t);
                  },
                );
              }).toList(),
            ),

          if (_isFreeRound) const SizedBox(height: 18),

          // 마크 선택 영역
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '이번 라운드 마크 수 (0~9)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(10, (index) {
              final selected = _selectedMarks == index;
              return GestureDetector(
                onTap:
                widget.isBusy ? null : () => _selectMarks(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.cyan.shade600
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: selected
                        ? [
                      BoxShadow(
                        color:
                        Colors.cyan.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                        : null,
                    border: Border.all(
                      color: selected
                          ? Colors.cyan.shade800
                          : Colors.grey.shade300,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? Colors.white
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 18),

          // 라운드 확정 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
              widget.isBusy ? null : _submitCurrentRound,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 4,
              ),
              child: Text(
                _currentRound < _totalRounds
                    ? '이번 라운드 점수 확정'
                    : '8R 입력 완료',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Undo 버튼
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed:
              widget.isBusy ? null : _undoLastRound,
              icon:
              const Icon(Icons.undo_rounded, size: 18),
              label: const Text(
                '이전 라운드 되돌리기',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 드릴 종료 + 결과 저장 버튼
          TextButton(
            onPressed:
            widget.isBusy ? null : _onTapSaveAndFinish,
            child: const Text(
              '드릴 종료하고 결과 저장',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.cyan,
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
