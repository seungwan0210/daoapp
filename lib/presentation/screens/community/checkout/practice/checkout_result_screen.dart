// lib/presentation/screens/community/checkout/practice/checkout_result_screen.dart
import 'package:flutter/material.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/providers/checkout_practice_provider.dart';
// ↑ 여기서 Provider는 안 쓰고, PracticeSessionSummary / PracticeResult 타입만 쓸 거야

class CheckoutResultScreen extends StatelessWidget {
  const CheckoutResultScreen({super.key});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 연습 화면에서 넘겨준 arguments 받아오기
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! PracticeSessionSummary) {
      return Scaffold(
        appBar: const CommonAppBar(title: "연습 결과"),
        body: const Center(
          child: Text("결과 데이터를 불러올 수 없습니다."),
        ),
      );
    }

    final summary = args;
    final results = summary.results;

    final total = results.length;
    final successCount = results.where((r) => r.success).length;
    final successRate = total > 0 ? successCount / total * 100 : 0.0;

    final usedDarts = results.map((r) => r.dartsUsed).toList();
    final avgDarts = usedDarts.isEmpty
        ? 0.0
        : usedDarts.reduce((a, b) => a + b) / usedDarts.length;

    return Scaffold(
      appBar: const CommonAppBar(title: "연습 결과"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppCard(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "총 소요 시간",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(summary.elapsedSeconds),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "성공률: ${successRate.toStringAsFixed(0)}%",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "평균 사용 다트: ${avgDarts.toStringAsFixed(1)} 다트",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final r = results[index];
                  return AppCard(
                    child: ListTile(
                      title: Text("문제 ${index + 1}: ${r.problem.targetScore}"),
                      subtitle: Text(
                        r.success
                            ? "${r.dartsUsed} 다트 성공"
                            : "실패",
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
