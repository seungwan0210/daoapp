// lib/presentation/screens/user/guestbook_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'widgets/guestbook_header.dart';
import 'widgets/guestbook_comment_item.dart';

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

  // === 방명록 작성 (writerName 저장 제거!) ===
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
        // 'writerName': currentUser.displayName ?? '익명',  ← 완전 삭제!
        'message': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': <String>[],
      });

      _commentController.clear();
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      _showSnackBar('방명록이 작성되었습니다', Colors.green);
    } catch (e) {
      _showSnackBar('전송 실패: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMe = currentUser?.uid == widget.userId;

    return Scaffold(
      appBar: CommonAppBar(
        title: isMe ? '내 방명록' : '방명록 쓰기',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // 상단 프로필
          GuestbookHeader(userId: widget.userId),

          const Divider(height: 1),

          // 입력창
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: '응원 메시지 남기기...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: theme.colorScheme.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isLoading
                    ? const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2))
                    : FloatingActionButton(
                  mini: true,
                  backgroundColor: theme.colorScheme.primary,
                  onPressed: _sendComment,
                  child: const Icon(Icons.send, size: 18, color: Colors.white),
                ),
              ],
            ),
          ),

          // 방명록 리스트
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('guestbook')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final comments = snapshot.data!.docs;
                if (comments.isEmpty) return const Center(child: Text('아직 방명록이 없습니다'));

                return ListView.separated(
                  key: ValueKey('guestbook_${widget.userId}'),
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                  itemBuilder: (context, i) {
                    final doc = comments[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    final writerId = data['writerId'] as String?;
                    // final writerName = data['writerName'] ?? '익명';  ← 삭제!
                    final message = data['message'] ?? '';
                    final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

                    return GuestbookCommentItem(
                      writerId: writerId ?? '',
                      // writerName: writerName,  ← 완전 삭제!
                      message: message,
                      timestamp: timestamp,
                      docId: docId,
                      guestbookOwnerId: widget.userId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}