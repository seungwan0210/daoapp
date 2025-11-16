// lib/presentation/screens/community/checkout/practice/widgets/checkout_ranking_mini.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/constants/badge_constants.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/utils/badge_utils.dart'; // 추가

class CheckoutRankingMiniWidget extends StatelessWidget {
  final int limit;
  const CheckoutRankingMiniWidget({super.key, this.limit = 5});

  String _currentMonthlyCollection() {
    final nowKst = DateTime.now().toUtc().add(const Duration(hours: 9));
    final year = nowKst.year;
    final month = nowKst.month.toString().padLeft(2, '0');
    return 'checkout_practice_rankings_${year}_${month}';
  }

  /// 다양한 타입(double/int/num/String)을 안전하게 double로 변환
  double _asDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) {
      final v = double.tryParse(value);
      if (v != null) return v;
    }
    return defaultValue;
  }

  /// 0.0~1.0 또는 0~100 둘 다 대응
  double _asPercent(dynamic value) {
    final v = _asDouble(value, 0.0);
    if (v <= 1.0) {
      // 0.2 → 20%
      return v * 100;
    } else {
      // 이미 퍼센트 값(20)으로 저장된 경우
      return v;
    }
  }

  @override
  Widget build(BuildContext context) {
    final collectionName = _currentMonthlyCollection();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collectionName)
          .orderBy('score', descending: true)
          .orderBy('elapsedSeconds')
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

            // 랭킹 컬렉션에 저장된 기본 값 (fallback용)
            final fallbackElapsedSeconds =
            _asDouble(data['elapsedSeconds']).toInt();
            final fallbackAvgDarts = _asDouble(data['avgDarts']);
            final fallbackSuccessRate = data['successRate'];
            final fallbackOptimizationRate = data['optimizationRate'];
            final fallbackRouteAccuracy = data['routeAccuracy'];
            final score = _asDouble(data['score']);

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
                child: Text(
                  "$rank",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      koreanName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 배지 (이름 옆)
                  if (uid != null)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>? ??
                                {};
                        final badgesMap = BadgeUtils.extractBadges(userData);
                        final monthly =
                        BadgeUtils.getLatestMonthlyBadge(badgesMap);
                        final admin =
                        BadgeUtils.getLatestAdminBadge(badgesMap);
                        final badges = <String>[];
                        if (monthly != null) badges.add(monthly);
                        if (admin != null) badges.add(admin);

                        return Wrap(
                          spacing: 2,
                          children: badges
                              .map(
                                (key) => Tooltip(
                              message: BadgeUtils.getBadgeTooltip(key),
                              child: BadgeWidget(
                                badgeKey: key,
                                size: 16,
                              ),
                            ),
                          )
                              .toList(),
                        );
                      },
                    ),
                ],
              ),
              subtitle: uid == null
              // uid 없으면 그냥 기존 랭킹 값으로 표시
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "점수 ${score.toStringAsFixed(1)} · ${_formatTime(fallbackElapsedSeconds)} · ${fallbackAvgDarts.toStringAsFixed(1)}다트",
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black87),
                  ),
                  Text(
                    "성공 ${_asPercent(fallbackSuccessRate).toStringAsFixed(0)}% · "
                        "최적 ${_asPercent(fallbackOptimizationRate).toStringAsFixed(0)}% · "
                        "정석 ${_asPercent(fallbackRouteAccuracy).toStringAsFixed(0)}%",
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                ],
              )
              // ✅ uid 있으면: 해당 유저의 "마지막 기록"을 다시 읽어서 표시 (내 기록과 동일 기준)
                  : FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('checkout_practice')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .get(),
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    // 최근 기록이 없으면 fallback 사용
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "점수 ${score.toStringAsFixed(1)} · ${_formatTime(fallbackElapsedSeconds)} · ${fallbackAvgDarts.toStringAsFixed(1)}다트",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black87),
                        ),
                        Text(
                          "성공 ${_asPercent(fallbackSuccessRate).toStringAsFixed(0)}% · "
                              "최적 ${_asPercent(fallbackOptimizationRate).toStringAsFixed(0)}% · "
                              "정석 ${_asPercent(fallbackRouteAccuracy).toStringAsFixed(0)}%",
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    );
                  }

                  final lastData = snap.data!.docs.first.data()
                  as Map<String, dynamic>? ??
                      {};

                  final elapsedSeconds =
                  _asDouble(lastData['elapsedSeconds'],
                      fallbackElapsedSeconds.toDouble())
                      .toInt();
                  final avgDarts =
                  _asDouble(lastData['avgDarts'], fallbackAvgDarts);
                  final successRate = lastData['successRate'] ??
                      fallbackSuccessRate;
                  final optimizationRate =
                      lastData['optimizationRate'] ??
                          fallbackOptimizationRate;
                  final routeAccuracy =
                      lastData['routeAccuracy'] ?? fallbackRouteAccuracy;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "점수 ${score.toStringAsFixed(1)} · ${_formatTime(elapsedSeconds)} · ${avgDarts.toStringAsFixed(1)}다트",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87),
                      ),
                      Text(
                        "성공 ${_asPercent(successRate).toStringAsFixed(0)}% · "
                            "최적 ${_asPercent(optimizationRate).toStringAsFixed(0)}% · "
                            "정석 ${_asPercent(routeAccuracy).toStringAsFixed(0)}%",
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(int s) =>
      "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";
}
