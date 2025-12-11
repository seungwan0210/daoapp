// lib/presentation/screens/training/finish_route/finish_route_practice_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:daoapp/presentation/providers/checkout_practice_provider.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/core/constants/checkout_table.dart';

import 'widgets/dartboard_widget.dart';

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
        const SnackBar(content: Text("이 점수에 대한 피니쉬 루트가 없습니다.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "최적 피니쉬 루트 ($remainingScore점)",
          textAlign: TextAlign.center,
        ),
        content: Column(
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
                  const Text(
                    "최적 루트 (PDC 공식)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    routeData.primary.join(" → "),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
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
              const Text(
                "대안 루트",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...routeData.alts.map(
                    (alt) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    "• ${alt.join(" → ")} (${alt.length}다트)",
                  ),
                ),
              ),
            ],
          ],
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
        return CheckoutPracticeProvider()..startNewPractice();
      },
      child: Scaffold(
        appBar: const CommonAppBar(title: "피니쉬 루트 연습"),
        body: Consumer<CheckoutPracticeProvider>(
          builder: (context, provider, _) {
            // ✅ 연습이 끝나면 결과 화면으로 이동
            if (provider.isFinished && !_navigatedToResult) {
              _navigatedToResult = true;
              Future(() async {
                await provider.finishPractice();
                if (!context.mounted) return;

                final summary = PracticeSessionSummary(
                  elapsedSeconds: provider.elapsedSeconds,
                  results: List.from(provider.results),
                );

                Navigator.pushReplacementNamed(
                  context,
                  RouteConstants.finishRouteResult, // ✅ 피니쉬 루트 결과 라우트
                  arguments: summary,
                );
              });

              return const Center(child: CircularProgressIndicator());
            }

            if (provider.currentProblem == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final boardSize = MediaQuery.of(context).size.width - 32;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🎯 피니쉬 루트 연습용 다트보드
                Padding(
                  padding:
                  const EdgeInsets.only(top: 8, left: 16, right: 16),
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

                // 점수 + 타이머 카드
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppCard(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "남은 점수",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${provider.remainingScore}",
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "이번 턴",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  provider.currentDarts.isEmpty
                                      ? "-"
                                      : provider.currentDarts.join(", "),
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
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
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: List.generate(3, (i) {
                                    final active = provider.dartCount > i;
                                    return Container(
                                      margin:
                                      const EdgeInsets.only(left: 6),
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: active
                                            ? Colors.green
                                            : Colors.grey[300],
                                        border: Border.all(
                                          color: Colors.black26,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${i + 1}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: active
                                                ? Colors.white
                                                : Colors.black54,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 되돌리기 + 확인 + 힌트 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: provider.dartCount > 0
                              ? provider.undoLastDart
                              : null,
                          icon: const Icon(Icons.undo, size: 16),
                          label: const Text("되돌리기"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: provider.canConfirm
                              ? provider.confirmCurrentProblem
                              : null,
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text("확인"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: provider.canConfirm
                                ? Colors.green
                                : Colors.grey,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 56,
                        child: ElevatedButton(
                          onPressed: () => _showHintDialog(
                            context,
                            provider.remainingScore,
                          ),
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

                // 최적화율 + BUST 피드백
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
                            ? "BUST! 다음 문제로 넘어갑니다..."
                            : provider.dartCount == 0
                            ? "다트를 던져보세요"
                            : provider.currentEfficiency >= 100
                            ? "최적! ${provider.currentOptimalDarts}다트 완료"
                            : "최적: ${provider.currentOptimalDarts}다트 (현재: ${provider.dartCount}다트 → ${provider.currentEfficiency.toStringAsFixed(0)}%)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: provider.isBust
                              ? Colors.red[800]
                              : provider.currentEfficiency >= 100
                              ? Colors.green[800]
                              : Colors.orange[800],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }
}
