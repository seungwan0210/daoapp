// lib/presentation/screens/training/drills/widgets/specialized/top_bottom_board_panel.dart

import 'package:flutter/material.dart';

class TopBottomBoardPanel extends StatefulWidget {
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;
  final bool isBusy;
  final int totalDarts; // 예: 60 (상단 30 + 하단 30)

  const TopBottomBoardPanel({
    super.key,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.isBusy = false,
    required this.totalDarts,
  });

  @override
  State<TopBottomBoardPanel> createState() => _TopBottomBoardPanelState();
}

class _TopBottomBoardPanelState extends State<TopBottomBoardPanel> {
  int _thrown = 0;
  int _successCount = 0;

  late final int _dartsPerArea;

  @override
  void initState() {
    super.initState();
    _dartsPerArea = (widget.totalDarts <= 0 ? 60 : widget.totalDarts) ~/ 2;
  }

  bool get _isFinished => _thrown >= widget.totalDarts;
  bool get _isTopPhase => _thrown < _dartsPerArea;

  int get _currentInArea => (_thrown % _dartsPerArea) + 1;

  void _record(bool success) {
    if (widget.isBusy || _isFinished) return;

    setState(() {
      _thrown++;
      if (success) _successCount++;
    });

    if (success) {
      widget.onHitSuccess?.call();
    } else {
      widget.onHitFail?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color highlightColor = _isTopPhase
        ? const Color(0xFFE91E63) // 상단: 핫핑크
        : const Color(0xFFFF6D00); // 하단: 오렌지

    final String mainTitle = _isTopPhase ? '상단 영역 집중' : '하단 영역 집중';
    final String subtitle =
    _isTopPhase ? '위쪽 반만 정확히 노려주세요!' : '아래쪽 반만 노려주세요!';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),

          // 보드 + 오버레이 + 텍스트 정보
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 기본 보드
                      ClipOval(
                        child: Image.asset(
                          'assets/images/dartboard.png',
                          width: 260,
                          height: 260,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // 활성 영역(위/아래) 정확히 반원만 색 입히기
                      ShaderMask(
                        blendMode: BlendMode.srcATop,
                        shaderCallback: (Rect bounds) {
                          if (_isTopPhase) {
                            // 위쪽 반원만 색 → 중간에서 딱 끊김
                            return LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                highlightColor.withOpacity(0.7),
                                highlightColor.withOpacity(0.7),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 0.5, 1.0],
                            ).createShader(bounds);
                          } else {
                            // 아래쪽 반원만 색
                            return LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                highlightColor.withOpacity(0.7),
                                highlightColor.withOpacity(0.7),
                              ],
                              stops: const [0.0, 0.5, 0.5, 1.0],
                            ).createShader(bounds);
                          }
                        },
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/dartboard.png',
                            width: 260,
                            height: 260,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 메인 타이틀
                Text(
                  mainTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // 부제목
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // 진행 정보
                _buildInfoRow('이번 구역', '$_currentInArea / $_dartsPerArea 다트'),
                _buildInfoRow(
                    '전체 진행', '$_thrown / ${widget.totalDarts} 다트'),
                _buildInfoRow(
                  '성공률',
                  _thrown == 0
                      ? '--'
                      : '${((_successCount / _thrown) * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20), // 진행 카드와 간격 조금 줄인 값

          // 성공 / 실패 버튼
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                  widget.isBusy || _isFinished ? null : () => _record(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 8,
                  ),
                  child: const Text(
                    "성공",
                    style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 8,
                  ),
                  child: const Text(
                    "실패",
                    style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (_isFinished)
            ElevatedButton(
              onPressed: widget.onFinishPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 10,
              ),
              child: const Text(
                "결과 확인하기",
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            )
          else
            TextButton(
              onPressed: widget.isBusy ? null : widget.onFinishPressed,
              child: Text(
                "드릴 종료하고 결과 저장",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan.shade400,
                ),
              ),
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}