// lib/presentation/screens/community/checkout/practice/checkout_practice_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoapp/presentation/providers/checkout_practice_provider.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'widgets/dartboard_widget.dart';
import 'widgets/remaining_score_display.dart';

/// 이 화면 전용 AppCard (기존 그대로 유지)
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

class CheckoutPracticeScreen extends StatelessWidget {
  const CheckoutPracticeScreen({super.key});

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
        _navigatedToResult = false;
        return CheckoutPracticeProvider()..startNewPractice();
      },
      child: Scaffold(
        appBar: const CommonAppBar(title: "체크아웃 연습"),
        body: Consumer<CheckoutPracticeProvider>(
          builder: (context, provider, _) {
            // 연습 종료 처리
            if (provider.isFinished && !_navigatedToResult) {
              _navigatedToResult = true;
              Future(() async {
                await provider.finishPractice();
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
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.currentProblem == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final screenWidth = MediaQuery.of(context).size.width;
            final boardSize = screenWidth - 32;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 다트보드
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

                // 점수 + 타이머 카드 (당신이 좋아했던 그 크기 그대로!)
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
                                Text("남은 점수", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                const SizedBox(height: 4),
                                Text("${provider.remainingScore}", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Text("이번 턴", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                const SizedBox(height: 4),
                                Text(
                                  provider.currentDarts.isEmpty ? "-" : provider.currentDarts.join(", "),
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
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _formatTime(provider.elapsedSeconds),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: List.generate(3, (i) {
                                    final isActive = provider.dartCount > i;
                                    return Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isActive ? Colors.green : Colors.grey[300],
                                        border: Border.all(color: Colors.black26),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${i + 1}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: isActive ? Colors.white : Colors.black54,
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

                // 되돌리기 + 확인 버튼 (당신이 좋아했던 위치 그대로!)
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
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: provider.canConfirm ? provider.confirmCurrentProblem : null,
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text("확인"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: provider.canConfirm ? Colors.green : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 최적화율 + BUST 피드백 (당신이 좋아했던 스타일 그대로 + BUST 추가)
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

                // 하단 여유 공간 확보 (제스처 바 침범 방지)
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }
}