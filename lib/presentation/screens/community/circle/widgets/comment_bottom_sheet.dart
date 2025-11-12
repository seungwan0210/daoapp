// lib/presentation/screens/community/circle/widgets/comment_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';

class CommentBottomSheet extends ConsumerStatefulWidget {
  final String postId;
  const CommentBottomSheet({super.key, required this.postId});

  static void show(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentBottomSheet(postId: postId),
    );
  }

  @override
  ConsumerState<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends ConsumerState<CommentBottomSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;
    final batch = FirebaseFirestore.instance.batch();

    final commentRef = FirebaseFirestore.instance
        .collection('community')
        .doc(widget.postId)
        .collection('comments')
        .doc();

    batch.set(commentRef, {
      'userId': user.uid,
      'displayName': user.displayName ?? 'Unknown',
      'content': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    batch.update(FirebaseFirestore.instance.collection('community').doc(widget.postId), {
      'comments': FieldValue.increment(1),
    });

    await batch.commit();
    _controller.clear();
  }

  void _showEditDialog(String commentId, String currentContent) {
    final editController = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('댓글 수정'),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: '수정할 내용을 입력하세요'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('community')
                  .doc(widget.postId)
                  .collection('comments')
                  .doc(commentId)
                  .update({'content': newText});

              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final batch = FirebaseFirestore.instance.batch();
    batch.delete(FirebaseFirestore.instance
        .collection('community')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId));
    batch.update(FirebaseFirestore.instance.collection('community').doc(widget.postId), {
      'comments': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isAdminAsync = ref.watch(isAdminProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('댓글', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const Divider(height: 1),
        Flexible(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('community')
                .doc(widget.postId)
                .collection('comments')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final comments = snapshot.data!.docs;
              if (comments.isEmpty) {
                return const Center(child: Text('아직 댓글이 없습니다'));
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: comments.length,
                itemBuilder: (context, i) {
                  final doc = comments[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final commentId = doc.id;
                  final commentUserId = data['userId'] as String?;
                  final displayName = data['displayName'] ?? 'Unknown';
                  final content = data['content'] ?? '';
                  final timestamp = data['timestamp'] as Timestamp?;
                  final timeStr = timestamp != null ? AppDateUtils.formatRelativeTime(timestamp.toDate()) : '방금 전';

                  final isMyComment = commentUserId == currentUserId;
                  final isAdmin = isAdminAsync.when(data: (v) => v, loading: () => false, error: (_, __) => false);
                  final canEditDelete = isMyComment || isAdmin;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[300],
                          child: Text(displayName.isNotEmpty ? displayName[0] : '?'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  if (canEditDelete) ...[
                                    const Spacer(),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_horiz, size: 16),
                                      onSelected: (v) async {
                                        if (v == 'edit' && isMyComment) {
                                          _showEditDialog(commentId, content);
                                        } else if (v == 'delete') {
                                          await _deleteComment(commentId);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        if (isMyComment) const PopupMenuItem(value: 'edit', child: Text('수정')),
                                        const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(content, style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        // 입력창
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: '댓글을 입력하세요...', border: InputBorder.none),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendComment(),
              ),
            ),
            GestureDetector(
              onTap: _sendComment,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.send, color: Colors.blue, size: 24),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}