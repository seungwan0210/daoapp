import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';

class NoticeListScreen extends ConsumerStatefulWidget {
  const NoticeListScreen({super.key});

  @override
  ConsumerState<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends ConsumerState<NoticeListScreen> {
  // 읽음 여부 캐시 (성능 향상)
  final Map<String, bool> _readStatusCache = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '공지사항', showBackButton: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notices')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          print('공지사항 문서 수: ${docs.length}');

          if (docs.isEmpty) {
            return const Center(child: Text('공지가 없습니다'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id;

              final title = data['title'] ?? '제목 없음';
              final content = data['content'] ?? '';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ??
                  (data['createdAt'] as Timestamp?)?.toDate();

              // 읽음 여부 확인 (캐시 사용)
              final isUnread = _isUnread(docId);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  // 안 읽은 공지는 파란 점
                  leading: isUnread
                      ? Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  )
                      : null,
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      color: isUnread ? Colors.black : Colors.grey[600],
                    ),
                  ),
                  subtitle: timestamp != null
                      ? Text(
                    AppDateUtils.formatRelativeTime(timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnread ? Colors.grey[700] : Colors.grey[500],
                    ),
                  )
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final user = FirebaseAuth.instance.currentUser;

                    // 로그인된 사용자만 읽음 기록 저장
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('readNotices')
                          .doc(docId)
                          .set({'timestamp': FieldValue.serverTimestamp()});

                      // 캐시 갱신 + 배지 리프레시
                      setState(() => _readStatusCache[docId] = false);
                      ref.invalidate(unreadNoticesCountProvider);
                    }

                    // 누구나 다이얼로그
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

  // 읽음 여부 확인 (캐시 + 비로그인 처리)
  bool _isUnread(String docId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return true; // 비로그인 → 항상 안 읽음

    // 캐시 확인
    if (_readStatusCache.containsKey(docId)) {
      return !_readStatusCache[docId]!;
    }

    // 초기값 (기본값: 안 읽음)
    _readStatusCache[docId] = true;

    // 비동기로 실제 읽음 여부 확인
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('readNotices')
        .doc(docId)
        .get()
        .then((readDoc) {
      if (mounted) {
        setState(() {
          _readStatusCache[docId] = readDoc.exists;
        });
      }
    });

    return true; // 초기값
  }
}