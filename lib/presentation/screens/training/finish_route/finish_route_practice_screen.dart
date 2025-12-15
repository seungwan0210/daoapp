// lib/presentation/screens/training/finish_route/finish_route_practice_screen.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/core/constants/checkout_table.dart';

// ✅ finish route provider
import 'package:daoapp/presentation/providers/training/finish_route/finish_route_practice_provider.dart';

// ✅ widgets
import 'widgets/dartboard_widget.dart';
import 'widgets/remaining_score_display.dart';

class FinishRoutePracticeScreen extends StatelessWidget {
  const FinishRoutePracticeScreen({super.key});
  static bool _navigatedToResult = false;

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void _showHintDialog(BuildContext context, int remainingScore) {
    final routeData = checkoutTable[remainingScore.toString()];
    if (routeData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이 점수에 대한 체크아웃 루트가 없습니다.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("추천 피니시 루트 ($remainingScore점)", textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  children: [
                    const Text("최적 루트", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      routeData.primary.join(" → "),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "(${routeData.primary.length}다트)",
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
              if (routeData.alts.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text("대안 루트", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...routeData.alts.map(
                      (alt) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text("• ${alt.join(" → ")} (${alt.length}다트)"),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("닫기"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        _navigatedToResult = false;
        return FinishRoutePracticeProvider()..startNewPractice();
      },
      child: Scaffold(
        appBar: const CommonAppBar(title: "피니시 루트 연습"),
        body: Consumer<FinishRoutePracticeProvider>(
          builder: (context, provider, _) {
            // ✅ 종료 → 결과 화면 이동
            if (provider.isFinished && !_navigatedToResult) {
              _navigatedToResult = true;
              Future(() async {
                await provider.finishPractice();
                if (!context.mounted) return;

                final summary = FinishRoutePracticeSessionSummary(
                  elapsedSeconds: provider.elapsedSeconds,
                  results: List.from(provider.results),
                );

                Navigator.pushReplacementNamed(
                  context,
                  RouteConstants.finishRouteResult,
                  arguments: summary,
                );
              });
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.currentProblem == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                // ✅ 보드 사이즈를 "화면 높이"에도 맞춰서 자동 조절
                // - 너무 커서 아래 UI를 밀어내는 걸 방지
                final safeBoard = min(width - 32, constraints.maxHeight * 0.46);
                final boardSize = safeBoard.clamp(240.0, width - 32);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // =========================
                    // 1) 다트보드 (상단 고정)
                    // =========================
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                      child: SizedBox(
                        width: boardSize,
                        height: boardSize,
                        child: DartboardWidget(
                          size: boardSize,
                          onSegmentTap: provider.inputDart,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // =========================
                    // 2) 아래 영역은 스크롤 (오버플로우 방지)
                    // =========================
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 점수 카드
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: RemainingScoreDisplay(
                                remainingScore: provider.remainingScore,
                                currentDarts: provider.currentDarts,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // 타이머 + 다트 인디케이터 카드
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.75),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _formatTime(provider.elapsedSeconds),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: List.generate(3, (i) {
                                          final active = provider.dartCount > i;
                                          return Container(
                                            margin: const EdgeInsets.only(left: 6),
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: active ? Colors.green : Colors.grey[300],
                                              border: Border.all(color: Colors.black26),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "${i + 1}",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: active ? Colors.white : Colors.black54,
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 되돌리기 + 확인 + 힌트
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: provider.dartCount > 0 ? provider.undoLastDart : null,
                                      icon: const Icon(Icons.undo, size: 16),
                                      label: const Text("되돌리기"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: provider.canConfirm ? provider.confirmCurrentProblem : null,
                                      icon: const Icon(Icons.check_circle, size: 16),
                                      label: const Text("확인"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: provider.canConfirm ? Colors.green : Colors.grey,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 56,
                                    child: ElevatedButton(
                                      onPressed: () => _showHintDialog(context, provider.remainingScore),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[600],
                                        padding: const EdgeInsets.all(14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Icon(Icons.lightbulb, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 피드백 박스
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: provider.isBust
                                      ? Colors.red[50]
                                      : provider.currentEfficiency >= 100
                                      ? Colors.green[50]
                                      : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: provider.isBust
                                        ? Colors.red
                                        : provider.currentEfficiency >= 100
                                        ? Colors.green
                                        : Colors.orange,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    provider.isBust
                                        ? "BUST! 0점으로 처리 후 ‘확인’ 버튼을 눌러 다음 문제로 넘어가세요."
                                        : provider.dartCount == 0
                                        ? "다트보드를 눌러 입력하세요"
                                        : provider.remainingScore == 0
                                        ? "마무리! ‘확인’ 버튼을 눌러 다음 문제로"
                                        : provider.currentEfficiency >= 100
                                        ? "최적! ${provider.currentOptimalDarts}다트 페이스"
                                        : "최적: ${provider.currentOptimalDarts}다트 (현재: ${provider.dartCount}다트 → ${provider.currentEfficiency.toStringAsFixed(0)}%)",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: provider.isBust
                                          ? Colors.red[800]
                                          : provider.currentEfficiency >= 100
                                          ? Colors.green[800]
                                          : Colors.orange[800],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // 실패(스킵)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: OutlinedButton.icon(
                                onPressed: provider.failCurrentProblem,
                                icon: const Icon(Icons.close),
                                label: const Text("이번 문제 실패(스킵)"),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // 홈으로
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.popUntil(
                                    context,
                                    ModalRoute.withName(RouteConstants.finishRouteHome),
                                  );
                                },
                                icon: const Icon(Icons.arrow_back),
                                label: const Text("피니시 루트 홈으로 돌아가기"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
