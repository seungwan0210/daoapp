import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/core/constants/badge_constants.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';

/// ✅ 피니시 루트 "현재 랭킹" 미니 위젯
/// - finish_route_rankings_current 컬렉션을 사용
/// - ⚠️ users/{uid} 추가 fetch는 제거(성능/실시간 안정성)
class FinishRouteRankingMini extends StatelessWidget {
  final int limit;
  const FinishRouteRankingMini({super.key, this.limit = 5});

  static const String _currentRankingCollection = 'finish_route_rankings_current';

  double _asDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  int _asInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  double _asPercent(dynamic value) {
    final v = _asDouble(value, 0.0);
    return v <= 1.0 ? v * 100 : v; // 0~1이면 퍼센트로 변환, 이미 0~100이면 그대로
  }

  String _formatTime(int s) =>
      "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(_currentRankingCollection)
          .orderBy('score', descending: true)
          .orderBy('elapsedSeconds')
          .orderBy('updatedAt', descending: true) // ✅ 동률일 때 순서 안정화
          .limit(limit)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "랭킹을 불러오지 못했어요.\n${snapshot.error}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "이번 달 랭킹 데이터 없음",
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final rank = i + 1;

            final koreanName = (data['koreanName'] ?? '이름 없음').toString();
            final badgeKey = BadgeConstants.badgeKeyForRank(rank);

            final score = _asDouble(data['score']);
            final elapsedSeconds = _asInt(data['elapsedSeconds']);
            final avgDarts = _asDouble(data['avgDarts']);

            final successRate = _asPercent(data['successRate']);
            final optimizationRate = _asPercent(data['optimizationRate']);
            final routeAccuracy =
            _asPercent(data['routeMatchRate'] ?? data['routeAccuracy']);

            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
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
              title: Text(
                koreanName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "점수 ${score.toStringAsFixed(0)} · ${_formatTime(elapsedSeconds)} · ${avgDarts.toStringAsFixed(1)}다트",
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "성공 ${successRate.toStringAsFixed(0)}% · "
                        "최적 ${optimizationRate.toStringAsFixed(0)}% · "
                        "정석 ${routeAccuracy.toStringAsFixed(0)}%",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
