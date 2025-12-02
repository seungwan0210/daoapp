// lib/presentation/screens/training/history/training_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/training/training_history_provider.dart';
import 'package:daoapp/presentation/screens/training/history/training_session_detail_screen.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class TrainingHistoryScreen extends ConsumerWidget {
  const TrainingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(trainingRecentSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("트레이닝 히스토리"),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.cyan,
      ),
      backgroundColor: const Color(0xFF0D001A),
      body: historyAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    "아직 저장된 트레이닝 기록이 없습니다.\n지금 바로 연습을 시작해보세요!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final s = sessions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TrainingSessionDetailScreen(session: s),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade800,
                      child: Text(
                        s.drillTitle.isNotEmpty ? s.drillTitle[0] : "?",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      s.drillTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      "${s.startedAt.toLocal().toString().substring(0, 16)} ~ "
                          "${s.endedAt.toLocal().toString().substring(0, 16)}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${(s.hitRate * 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: s.hitRate >= 0.7
                                ? Colors.cyan
                                : s.hitRate >= 0.5
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        Text(
                          "${s.successCount}/${s.totalAttempts} 다트",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.cyan),
        ),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text(
                "기록을 불러오지 못했습니다",
                style: TextStyle(color: Colors.red),
              ),
              Text(
                "$e",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
