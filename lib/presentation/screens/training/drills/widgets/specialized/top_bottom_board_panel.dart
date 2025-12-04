// lib/presentation/screens/training/drills/widgets/specialized/top_bottom_board_panel.dart

import 'package:flutter/material.dart';

class TopBottomBoardPanel extends StatefulWidget {
  /// 성공 버튼 눌렀을 때 (DrillRunScreen의 _recordHit(true)로 연결)
  final VoidCallback? onHitSuccess;

  /// 실패 버튼 눌렀을 때 (DrillRunScreen의 _recordHit(false)로 연결)
  final VoidCallback? onHitFail;

  /// 드릴 종료 / 결과 저장 버튼 눌렀을 때
  final VoidCallback? onFinishPressed;

  /// 상위에서 세션 시작/저장 중일 때 버튼 비활성화용
  final bool isBusy;

  /// 전체 계획 다트 수 (예: 60)
  final int totalDarts;

  const TopBottomBoardPanel({
    super.key,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.isBusy = false,
    this.totalDarts = 60,
  });

  @override
  State<TopBottomBoardPanel> createState() => _TopBottomBoardPanelState();
}

class _TopBottomBoardPanelState extends State<TopBottomBoardPanel> {
  /// 이 패널에서 처리한 다트 수 (로컬)
  int _thrown = 0;

  /// 이 패널 내 성공 카운트 (표시용)
  int _successCount = 0;

  /// 상/하 각각 몇 다트씩인지
  int get _dartsPerArea {
    final total = widget.totalDarts ?? 60;  // null이면 60으로 fallback
    final perArea = (total / 2).round();
    return perArea > 0 ? perArea : 30;  // 0이면 30으로 강제 설정
  }

  /// 전체 계획 다트를 다 던졌는지 여부
  bool get _isFinished => _thrown >= widget.totalDarts;

  /// 현재 상단 구간인지, 하단 구간인지
  bool get _isTopPhase => _thrown < _dartsPerArea;

  int get _dartInArea {
    if (_dartsPerArea == 0) return 1;  // 0 나누기 방지
    return (_thrown % _dartsPerArea) + 1;
  }

  void _record(bool success) {
    if (widget.isBusy || _isFinished) return;

    setState(() {
      _thrown++;
      if (success) _successCount++;
    });

    // 상위 런 스크린의 공통 로직 호출
    if (success) {
      widget.onHitSuccess?.call();
    } else {
      widget.onHitFail?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color areaColor = _isTopPhase
        ? const Color(0xFFE91E63) // 위: 핑크레드
        : const Color(0xFFFF6D00); // 아래: 오렌지

    final String subtitle =
    _isTopPhase ? "위쪽 반만 노려주세요!" : "아래쪽 반만 노려주세요!";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),

          // 1) 보드 + 상/하 오버레이 + 설명
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/dartboard.png',
                        width: 260,
                        height: 260,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // 상단 영역 하이라이트
                    Align(
                      alignment: Alignment.topCenter,
                      child: FractionallySizedBox(
                        heightFactor: 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                areaColor.withOpacity(_isTopPhase ? 0.6 : 0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 하단 영역 하이라이트
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                areaColor.withOpacity(_isTopPhase ? 0.1 : 0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _isTopPhase ? '현재: 상단 영역 집중' : '현재: 하단 영역 집중',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '이번 구역 진행: $_dartInArea / $_dartsPerArea 다트',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '성공: $_successCount / $_thrown',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 2) 성공 / 실패 버튼
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy || _isFinished
                      ? null
                      : () => _record(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "성공",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isBusy || _isFinished
                      ? null
                      : () => _record(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "실패",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3) 종료/저장 버튼
          if (_isFinished)
            ElevatedButton(
              onPressed: widget.onFinishPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "결과 확인하기",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            TextButton(
              onPressed: widget.isBusy ? null : widget.onFinishPressed,
              child: const Text(
                "드릴 종료하고 결과 저장",
                style: TextStyle(
                  fontSize: 14,
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
