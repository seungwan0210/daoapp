// lib/presentation/screens/training/drills/widgets/specialized/top_bottom_board_panel.dart

import 'package:flutter/material.dart';

class TopBottomBoardPanel extends StatelessWidget {
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;

  /// ✅ Undo 지원 (선택)
  final bool canUndo;
  final VoidCallback? onUndo;

  final bool isBusy;
  final int totalDarts; // 예: 60 (상단 30 + 하단 30)

  /// ✅ RunScreen의 thrownDarts를 그대로 받아서 UI 표시까지 동기화
  final ValueNotifier<int>? thrownDartsNotifier;

  const TopBottomBoardPanel({
    super.key,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.canUndo = false,
    this.onUndo,
    this.isBusy = false,
    required this.totalDarts,
    this.thrownDartsNotifier,
  });

  void _record(bool success, int thrown) {
    if (isBusy) return;
    if (thrown >= totalDarts) return;

    if (success) {
      onHitSuccess?.call();
    } else {
      onHitFail?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content(int thrown) {
      final int safeTotal = (totalDarts <= 0 ? 60 : totalDarts);
      final int dartsPerArea = (safeTotal ~/ 2);

      final bool isFinished = thrown >= safeTotal;
      final bool isTopPhase = thrown < dartsPerArea;

      // ✅ “이번 구역” 진행은 1부터 보이게
      final int currentInArea = (thrown % dartsPerArea) + 1;

      final Color highlightColor = isTopPhase
          ? const Color(0xFFE91E63) // 상단: 핫핑크
          : const Color(0xFFFF6D00); // 하단: 오렌지

      final String mainTitle = isTopPhase ? '상단 영역 집중' : '하단 영역 집중';
      final String subtitle =
      isTopPhase ? '위쪽 반만 정확히 노려주세요!' : '아래쪽 반만 노려주세요!';

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
                            if (isTopPhase) {
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

                  const SizedBox(height: 12),

                  // ✅ Undo (선택)
                  if (onUndo != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: (isBusy || !canUndo) ? null : onUndo,
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text(
                          'UNDO',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // 진행 정보
                  _buildInfoRow('이번 구역', '$currentInArea / $dartsPerArea 다트'),
                  _buildInfoRow('전체 진행', '$thrown / $safeTotal 다트'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 성공 / 실패 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                    isBusy || isFinished ? null : () => _record(true, thrown),
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
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isBusy || isFinished
                        ? null
                        : () => _record(false, thrown),
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
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            if (isFinished)
              ElevatedButton(
                onPressed: onFinishPressed,
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
                onPressed: isBusy ? null : onFinishPressed,
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

    // ✅ notifier가 있으면 UI 완전 동기화
    if (thrownDartsNotifier != null) {
      return ValueListenableBuilder<int>(
        valueListenable: thrownDartsNotifier!,
        builder: (_, thrown, __) => content(thrown),
      );
    }

    // ✅ notifier가 없으면(구버전 호환) 0으로 표시 (권장: notifier 넘겨라)
    return content(0);
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
