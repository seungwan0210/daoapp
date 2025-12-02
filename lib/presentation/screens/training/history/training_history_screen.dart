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
        title: const Text(
          "트레이닝 히스토리",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,      // 🔹 라이트 모드 앱바
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      backgroundColor: Colors.white,        // 🔹 전체 배경 흰색
      body: historyAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "아직 저장된 트레이닝 기록이 없습니다.\n지금 바로 연습을 시작해보세요!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
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

              // 🔹 null-safe 처리
              final double hitRate = s.hitRate ?? 0.0;
              final String hitRateText =
              (hitRate * 100).toStringAsFixed(1);

              final int successCount = s.successCount ?? 0;
              final int totalAttempts = s.totalAttempts ?? 0;

              final Color rateColor =
              hitRate >= 0.7
                  ? (Colors.cyan[700]!)
                  : hitRate >= 0.5
                  ? (Colors.green[600]!)
                  : (Colors.orange[700]!);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            TrainingSessionDetailScreen(session: s),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.cyan[700],
                      child: Text(
                        s.drillTitle.isNotEmpty
                            ? s.drillTitle[0]
                            : "?",
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
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      "${s.startedAt.toLocal().toString().substring(0, 16)} ~ "
                          "${s.endedAt.toLocal().toString().substring(0, 16)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "$hitRateText%",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: rateColor,
                          ),
                        ),
                        Text(
                          "$successCount/$totalAttempts 다트",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
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
          child: CircularProgressIndicator(
            color: Colors.cyan,
          ),
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
              const SizedBox(height: 8),
              Text(
                "$e",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
