// lib/presentation/screens/training/history/training_session_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class TrainingSessionDetailScreen extends StatelessWidget {
  final TrainingSessionModel session;

  const TrainingSessionDetailScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final double hitRatePercent = session.hitRate * 100;
    final String rateText = hitRatePercent.toStringAsFixed(1);

    // 성공률에 따라 색상 결정
    Color rateColor;
    if (hitRatePercent >= 80) {
      rateColor = Colors.cyan;
    } else if (hitRatePercent >= 60) {
      rateColor = Colors.green;
    } else if (hitRatePercent >= 40) {
      rateColor = Colors.yellow;
    } else {
      rateColor = Colors.orange;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D001A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "트레이닝 상세",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        foregroundColor: Colors.cyan,
        iconTheme: const IconThemeData(color: Colors.cyan),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            // 드릴 제목 & ID
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.drillTitle,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "드릴 ID: ${session.drillId}",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.access_time_filled,
                            color: Colors.purpleAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "연습 시간",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${session.startedAt.toLocal().toString().substring(0, 16)}\n→ ${session.endedAt.toLocal().toString().substring(0, 16)}",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 성공률 + 성공/시도
            AppCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            "성공률",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "$rateText%",
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: rateColor,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 0),
                                  blurRadius: 20,
                                  color: rateColor.withOpacity(0.6),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 80,
                      color: Colors.grey[700],
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            "성공 / 시도",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            session.successCount.toString(),
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyan,
                            ),
                          ),
                          Text(
                            "/ ${session.totalAttempts} 다트",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 추가 정보 (extra)
            if (session.extra != null && session.extra!.isNotEmpty)
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.code, color: Colors.purpleAccent),
                          const SizedBox(width: 10),
                          const Text(
                            "드릴 설정 정보",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.purpleAccent.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: SelectableText(
                          session.extra.toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontFamily: 'RobotoMono',
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}