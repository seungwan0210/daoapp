// lib/presentation/screens/community/checkout/practice/widgets/checkout_ranking_mini.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/constants/badge_constants.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/utils/badge_utils.dart';

class CheckoutRankingMiniWidget extends StatelessWidget {
  final int limit;
  const CheckoutRankingMiniWidget({super.key, this.limit = 5});

  String _currentMonthlyCollection() {
    final nowKst = DateTime.now().toUtc().add(const Duration(hours: 9));
    final year = nowKst.year;
    final month = nowKst.month.toString().padLeft(2, '0');
    return 'checkout_practice_rankings_${year}_${month}';
  }

  double _asDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) {
      final v = double.tryParse(value);
      if (v != null) return v;
    }
    return defaultValue;
  }

  double _asPercent(dynamic value) {
    final v = _asDouble(value, 0.0);
    return v <= 1.0 ? v * 100 : v;
  }

  String _formatTime(int s) =>
      "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final collectionName = _currentMonthlyCollection();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collectionName)
          .orderBy('score', descending: true)
          .limit(limit)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "이번 달 랭킹 데이터 없음",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final rank = i + 1;
            final uid = data['uid'] as String?;
            final koreanName = (data['koreanName'] ?? '이름 없음').toString();
            final badgeKey = BadgeConstants.badgeKeyForRank(rank);

            // 랭킹 컬렉션 데이터만 사용 → 최고 점수 세션의 정확한 모든 정보!
            final score = _asDouble(data['score']);
            final elapsedSeconds = _asDouble(data['elapsedSeconds']).toInt();
            final avgDarts = _asDouble(data['avgDarts']);
            final successRate = data['successRate'];
            final optimizationRate = data['optimizationRate'];
            final routeAccuracy = data['routeMatchRate'] ?? data['routeAccuracy'];

            return ListTile(
              dense: true,
              leading: badgeKey != null
                  ? Stack(
                alignment: Alignment.bottomRight,
                children: [
                  BadgeWidget(badgeKey: badgeKey, size: 28),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
                  : CircleAvatar(
                radius: 14,
                child: Text("$rank", style: const TextStyle(fontSize: 12)),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      koreanName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 배지 표시
                  if (uid != null)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) return const SizedBox.shrink();
                        final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                        final badgesMap = BadgeUtils.extractBadges(userData);
                        final monthly = BadgeUtils.getLatestMonthlyBadge(badgesMap);
                        final admin = BadgeUtils.getLatestAdminBadge(badgesMap);
                        final badges = <String>[];
                        if (monthly != null) badges.add(monthly);
                        if (admin != null) badges.add(admin);

                        return Wrap(
                          spacing: 2,
                          children: badges
                              .map((key) => Tooltip(
                            message: BadgeUtils.getBadgeTooltip(key),
                            child: BadgeWidget(badgeKey: key, size: 16),
                          ))
                              .toList(),
                        );
                      },
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "점수 ${score.toStringAsFixed(1)} · ${_formatTime(elapsedSeconds)} · ${avgDarts.toStringAsFixed(1)}다트",
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  Text(
                    "성공 ${_asPercent(successRate).toStringAsFixed(0)}% · "
                        "최적 ${_asPercent(optimizationRate).toStringAsFixed(0)}% · "
                        "정석 ${_asPercent(routeAccuracy).toStringAsFixed(0)}%",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}