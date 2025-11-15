// lib/presentation/screens/community/checkout/practice/checkout_ranking_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart'; // 추가
import 'package:daoapp/core/constants/badge_constants.dart';

class CheckoutRankingScreen extends StatelessWidget {
  const CheckoutRankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: "전체 랭킹"),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collectionGroup('checkout_practice').get().asStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final Map<String, Map<String, dynamic>> bestRecords = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final uid = doc.reference.parent.parent!.id;
            final time = data['elapsedSeconds'] as int;
            final successRate = (data['successRate'] as num).toDouble();
            final avgDarts = (data['avgDarts'] as num).toDouble();

            if (!bestRecords.containsKey(uid) ||
                time < bestRecords[uid]!['elapsedSeconds'] ||
                (time == bestRecords[uid]!['elapsedSeconds'] && successRate > bestRecords[uid]!['successRate'])) {
              bestRecords[uid] = {...data, 'uid': uid, 'avgDarts': avgDarts};
            }
          }

          final ranked = bestRecords.values.toList()
            ..sort((a, b) {
              final timeA = a['elapsedSeconds'] as int;
              final timeB = b['elapsedSeconds'] as int;
              if (timeA != timeB) return timeA.compareTo(timeB);
              return (b['successRate'] as num).compareTo(a['successRate'] as num);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ranked.length,
            itemBuilder: (context, i) {
              final r = ranked[i];
              final rank = i + 1;
              final badgeKey = _getMonthlyBadgeKey(rank);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(r['uid']).get(),
                builder: (context, snap) {
                  if (!snap.hasData) return const ListTile();
                  final name = snap.data!['koreanName'] ?? '이름 없음';
                  final englishName = snap.data!['englishName'] ?? '';

                  return AppCard(
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            child: Text("$rank", style: const TextStyle(fontSize: 12)),
                          ),
                          if (badgeKey != null) ...[
                            const SizedBox(width: 4),
                            BadgeWidget(badgeKey: badgeKey),
                          ],
                        ],
                      ),
                      title: Text("$name ($englishName)"),
                      subtitle: Text(
                        "시간: ${_formatTime(r['elapsedSeconds'] as int)} · "
                            "최적율: ${(r['avgDarts'] as num).toStringAsFixed(1)}다트 · "
                            "성공률: ${((r['successRate'] as num) * 100).toStringAsFixed(0)}%",
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(int s) => "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";

  String? _getMonthlyBadgeKey(int rank) {
    // 현재 월 기준 (KST)
    final now = DateTime.now().toUtc().add(const Duration(hours: 9));
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final badgeNames = [
      null,
      'pro', 'emerald', 'diamond',
      'platinum1', 'platinum2',
      'gold1', 'gold2',
      'silver1', 'silver2',
      'bronze1', 'bronze2', 'bronze3'
    ];
    final badge = badgeNames.length > rank ? badgeNames[rank] : null;
    return badge != null ? 'monthly_${year}_${month}_$badge' : null;
  }
}