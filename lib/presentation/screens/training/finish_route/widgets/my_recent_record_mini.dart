import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/core/utils/date_utils.dart';

class MyRecentRecordMini extends StatelessWidget {
  const MyRecentRecordMini({super.key});

  DateTime? _resolveCreatedAt(Map<String, dynamic> data) {
    final ts = (data['timestamp'] ?? data['createdAt']);
    if (ts is Timestamp) return ts.toDate();

    final ms = data['clientTimestamp'];
    if (ms is int) return DateTime.fromMillisecondsSinceEpoch(ms);

    return null;
  }

  String _formatTime(int s) =>
      "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text(
        "로그인 필요",
        style: TextStyle(color: Colors.grey, fontSize: 13),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('finish_route_practice')
      // ✅ provider 저장에는 timestamp(serverTimestamp)가 있으니 이걸로 정렬이 가장 안전
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              height: 40,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "기록을 불러오지 못했어요.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "아직 기록 없음\n지금 시작하세요!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          );
        }

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>? ?? {};

        final successRate = (data['successRate'] as num?)?.toDouble() ?? 0.0;
        final elapsedSeconds = (data['elapsedSeconds'] as num?)?.toInt() ?? 0;
        final avgDarts = (data['avgDarts'] as num?)?.toDouble() ?? 0.0;

        final date = _resolveCreatedAt(data);
        final score = (data['score'] as num?)?.toDouble();

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (date != null)
              Text(
                AppDateUtils.formatKoreanDate(date),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (date != null) const SizedBox(height: 4),
            Text(
              "${_formatTime(elapsedSeconds)} · ${avgDarts.toStringAsFixed(1)}다트",
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 6),
            if (score != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "Score ${score.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: successRate >= 0.7 ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${(successRate * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
