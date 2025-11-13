// lib/presentation/screens/community/checkout/practice/checkout_result_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 추가
import 'package:daoapp/presentation/providers/checkout_provider.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class CheckoutResultScreen extends StatelessWidget {
  const CheckoutResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutProvider>(
      builder: (context, provider, child) {
        final history = provider.practiceHistory;

        // 성공한 턴 필터링
        final successTurns = history.where((turn) {
          if (turn.darts.isEmpty) return false;
          final lastDart = turn.darts.last;
          return lastDart.startsWith('D') || lastDart == 'Bull';
        }).toList();

        // 실패한 턴
        final failTurns = history.where((turn) => !successTurns.contains(turn)).toList();

        // 가장 많이 성공한 루트
        final routeCount = <String, int>{};
        for (var turn in successTurns) {
          final route = turn.darts.join(' → ');
          routeCount[route] = (routeCount[route] ?? 0) + 1;
        }
        final bestRoute = routeCount.isEmpty
            ? null
            : routeCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

        return Scaffold(
          appBar: AppBar(
            title: const Text("연습 결과"),
            centerTitle: true,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 요약 카드
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text("연습 요약", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem("총 턴", "${history.length}", Colors.blue),
                            _buildStatItem("성공", "${successTurns.length}", Colors.green),
                            _buildStatItem("실패", "${failTurns.length}", Colors.red),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "성공률: ${history.isEmpty ? 0 : ((successTurns.length / history.length) * 100).toStringAsFixed(1)}%",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 최고의 마무리 루트
                if (bestRoute != null) ...[
                  Card(
                    color: Colors.amber[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.amber),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("최고 마무리 루트", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(bestRoute, style: const TextStyle(fontSize: 16)),
                                Text("${routeCount[bestRoute]}회 성공", style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 성공한 루트 리스트
                if (successTurns.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("성공한 마무리", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  ...successTurns.map((turn) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(turn.darts.join(" → ")),
                      subtitle: Text("남은 점수: ${turn.scoreBefore}"),
                    ),
                  )),
                  const SizedBox(height: 24),
                ],

                // 실패한 루트 리스트
                if (failTurns.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("실패한 시도", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  ...failTurns.map((turn) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.red[50],
                    child: ListTile(
                      leading: const Icon(Icons.cancel, color: Colors.red),
                      title: Text(turn.darts.join(" → ")),
                      subtitle: Text("남은 점수: ${turn.scoreBefore}"),
                    ),
                  )),
                ],

                const SizedBox(height: 32),

                // 다시 연습하기 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final newProvider = CheckoutProvider()..startPractice(501);
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteConstants.checkoutPractice,
                            (route) => route.settings.name == RouteConstants.checkoutHome,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("다시 연습하기", style: TextStyle(fontSize: 18)),
                  ),
                ),

                const SizedBox(height: 16),

                // 홈으로 가기
                TextButton(
                  onPressed: () => Navigator.popUntil(context, ModalRoute.withName(RouteConstants.checkoutHome)),
                  child: const Text("체크아웃 홈으로 돌아가기"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}