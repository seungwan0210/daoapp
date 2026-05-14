// lib/presentation/screens/training/drills/widgets/specialized/top_bottom_board_panel.dart

import 'package:flutter/material.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 임포트 경로 확인

class TopBottomBoardPanel extends StatelessWidget {
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;

  final bool canUndo;
  final VoidCallback? onUndo;

  final bool isBusy;
  final int totalDarts;

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
    // 🔹 S 대신 AppLocalizations 사용
    final s = AppLocalizations.of(context)!;

    Widget content(int thrown) {
      final int safeTotal = (totalDarts <= 0 ? 60 : totalDarts);
      final int dartsPerArea = (safeTotal ~/ 2);

      final bool isFinished = thrown >= safeTotal;
      final bool isTopPhase = thrown < dartsPerArea;

      final int currentInArea = (thrown % dartsPerArea) + 1;

      final Color highlightColor = isTopPhase
          ? const Color(0xFFE91E63) // 상단: 핫핑크
          : const Color(0xFFFF6D00); // 하단: 오렌지

      // 🔹 타이틀 및 가이드 텍스트 (기존 키 활용)
      final String mainTitle = isTopPhase ? s.drill_top_half : s.drill_bottom_half;
      // 가이드 키가 따로 없을 경우 범용 가이드 키(drill_quadrant_guide) 사용
      final String subtitle = s.drill_quadrant_guide;

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
                        ClipOval(
                          child: Image.asset(
                            'assets/images/dartboard.png',
                            width: 260,
                            height: 260,
                            fit: BoxFit.cover,
                          ),
                        ),

                        ShaderMask(
                          blendMode: BlendMode.srcATop,
                          shaderCallback: (Rect bounds) {
                            // 상단/하단 강조 그라데이션
                            return LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isTopPhase
                                  ? [highlightColor.withOpacity(0.7), highlightColor.withOpacity(0.7), Colors.transparent, Colors.transparent]
                                  : [Colors.transparent, Colors.transparent, highlightColor.withOpacity(0.7), highlightColor.withOpacity(0.7)],
                              stops: const [0.0, 0.5, 0.5, 1.0],
                            ).createShader(bounds);
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

                  Text(
                    mainTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

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

                  // UNDO 버튼
                  if (onUndo != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: (isBusy || !canUndo) ? null : onUndo,
                        icon: const Icon(Icons.undo, size: 18),
                        label: Text(
                          s.calc_undo.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // 🔹 정보 행 다국어화
                  _buildInfoRow(
                      s.drill_quadrant_title, // "이번 구역 진행" 또는 "에어리어 연습"
                      '$currentInArea / $dartsPerArea ${s.drill_stat_darts}'
                  ),
                  _buildInfoRow(
                      s.drill_progress_title, // "진행률" 또는 "전체 진행"
                      '$thrown / $safeTotal ${s.drill_stat_darts}'
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 성공 / 실패 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isBusy || isFinished ? null : () => _record(true, thrown),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 8,
                    ),
                    child: Text(
                      s.drill_btn_success,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isBusy || isFinished ? null : () => _record(false, thrown),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 8,
                    ),
                    child: Text(
                      s.drill_btn_fail,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                child: Text(
                  s.drill_check_result,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              )
            else
              TextButton(
                onPressed: isBusy ? null : onFinishPressed,
                child: Text(
                  s.drill_btn_finish_save,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
              ),

            const SizedBox(height: 12),
          ],
        ),
      );
    }

    if (thrownDartsNotifier != null) {
      return ValueListenableBuilder<int>(
        valueListenable: thrownDartsNotifier!,
        builder: (_, thrown, __) => content(thrown),
      );
    }

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