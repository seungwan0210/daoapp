// lib/presentation/screens/user/notice_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class NoticeListScreen extends ConsumerWidget {
  const NoticeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: CommonAppBar(title: '공지사항', showBackButton: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notices')
            .where('isActive', isEqualTo: true)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('공지가 없습니다'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final noticeId = doc.id;
              final title = data['title'] ?? '제목 없음';
              final content = data['content'] ?? '';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: timestamp != null
                      ? Text(AppDateUtils.formatRelativeTime(timestamp), style: const TextStyle(fontSize: 12, color: Colors.grey))
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    if (user != null) {
                      // 읽음 기록 저장
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('readNotices')
                          .doc(noticeId)
                          .set({'timestamp': FieldValue.serverTimestamp()});
                    }
                    // 상세 보기
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(title),
                        content: SingleChildScrollView(child: Text(content)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기')),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}