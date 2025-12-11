// lib/presentation/screens/training/finish_route/finish_route_my_history_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'finish_route_detail_screen.dart';

class FinishRouteMyHistoryScreen extends StatelessWidget {
  const FinishRouteMyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다.')),
      );
    }

    // ✅ 실제 기록 저장 위치는 그대로 사용: users/{uid}/checkout_practice
    final historyRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('checkout_practice');

    return Scaffold(
      appBar: const CommonAppBar(title: '내 피니쉬 루트 연습 기록'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          child: StreamBuilder<QuerySnapshot>(
            stream: historyRef
                .orderBy('timestamp', descending: true) // ✅ 최신순
                .limit(10) // ✅ 최근 10개만
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    '아직 저장된 피니쉬 루트 연습 기록이 없어요.\n먼저 피니쉬 루트 연습을 해보세요!',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>? ?? {};

                  // ✅ timestamp / createdAt 둘 다 대응
                  final ts =
                  (data['timestamp'] ?? data['createdAt']) as Timestamp?;
                  final createdAt = ts?.toDate();

                  final elapsed =
                      (data['elapsedSeconds'] as num?)?.toDouble() ?? 0.0;

                  // successRate 는 0~1 로 저장되어 있음
                  final successRate =
                      (data['successRate'] as num?)?.toDouble() ?? 0.0;

                  final avgDarts =
                      (data['avgDarts'] as num?)?.toDouble() ?? 0.0;

                  // 새 구조: problemCount
                  // 옛 구조: totalAttempts
                  final totalAttempts =
                      (data['problemCount'] as num?)?.toInt() ??
                          (data['totalAttempts'] as num?)?.toInt() ??
                          0;

                  // 새 구조에선 successCount 가 없으니,
                  // 있으면 쓰고, 없으면 successRate * totalAttempts 로 근사
                  int successCount =
                      (data['successCount'] as num?)?.toInt() ?? 0;
                  if (successCount == 0 && totalAttempts > 0) {
                    successCount =
                        (successRate * totalAttempts).round();
                  }

                  String dateText = '날짜 없음';
                  if (createdAt != null) {
                    dateText =
                    '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')} '
                        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
                  }

                  return ListTile(
                    title: Text(
                      dateText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '시간: ${elapsed.toStringAsFixed(1)}초 · '
                          '다트: ${avgDarts.toStringAsFixed(1)}개 · '
                          '성공률: ${(successRate * 100).toStringAsFixed(0)}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$successCount / $totalAttempts',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '성공 / 시도',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FinishRouteDetailScreen(
                            recordId: doc.id,
                            data: data,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
