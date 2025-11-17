// lib/presentation/screens/community/checkout/practice/checkout_practice_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoapp/presentation/providers/checkout_practice_provider.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'widgets/dartboard_widget.dart';
import 'widgets/remaining_score_display.dart';

/// 연습 플레이 화면 전용 AppCard (전역 AppCard와 충돌 방지)
class _LocalAppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  const _LocalAppCard({required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }
}

class CheckoutPracticeScreen extends StatelessWidget {
  const CheckoutPracticeScreen({super.key});

  // 연습 종료 후 결과 화면 이동을 딱 한 번만 하게 하는 플래그
  static bool _navigatedToResult = false;

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        _navigatedToResult = false; // 새 연습 시작 시 반드시 리셋
        return CheckoutPracticeProvider()..startNewPractice();
      },
      child: Scaffold(
        appBar: const CommonAppBar(title: "체크아웃 연습"),
        body: Consumer<CheckoutPracticeProvider>(
          builder: (context, provider, _) {
            // ==================== 연습 종료 처리 (핵심 패치) ====================
            if (provider.isFinished && !_navigatedToResult) {
              _navigatedToResult = true;

              Future(() async {
                await provider.finishPractice(); // 저장 완료까지 기다림

                if (!context.mounted) return;

                final summary = PracticeSessionSummary(
                  elapsedSeconds: provider.elapsedSeconds,
                  results: List<PracticeResult>.from(provider.results),
                );

                Navigator.pushReplacementNamed(
                  context,
                  RouteConstants.checkoutResult,
                  arguments: summary,
                );
              });

              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text("기록을 저장하고 있어요...", style: TextStyle(fontSize: 16)),
                  ],
                ),
              );
            }
            // =================================================================

            if (provider.currentProblem == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final screenWidth = MediaQuery.of(context).size.width;
            final boardSize = screenWidth - 32;

            return Column(
              children: [
                // 다트보드
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
                  child: SizedBox(
                    width: boardSize,
                    height: boardSize,
                    child: DartboardWidget(
                      size: boardSize,
                      onSegmentTap: provider.inputDart,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 점수 + 타이머 + 이번 턴 다트
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _LocalAppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: RemainingScoreDisplay(
                              remainingScore: provider.remainingScore,
                              currentDarts: provider.currentDarts,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _formatTime(provider.elapsedSeconds),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: List.generate(3, (i) {
                                    final active = provider.dartCount > i;
                                    return Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: active ? Colors.green : Colors.grey[300],
                                      ),
                                      child: Center(
                                        child: Text("${i + 1}", style: TextStyle(color: active ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
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

                // 되돌리기 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.dartCount > 0 ? provider.undoLastDart : null,
                      icon: const Icon(Icons.undo),
                      label: const Text("되돌리기"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // 최적화율 안내
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: provider.currentEfficiency >= 100 ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: provider.currentEfficiency >= 100 ? Colors.green : Colors.orange,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        provider.dartCount == 0
                            ? "다트를 던져보세요"
                            : provider.currentEfficiency >= 100
                            ? "최적 루트 완료! (${provider.currentOptimalDarts}다트)"
                            : "최적 ${provider.currentOptimalDarts}다트 → 현재 ${provider.dartCount}다트 (${provider.currentEfficiency.toStringAsFixed(0)}%)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: provider.currentEfficiency >= 100 ? Colors.green[800] : Colors.orange[800],
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),
              ],
            );
          },
        ),
      ),
    );
  }
}