import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/constants/badge_constants.dart';

class FinishRouteRankingScreen extends StatelessWidget {
  const FinishRouteRankingScreen({super.key});

  /// ✅ 고정 컬렉션(Cloud Function이 갱신)
  static const String _currentRankingCollection = 'finish_route_rankings_current';

  double _asDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) {
      final v = double.tryParse(value);
      if (v != null) return v;
    }
    return defaultValue;
  }

  int _asInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: "피니시 루트 전체 랭킹"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  "이번 달 실시간 상위 12명",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "시간·성공률·최적 다트율·정석 루트율을 종합한 점수 기준입니다.\n"
                      "랭킹은 연습 기록 저장 시 자동 갱신됩니다.",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),

              /// ===================== 랭킹 리스트 =====================
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(_currentRankingCollection)
                      .orderBy('score', descending: true)
                      .orderBy('elapsedSeconds') // ✅ 동점이면 더 빠른 시간 우선
                      .orderBy('updatedAt', descending: true) // ✅ 완전 동률이면 최신 업데이트 우선(순서 안정화)
                      .limit(12)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "랭킹을 불러오지 못했어요.\n${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("아직 랭킹 데이터가 없어요."));
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>? ?? {};
                        final rank = index + 1;

                        final name = data['koreanName']?.toString() ?? '이름 없음';

                        final elapsedSeconds = _asInt(data['elapsedSeconds']);
                        final successRate = _asDouble(data['successRate']);
                        final avgDarts = _asDouble(data['avgDarts']);
                        final optimizationRate = _asDouble(data['optimizationRate']);

                        // ✅ 필드 혼용 대응
                        final routeMatchRate = _asDouble(
                          data['routeMatchRate'] ?? data['routeAccuracy'],
                        );

                        final score = _asDouble(data['score']);

                        final badgeKey = BadgeConstants.badgeKeyForRank(rank);

                        return ListTile(
                          leading: badgeKey != null
                              ? Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              BadgeWidget(
                                badgeKey: badgeKey,
                                size: 32,
                              ),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$rank',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          )
                              : CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey[300],
                            child: Text(
                              '$rank',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '점수 ${score.toStringAsFixed(0)} · '
                                    '시간 ${_formatTime(elapsedSeconds)} · '
                                    '평균 다트 ${avgDarts.toStringAsFixed(1)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '성공률 ${(successRate * 100).toStringAsFixed(0)}% · '
                                    '최적 ${(optimizationRate * 100).toStringAsFixed(0)}% · '
                                    '정석 ${(routeMatchRate * 100).toStringAsFixed(0)}%',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
