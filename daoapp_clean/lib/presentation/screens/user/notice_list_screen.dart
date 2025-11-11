// lib/presentation/screens/user/notice_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: CommonAppBar(
        title: '공지사항',
        showBackButton: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '제목 또는 내용으로 검색',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
              ),
            ),
          ),
          Expanded(child: _buildNoticeList(theme, user?.uid)),
        ],
      ),
    );
  }

  Widget _buildNoticeList(ThemeData theme, String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notices')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('공지가 없습니다.'));
        }

        var docs = snapshot.data!.docs;
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] as String?)?.toLowerCase() ?? '';
            final content = (data['content'] as String?)?.toLowerCase() ?? '';
            return title.contains(_searchQuery) || content.contains(_searchQuery);
          }).toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final noticeId = doc.id;
            final title = data['title'] as String? ?? '제목 없음';
            final content = data['content'] as String? ?? '';
            final link = data['actionUrl'] as String?;

            return AppCard(
              margin: const EdgeInsets.only(bottom: 12),
              onTap: link != null && link.isNotEmpty
                  ? () => _handleNoticeTap(noticeId, userId, link)
                  : () => _markAsRead(noticeId, userId),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                title: Text(
                  title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: content.isNotEmpty
                    ? Text(
                  content,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
                    : null,
                trailing: link != null && link.isNotEmpty
                    ? const Icon(Icons.open_in_new, color: Colors.blue, size: 20)
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  // 읽음 처리 + 링크 열기
  Future<void> _handleNoticeTap(String noticeId, String? userId, String link) async {
    if (userId != null) {
      await _markAsRead(noticeId, userId);
    }
    await _launchURL(link);
  }

  // 읽음 처리
  Future<void> _markAsRead(String noticeId, String? userId) async {
    if (userId == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('readNotices')
        .doc(noticeId)
        .set({'readAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('링크를 열 수 없습니다.')),
      );
    }
  }
}