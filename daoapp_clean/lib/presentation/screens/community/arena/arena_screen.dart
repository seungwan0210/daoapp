// lib/presentation/screens/community/arena/arena_screen.dart
import 'package:flutter/material.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArenaScreen extends StatelessWidget {
  const ArenaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("다음 경기", style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('events')
                      .where('date', isGreaterThan: Timestamp.now())
                      .orderBy('date')
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text("예정된 경기가 없습니다");
                    }
                    final event = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                    return Text("${event['title']} - ${event['date']}");
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("현재 Top 3", style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('totalPoints', descending: true)
                      .limit(3)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final user = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          leading: CircleAvatar(backgroundImage: NetworkImage(user['photoUrl'] ?? '')),
                          title: Text(user['koreanName'] ?? ''),
                          trailing: Text("${user['totalPoints']}점"),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}