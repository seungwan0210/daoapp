// lib/presentation/screens/user/guestbook_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';

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
  String? _editingDocId;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendComment([String? docId]) async {
    if (_commentController.text.trim().isEmpty || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('guestbook');

      final data = {
        'writerId': currentUser.uid,
        'writerName': currentUser.displayName ?? '익명',
        'message': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': <String>[],
      };

      if (docId != null) {
        await ref.doc(docId).update(data);
        _showSnackBar('수정되었습니다', Colors.green);
      } else {
        await ref.add(data);
        _showSnackBar('방명록이 작성되었습니다', Colors.green);
      }

      _commentController.clear();
      _editingDocId = null;
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (e) {
      _showSnackBar('전송 실패: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

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

  Future<void> _toggleLike(String docId, List<dynamic> likedBy) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final newLikedBy = List<String>.from(likedBy);
    final wasLiked = newLikedBy.contains(currentUser.uid);

    if (wasLiked) {
      newLikedBy.remove(currentUser.uid);
    } else {
      newLikedBy.add(currentUser.uid);
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('guestbook')
        .doc(docId)
        .update({
      'likes': newLikedBy.length,
      'likedBy': newLikedBy,
    });
  }

  void _startEdit(String docId, String message) {
    _commentController.text = message;
    _editingDocId = docId;
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _showSnackBar(String message, Color color) {
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
                      hintText: _editingDocId != null ? '수정 중...' : '응원 메시지 남기기...',
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
                  onPressed: () => _sendComment(_editingDocId),
                  child: Icon(_editingDocId != null ? Icons.check : Icons.send, size: 18, color: Colors.white),
                ),
                if (_editingDocId != null)
                  TextButton(
                    onPressed: () {
                      _commentController.clear();
                      setState(() => _editingDocId = null);
                    },
                    child: const Text('취소'),
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
                    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                    final timeStr = timestamp != null ? AppDateUtils.formatRelativeTime(timestamp) : '방금 전';
                    final likedBy = List<String>.from(data['likedBy'] ?? []);
                    final likes = likedBy.length;
                    final isLiked = likedBy.contains(currentUser?.uid);

                    // 권한 체크
                    final isAuthor = writerId == currentUser?.uid; // 내가 쓴 글
                    final isMyGuestbook = widget.userId == currentUser?.uid; // 내 방명록
                    final isAdmin = ref.watch(isAdminProvider); // 관리자
                    final canEditDelete = isAuthor || isMyGuestbook || isAdmin;

                    return ListTile(
                      key: ValueKey(docId),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          writerName.isNotEmpty ? writerName[0] : '?',
                          style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(writerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const Spacer(),
                          Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(message, style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // 좋아요
                              GestureDetector(
                                onTap: () => _toggleLike(docId, likedBy),
                                child: Row(
                                  children: [
                                    Icon(
                                      isLiked ? Icons.favorite : Icons.favorite_border,
                                      size: 18,
                                      color: isLiked ? Colors.red : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text('$likes', style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // 수정/삭제 (내가 쓴 글 or 내 방명록 or 관리자)
                              if (canEditDelete)
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  onSelected: (v) {
                                    if (v == 'edit') _startEdit(docId, message);
                                    if (v == 'delete') _deleteComment(docId);
                                  },
                                  itemBuilder: (_) => [
                                    if (isAuthor) const PopupMenuItem(value: 'edit', child: Text('수정')),
                                    const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
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