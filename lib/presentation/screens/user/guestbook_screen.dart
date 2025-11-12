import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/post_item_widget.dart';

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

  // 새 댓글 작성
  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('guestbook');

      await ref.add({
        'writerId': currentUser.uid,
        'writerName': currentUser.displayName ?? '익명',
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

  // 삭제
  Future<void> _deleteComment(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('삭제 확인'),
        content: const Text('이 방명록을 삭제하시겠습니까?\n복구 불가합니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('guestbook')
          .doc(docId)
          .delete();
      _showSnackBar('삭제되었습니다', Colors.green);
    } catch (e) {
      _showSnackBar('삭제 실패: $e', Colors.red);
    }
  }

  // 수정 다이얼로그
  void _startEdit(String docId, String currentMessage) {
    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: currentMessage);
        return AlertDialog(
          title: const Text('방명록 수정'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: '메시지를 입력하세요',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newMessage = controller.text.trim();
                if (newMessage.isNotEmpty) {
                  await _updateComment(docId, newMessage);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('수정'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateComment(String docId, String message) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('guestbook')
          .doc(docId)
          .update({
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _showSnackBar('수정되었습니다', Colors.green);
    } catch (e) {
      _showSnackBar('수정 실패: $e', Colors.red);
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
          // 프로필
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox(height: 80);
              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              final profileImageUrl = data['profileImageUrl'] as String?;
              final koreanName = data['koreanName'] ?? '이름 없음';
              final shopName = data['shopName'] ?? '';

              return Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: profileImageUrl?.isNotEmpty == true
                          ? NetworkImage(profileImageUrl!)
                          : null,
                      child: profileImageUrl?.isNotEmpty != true
                          ? const Icon(Icons.person, size: 36, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(koreanName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          if (shopName.isNotEmpty)
                            Text('· $shopName', style: TextStyle(color: theme.colorScheme.primary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

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
                    final writerName = data['writerName'] ?? '익명';
                    final message = data['message'] ?? '';
                    final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

                    final currentUser = FirebaseAuth.instance.currentUser;
                    final isAuthor = writerId == currentUser?.uid;
                    final isMyGuestbook = widget.userId == currentUser?.uid;
                    final isAdmin = ref.watch(isAdminProvider).when(
                      data: (v) => v,
                      loading: () => false,
                      error: (_, __) => false,
                    );
                    final canEdit = isAuthor;
                    final canDelete = isAuthor || isMyGuestbook || isAdmin;

                    return PostItemWidget(
                      title: writerName,
                      content: message,
                      authorName: writerName,
                      timestamp: timestamp,
                      postId: docId,
                      collectionPath: 'users/${widget.userId}/guestbook',
                      authorId: writerId ?? '',
                      onEdit: canEdit ? () => _startEdit(docId, message) : null,
                      onDelete: canDelete ? () => _deleteComment(docId) : null,
                      onTap: null,
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