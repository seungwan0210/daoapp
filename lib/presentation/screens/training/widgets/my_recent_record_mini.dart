// lib/presentation/screens/community/checkout/practice/widgets/my_recent_record_mini.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/core/utils/date_utils.dart';

class MyRecentRecordMini extends StatelessWidget {
  const MyRecentRecordMini({super.key});

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
          .collection('checkout_practice')
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
        final timestamp = data['timestamp'] as Timestamp?;
        final date = timestamp?.toDate();

        // 앞으로 score 필드를 쓰게 될 때를 대비 (없으면 null)
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
            // 점수 표시 (있을 경우만)
            if (score != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[800],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "Score ${score.toStringAsFixed(1)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  String _formatTime(int s) =>
      "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";
}
