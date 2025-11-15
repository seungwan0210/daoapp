// lib/presentation/screens/community/checkout/practice/checkout_practice_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoapp/presentation/providers/checkout_practice_provider.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/screens/community/checkout/practice/widgets/dartboard_widget.dart';
import 'package:daoapp/core/constants/route_constants.dart';

/// 이 화면 전용 AppCard (전역 AppCard랑 충돌 안 하게 여기서만 사용)
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

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckoutPracticeProvider()..startNewPractice(),
      child: Scaffold(
        appBar: const CommonAppBar(title: "체크아웃 연습"),
        body: Consumer<CheckoutPracticeProvider>(
          builder: (context, provider, _) {
            final problem = provider.currentProblem;

            // ✅ 10문제 끝나면: 요약 만들어서 결과 화면으로 이동
            if (provider.isFinished) {
              Future.microtask(() {
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
            }

            // 문제 준비 중일 때 로딩
            if (problem == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // 화면 너비 기준으로 보드 크기 계산
            final screenWidth = MediaQuery.of(context).size.width;
            final boardSize = screenWidth - 32;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // === 다트보드 ===
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                  child: SizedBox(
                    width: boardSize,
                    height: boardSize,
                    child: DartboardWidget(
                      size: boardSize,
                      onSegmentTap: (segment) {
                        provider.inputDart(segment);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // === 남은 점수 / 이번 턴 / 타이머 / 다트 상태 카드 ===
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppCard(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // 왼쪽: 남은 점수 + 이번 턴
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "남은 점수",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
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
                                Text(
                                  "이번 턴",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
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

                          // 오른쪽: 타이머 + 다트 3개 상태
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // 타이머 뱃지
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 12),
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
                                // 1 / 2 / 3 다트 인디케이터
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
                                        color: isActive
                                            ? Colors.green
                                            : Colors.grey[300],
                                        border:
                                        Border.all(color: Colors.black26),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${i + 1}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: isActive
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

                const SizedBox(height: 8),

                // === 수정 / 확인 버튼 줄 ===
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // 수정 버튼: 이번 턴 전체 리셋
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: provider.dartCount > 0
                              ? provider.clearCurrentTurn
                              : null,
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text("수정"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 확인 버튼: 정답(0점 + 더블 아웃)일 때만 활성화
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
                            foregroundColor: Colors.white,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // === 실시간 최적화율 안내 박스 ===
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: provider.currentEfficiency >= 100
                          ? Colors.green[50]
                          : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: provider.currentEfficiency >= 100
                            ? Colors.green
                            : Colors.orange,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        provider.dartCount == 0
                            ? "다트를 던져보세요"
                            : provider.currentEfficiency >= 100
                            ? "최적! ${provider.currentOptimalDarts}다트 완료"
                            : "최적: ${provider.currentOptimalDarts}다트 (현재: ${provider.dartCount}다트 → ${provider.currentEfficiency.toStringAsFixed(0)}%)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: provider.currentEfficiency >= 100
                              ? Colors.green[800]
                              : Colors.orange[800],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}
