// lib/presentation/screens/community/checkout/practice/checkout_ranking_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/constants/badge_constants.dart';
import 'package:daoapp/core/utils/badge_utils.dart'; // 추가

class CheckoutRankingScreen extends StatelessWidget {
  const CheckoutRankingScreen({super.key});

  String _getMonthlyRankingCollection() {
    final nowKst = DateTime.now().toUtc().add(const Duration(hours: 9));
    final year = nowKst.year;
    final month = nowKst.month.toString().padLeft(2, '0');
    return 'checkout_practice_rankings_${year}_$month';
  }

  double _asDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    final collectionName = _getMonthlyRankingCollection();

    return Scaffold(
      appBar: const CommonAppBar(title: "체크아웃 전체 랭킹"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text("이번 달 실시간 상위 12명", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "시간·성공률·최적다트율·정석루트율을 종합한 점수 기준입니다.\n"
                      "1~12위 배지는 전월 기록 기준으로 매월 1일 새벽에 자동 갱신됩니다.",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(collectionName)
                      .orderBy('score', descending: true)
                      .orderBy('elapsedSeconds')
                      .limit(12)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("아직 랭킹 데이터가 없어요."));
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>? ?? {};
                        final rank = index + 1;
                        final uid = data['uid'] as String?;
                        final name = data['koreanName']?.toString() ?? '이름 없음';

                        final elapsedSeconds = _asDouble(data['elapsedSeconds']);
                        final successRate = _asDouble(data['successRate']);
                        final avgDarts = _asDouble(data['avgDarts']);
                        final optimizationRate = _asDouble(data['optimizationRate']);
                        final routeAccuracy = _asDouble(data['routeAccuracy']);
                        final score = _asDouble(data['score']);

                        final badgeKey = BadgeConstants.badgeKeyForRank(rank);

                        return ListTile(
                          leading: badgeKey != null
                              ? Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              BadgeWidget(badgeKey: badgeKey, size: 32),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                                child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                              : CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey[300],
                            child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // 배지 (이름 옆)
                              if (uid != null)
                                FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) return const SizedBox.shrink();
                                    final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                                    final badgesMap = BadgeUtils.extractBadges(userData);
                                    final monthly = BadgeUtils.getLatestMonthlyBadge(badgesMap);
                                    final admin = BadgeUtils.getLatestAdminBadge(badgesMap);
                                    final badges = <String>[];
                                    if (monthly != null) badges.add(monthly);
                                    if (admin != null) badges.add(admin);

                                    return Wrap(
                                      spacing: 2,
                                      children: badges.map((key) => Tooltip(
                                        message: BadgeUtils.getBadgeTooltip(key),
                                        child: BadgeWidget(badgeKey: key, size: 18),
                                      )).toList(),
                                    );
                                  },
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '점수: ${score.toStringAsFixed(1)}  ·  시간: ${elapsedSeconds.toStringAsFixed(1)}초  ·  평균 다트: ${avgDarts.toStringAsFixed(1)}개',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '성공률: ${(successRate * 100).toStringAsFixed(0)}%  ·  최적 다트율: ${(optimizationRate * 100).toStringAsFixed(0)}%  ·  정석 루트율: ${(routeAccuracy * 100).toStringAsFixed(0)}%',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
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