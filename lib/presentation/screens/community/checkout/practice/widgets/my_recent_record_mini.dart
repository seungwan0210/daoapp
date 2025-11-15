// lib/presentation/screens/community/checkout/practice/widgets/my_recent_record_mini.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class MyRecentRecordMini extends StatelessWidget {
  const MyRecentRecordMini({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text("로그인 필요", style: TextStyle(color: Colors.grey));
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
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "아직 기록 없음\n지금 시작하세요!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          );
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final successRate = (data['successRate'] as num).toDouble();
        final time = data['elapsedSeconds'] as int;
        final date = (data['timestamp'] as Timestamp).toDate();

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppDateUtils.formatKoreanDate(date),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              "${_formatTime(time)} · ${(data['avgDarts'] as num).toStringAsFixed(1)}다트",
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: successRate >= 0.7 ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${(successRate * 100).toStringAsFixed(0)}%",
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, RouteConstants.checkoutMyHistory),
              child: const Text("전체 기록 보기", style: TextStyle(fontSize: 13)),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int s) => "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";
}