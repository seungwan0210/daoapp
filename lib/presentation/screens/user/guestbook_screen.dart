// lib/presentation/screens/user/guestbook_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart'; // 추가!

class GuestbookScreen extends ConsumerStatefulWidget {
  final String userId;
  const GuestbookScreen({super.key, required this.userId});

  @override
  ConsumerState<GuestbookScreen> createState() => _GuestbookScreenState();
}

class _GuestbookScreenState extends ConsumerState<GuestbookScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('guestbook')
          .add({
        'writerId': currentUser.uid,
        'writerName': currentUser.displayName ?? '익명',
        'message': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('전송 실패: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      // 통일된 AppBar
      appBar: CommonAppBar(
        title: '방명록',
        showBackButton: true,
      ),
      body: CustomScrollView(
        slivers: [
          // 프로필 + 배럴 정보
          SliverToBoxAdapter(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 120);
                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final profileImageUrl = data['profileImageUrl'] as String?;
                final barrelImageUrl = data['barrelImageUrl'] as String?;
                final koreanName = data['koreanName'] ?? '이름 없음';
                final shopName = data['shopName'] ?? '';
                final barrelName = data['barrelName'] ?? '';
                final email = data['email'] ?? '이메일 없음';

                return AppCard(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : null,
                              child: profileImageUrl == null || profileImageUrl.isEmpty
                                  ? const Icon(Icons.account_circle, size: 44, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          koreanName,
                                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (shopName.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '· $shopName',
                                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(email, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: barrelImageUrl != null && barrelImageUrl.isNotEmpty
                                    ? Image.network(barrelImageUrl, fit: BoxFit.cover)
                                    : const Icon(Icons.sports_esports, size: 30, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (barrelName.isNotEmpty)
                                    Text(
                                      barrelName,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 제목
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Text(
                '내 방명록 보기',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: Divider(height: 1)),

          // 댓글 리스트
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .collection('guestbook')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              final comments = snapshot.data!.docs;

              if (comments.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text('아직 댓글이 없어요')));
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) {
                      final data = comments[i].data() as Map<String, dynamic>;
                      final timestamp = data['timestamp'] as Timestamp?;
                      final timeStr = timestamp != null ? AppDateUtils.formatRelativeTime(timestamp.toDate()) : '방금 전';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              child: Text(
                                data['writerName']?[0] ?? '?',
                                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              data['writerName'] ?? '익명',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(data['message'] ?? ''),
                            trailing: Text(
                              timeStr,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: comments.length,
                  ),
                ),
              );
            },
          ),

          // 입력창 (본인 제외)
          if (currentUser != null && currentUser.uid != widget.userId)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: '응원 메시지 남기기...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : ElevatedButton(
                      onPressed: _sendComment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}