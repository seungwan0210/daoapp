import 'package:flutter/material.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class TodayTasksScreen extends StatelessWidget {
  const TodayTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = [
      "60점 → S20 / D20",
      "81점 → T15 / D18",
      "96점 → T20 / D18",
      "120점 → T20 / S20 / D20",
    ];

    return Scaffold(
      appBar: const CommonAppBar(title: "오늘의 체크아웃 과제"),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (_, i) {
          return AppCard(
            child: ListTile(
              title: Text(tasks[i], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("클릭해서 바로 연습해보기"),
              trailing: const Icon(Icons.play_arrow),
              onTap: () {
                // TODO: 해당 점수로 바로 연습 시작
              },
            ),
          );
        },
      ),
    );
  }
}
