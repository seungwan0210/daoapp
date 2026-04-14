import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

// ✅ 실제 파일명에 맞춰 import 수정
import 'finish_route_detail_screen.dart';

class FinishRouteMyHistoryScreen extends StatelessWidget {
  const FinishRouteMyHistoryScreen({super.key});

  DateTime? _resolveCreatedAt(Map<String, dynamic> data) {
    // 1) serverTimestamp (Timestamp)
    final ts = (data['timestamp'] ?? data['createdAt']);
    if (ts is Timestamp) return ts.toDate();

    // 2) clientTimestamp (int ms)
    final ms = data['clientTimestamp'];
    if (ms is int) return DateTime.fromMillisecondsSinceEpoch(ms);

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다.')),
      );
    }

    final historyRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('finish_route_practice');

    return Scaffold(
      appBar: const CommonAppBar(title: '내 피니시 루트 연습 기록'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          child: StreamBuilder<QuerySnapshot>(
            stream: historyRef
            // ✅ 가장 안정적인 정렬: timestamp(서버) → clientTimestamp(로컬 백업)
            // - timestamp가 없거나 null인 데이터가 섞여도 최대한 안정적
                .orderBy('timestamp', descending: true)
                .orderBy('clientTimestamp', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    '아직 저장된 연습 기록이 없어요.\n피니시 루트 연습을 먼저 해보세요!',
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

                  final createdAt = _resolveCreatedAt(data);

                  final elapsed =
                      (data['elapsedSeconds'] as num?)?.toDouble() ?? 0.0;
                  final successRate =
                      (data['successRate'] as num?)?.toDouble() ?? 0.0;
                  final avgDarts =
                      (data['avgDarts'] as num?)?.toDouble() ?? 0.0;

                  final totalAttempts =
                      (data['problemCount'] as num?)?.toInt() ??
                          (data['totalAttempts'] as num?)?.toInt() ??
                          0;

                  int successCount =
                      (data['successCount'] as num?)?.toInt() ?? 0;
                  if (successCount == 0 && totalAttempts > 0) {
                    successCount = (successRate * totalAttempts).round();
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FinishRoutePracticeDetailScreen(
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
