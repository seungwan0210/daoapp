// lib/presentation/screens/training/checkout/checkout_practice_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/presentation/providers/checkout_provider.dart'; // 공용 Provider 사용!
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/core/constants/checkout_table.dart';
import 'package:daoapp/data/models/practice_session_summary.dart';

// 트레이닝 전용 위젯
import 'package:daoapp/presentation/screens/training/widgets/dartboard_widget.dart';

class CheckoutPracticeScreen extends ConsumerWidget {
  const CheckoutPracticeScreen({super.key});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "최적 체크아웃 루트 ($remainingScore점)",
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green, width: 3),
                ),
                child: Column(
                  children: [
                    const Text("최적 루트 (PDC 공식)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Text(
                      routeData.primary.join(" → "),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Text("(${routeData.primary.length}다트)", style: const TextStyle(fontSize: 16, color: Colors.green)),
                  ],
                ),
              ),
              if (routeData.alts.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text("대안 루트", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...routeData.alts.map((alt) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text("• ${alt.join(" → ")} (${alt.length}다트)", style: const TextStyle(fontSize: 15)),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("닫기", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.read(checkoutProvider.notifier);
    final state = ref.watch(checkoutProvider);

    // 연습 종료 → 결과 화면 이동
    if (state.isPracticing && state.remainingScore <= 0 && state.currentTurn.isEmpty) {
      Future.microtask(() {
        final summary = PracticeSessionSummary(
          elapsedSeconds: state.elapsedSeconds,
          results: state.practiceHistory.map((turn) => PracticeResult(
            scoreBefore: turn.scoreBefore,
            darts: turn.darts,
            isSuccess: true,
            dartsUsed: turn.darts.length, // 이거 추가!
          )).toList(),
        );

        Navigator.pushReplacementNamed(
          context,
          RouteConstants.checkoutResult,
          arguments: summary,
        );
      });
      return const Center(child: CircularProgressIndicator());
    }

    final boardSize = MediaQuery.of(context).size.width - 32;

    return Scaffold(
      appBar: const CommonAppBar(title: "체크아웃 연습"),
      body: Column(
        children: [
          // 다트보드
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: boardSize,
              height: boardSize,
              child: DartboardWidget(
                size: boardSize,
                onSegmentTap: provider.inputDart,
              ),
            ),
          ),

          // 점수 + 타이머 카드
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("남은 점수", style: TextStyle(fontSize: 15, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Text(
                            "${state.remainingScore}",
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: state.remainingScore <= 60 ? Colors.red[700] : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text("이번 턴", style: TextStyle(fontSize: 15, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Text(
                            state.currentTurn.isEmpty ? "—" : state.currentTurn.join(" → "),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatTime(state.elapsedSeconds ?? 0),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: List.generate(3, (i) {
                              final active = state.currentTurn.length > i;
                              return Container(
                                margin: const EdgeInsets.only(left: 8),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: active ? Colors.green : Colors.grey[300],
                                  border: Border.all(color: Colors.black26, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    "${i + 1}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
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
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 액션 버튼들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.currentTurn.isNotEmpty ? provider.undoLast : null,
                    icon: const Icon(Icons.undo),
                    label: const Text("되돌리기"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[600], padding: const EdgeInsets.all(16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.currentTurn.isNotEmpty ? () => provider.finishTurn(context) : null,
                    icon: const Icon(Icons.check_circle),
                    label: const Text("확인"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.currentTurn.isNotEmpty ? Colors.green : Colors.grey,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 64,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () => _showHintDialog(context, state.remainingScore),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Icon(Icons.lightbulb, size: 28, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 피드백 박스
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              color: state.isBust
                  ? Colors.red[50]
                  : state.currentTurn.isEmpty
                  ? null
                  : state.currentEfficiency >= 100
                  ? Colors.green[50]
                  : Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  state.isBust
                      ? "BUST! 다음 문제로 넘어갑니다..."
                      : state.currentTurn.isEmpty
                      ? "다트를 던져보세요"
                      : state.currentEfficiency >= 100
                      ? "완벽한 체크아웃! ${state.currentOptimalDarts}다트"
                      : "최적: ${state.currentOptimalDarts}다트 → 현재 ${state.currentEfficiency.toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: state.isBust
                        ? Colors.red[800]
                        : state.currentEfficiency >= 100
                        ? Colors.green[800]
                        : Colors.orange[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}