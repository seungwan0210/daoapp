// lib/presentation/screens/training/drills/drill_result_screen.dart
import 'package:flutter/material.dart';
import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

import '../history/training_session_detail_screen.dart';
import 'drill_run_screen.dart';

class DrillResultScreen extends StatelessWidget {
  final TrainingSessionModel session;
  final TrainingDrillDefinition drill;
  final DaoTrainingTier tier;

  const DrillResultScreen({
    super.key,
    required this.session,
    required this.drill,
    required this.tier,
  });

  // ✅ 7티어 구조 + labelEn 활용
  String _tierLabel(DaoTrainingTier tier) {
    // Beginner → BEGINNER 이런 느낌
    return tier.labelEn.toUpperCase();
  }

  String _commentByHitRate(double rate) {
    if (rate >= 0.8) {
      return "완벽에 가까운 스코어! 지금 감각을 그대로 가져가면 실전에서도 큰 무기입니다.";
    } else if (rate >= 0.6) {
      return "좋은 흐름이에요. 조금만 더 집중해서 성공률 80%를 노려볼까요?";
    } else if (rate >= 0.4) {
      return "기복이 있는 구간입니다. 다시 한 번 천천히 폼과 타이밍을 점검해보면 좋아요.";
    } else {
      return "조금 어려운 날이네요. 그래도 이 기록이 다음 성장의 기준이 됩니다.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final hitRatePercent = session.hitRate * 100;
    final hitRateText = hitRatePercent.toStringAsFixed(1);

    Color rateColor;
    if (hitRatePercent >= 80) {
      rateColor = Colors.cyanAccent;
    } else if (hitRatePercent >= 60) {
      rateColor = Colors.greenAccent;
    } else if (hitRatePercent >= 40) {
      rateColor = Colors.amberAccent;
    } else {
      rateColor = Colors.orangeAccent;
    }

    final extra = session.extra ?? {};
    final finishedEarly = extra['finishedEarly'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFF0D001A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.cyanAccent,
        title: const Text(
          "드릴 결과",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            // 드릴 제목 + 티어 정보
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drill.titleKo,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      drill.shortDescriptionKo,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.cyanAccent,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "DAO TIER · ${_tierLabel(tier)}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "드릴 ID: ${session.drillId}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_filled,
                          size: 16,
                          color: Colors.purpleAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${session.startedAt.toLocal().toString().substring(0, 16)} ~ "
                              "${session.endedAt.toLocal().toString().substring(0, 16)}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 성공률 / 성공 / 시도 카드
            AppCard(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            "성공률",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "$hitRateText%",
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: rateColor,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 0),
                                  blurRadius: 20,
                                  color: rateColor.withOpacity(0.8),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 70,
                      color: Colors.grey[700],
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            "성공 / 시도",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            session.successCount.toString(),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "/ ${session.totalAttempts} 다트",
                            style: TextStyle(
                              fontSize: 13,
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

            const SizedBox(height: 18),

            // 코멘트 카드
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.cyanAccent.shade100,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _commentByHitRate(session.hitRate),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (finishedEarly) ...[
              const SizedBox(height: 12),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.orangeAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "이번 세션은 계획된 라운드보다 조금 일찍 종료되었습니다.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orangeAccent.shade100,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 버튼들: 다시 하기
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => DrillRunScreen(
                            drill: drill,
                            tier: tier,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      "같은 드릴 다시하기",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 상세 기록 보기
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        TrainingSessionDetailScreen(session: session),
                  ),
                );
              },
              icon: const Icon(Icons.description_outlined),
              label: const Text(
                "상세 기록 보기",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 10),

            // 트레이닝 홈으로
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.cyanAccent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                "트레이닝 홈으로",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
