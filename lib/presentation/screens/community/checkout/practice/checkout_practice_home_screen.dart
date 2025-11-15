import 'package:flutter/material.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class CheckoutPracticeHomeScreen extends StatelessWidget {
  const CheckoutPracticeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 나중에 Firestore에서 실제 기록 불러오기
    final dummyHistory = [
      {"date": "2025-11-14", "time": "01:23", "successRate": 0.7},
      {"date": "2025-11-13", "time": "01:45", "successRate": 0.5},
    ];

    return Scaffold(
      appBar: const CommonAppBar(title: "체크아웃 연습 모드"),
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
                    const Text(
                      "랜덤 10문제 체크아웃 연습",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "실제 다트보드를 터치해서 10개의 체크아웃 문제를 풀어보세요.",
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            RouteConstants.checkoutPracticePlay,
                          );
                        },
                        child: const Text("연습 시작하기"),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "최근 연습 기록",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: dummyHistory.length,
                itemBuilder: (context, index) {
                  final item = dummyHistory[index];
                  return AppCard(
                    child: ListTile(
                      title: Text(item["date"] as String),
                      subtitle: Text(
                        "소요 시간: ${item['time']}",
                      ),
                      trailing: Text(
                          "성공률 ${((item['successRate'] as double) * 100).toStringAsFixed(0)}%"
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
