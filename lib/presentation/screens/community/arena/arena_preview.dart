// lib/presentation/screens/community/arena/arena_preview.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';

class ArenaPreview extends StatelessWidget {
  const ArenaPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 다음 경기
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("다음 경기", style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: () => MainScreen.changeTab(context, 2),
                      child: const Text("전체 보기"),
                    ),
                  ],
                ),
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
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("예정된 경기 없음", style: TextStyle(color: Colors.grey)),
                      );
                    }
                    final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                    final date = (data['date'] as Timestamp).toDate();
                    final formatted = '${date.month}/${date.day} ${data['time']}';
                    return ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(data['shopName']),
                      subtitle: Text(formatted),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Top 3
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("현재 Top 3", style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: () => MainScreen.changeTab(context, 1),
                      child: const Text("전체 보기"),
                    ),
                  ],
                ),
                const Divider(),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('totalPoints', descending: true)
                      .limit(3)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final user = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(user['photoUrl'] ?? ''),
                            radius: 18,
                          ),
                          title: Text(user['koreanName'] ?? ''),
                          trailing: Text("${user['totalPoints']} pt"),
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