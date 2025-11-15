// lib/presentation/screens/community/checkout/practice/widgets/checkout_ranking_mini.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckoutRankingMiniWidget extends StatelessWidget {
  final int limit;
  const CheckoutRankingMiniWidget({super.key, this.limit = 5});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('checkout_practice_rankings')
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
            child: Text("랭킹 데이터 없음", style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, i) {
            final doc = snapshot.data!.docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final rank = i + 1;

            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                child: Text("$rank", style: const TextStyle(fontSize: 12)),
              ),
              title: Text(data['koreanName'] ?? '이름 없음', style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                "${_formatTime(data['elapsedSeconds'])} · "
                    "${data['avgDarts'].toStringAsFixed(1)}다트 · "
                    "${(data['successRate'] * 100).toStringAsFixed(0)}%",
                style: const TextStyle(fontSize: 12),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(int s) => "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";
}