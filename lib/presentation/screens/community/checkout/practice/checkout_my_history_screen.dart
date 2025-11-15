// lib/presentation/screens/community/checkout/practice/checkout_my_history_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class CheckoutMyHistoryScreen extends StatelessWidget {
  const CheckoutMyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        appBar: CommonAppBar(title: "내 연습 기록"),
        body: Center(child: Text("로그인이 필요합니다.")),
      );
    }

    return Scaffold(
      appBar: const CommonAppBar(title: "내 연습 기록"),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('checkout_practice')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "아직 연습 기록이 없습니다.\n연습을 시작해보세요!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final doc = snapshot.data!.docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final successRate = (data['successRate'] as num).toDouble();
              final time = data['elapsedSeconds'] as int;
              final date = (data['timestamp'] as Timestamp).toDate();

              return AppCard(
                onTap: () {
                  // 결과 화면으로 이동 (PracticeSessionSummary 필요 시)
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: successRate >= 0.7 ? Colors.green : Colors.orange,
                    child: Text(
                      "${(successRate * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(AppDateUtils.formatKoreanDate(date)),
                  subtitle: Text("소요 시간: ${_formatTime(time)}"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(int s) => "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";
}