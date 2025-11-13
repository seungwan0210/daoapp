// lib/presentation/screens/community/circle/widgets/comment_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/user_profile_dialog.dart';

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

  // === 댓글 작성 ===
  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length > 300) return;

    final user = FirebaseAuth.instance.currentUser!;
    final commentRef = FirebaseFirestore.instance
        .collection('community')
        .doc(widget.postId)
        .collection('comments')
        .doc();

    await commentRef.set({
      'userId': user.uid,
      'displayName': user.displayName ?? '익명',
      'content': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 댓글 수 증가
    await FirebaseFirestore.instance
        .collection('community')
        .doc(widget.postId)
        .update({'comments': FieldValue.increment(1)});

    _controller.clear();
    FocusScope.of(context).unfocus();

    // 최신 댓글이 위로 오도록 스크롤
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // === 댓글 삭제 ===
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
              child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('community')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      await FirebaseFirestore.instance
          .collection('community')
          .doc(widget.postId)
          .update({'comments': FieldValue.increment(-1)});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 삭제되었습니다'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 테마 사용
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isAdmin = ref.watch(isAdminProvider).when(data: (v) => v, loading: () => false, error: (_, __) => false);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // 핸들바
        Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('댓글', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        const Divider(height: 1),

        // === 댓글 리스트 ===
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('community')
                .doc(widget.postId)
                .collection('comments')
                .orderBy('timestamp', descending: true) // 최신순
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('아직 댓글이 없습니다'));

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final commentId = doc.id;
                  final userId = data['userId'] as String?;
                  final displayName = data['displayName'] as String? ?? '익명';
                  final content = data['content'] as String? ?? '';
                  final timestamp = data['timestamp'] as Timestamp?;
                  final timeStr = timestamp != null ? AppDateUtils.formatRelativeTime(timestamp.toDate()) : '방금 전';

                  final isMyComment = userId == currentUserId;
                  final canDelete = isMyComment || isAdmin;
                  final isLong = content.length > 80 || content.contains('\n');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 아바타 클릭 → 프로필
                        GestureDetector(
                          onTap: userId != null ? () => _showProfile(userId) : null,
                          child: _buildAvatar(userId),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 이름 클릭 → 프로필
                              GestureDetector(
                                onTap: userId != null ? () => _showProfile(userId) : null,
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              // 긴 댓글 → 더보기
                              GestureDetector(
                                onTap: isLong ? () => _showFullComment(displayName, content) : null,
                                child: Text(
                                  content,
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  maxLines: isLong ? 2 : null,
                                  overflow: isLong ? TextOverflow.ellipsis : null,
                                ),
                              ),
                              if (isLong)
                                TextButton(
                                  onPressed: () => _showFullComment(displayName, content),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    '더보기',
                                    style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                                  ),
                                ),
                              Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        // 삭제 버튼
                        if (canDelete)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz, size: 16),
                            onSelected: (v) => _deleteComment(commentId),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('삭제', style: TextStyle(color: Colors.red))),
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

        // === 입력창 ===
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: '댓글을 입력하세요...',
                    border: InputBorder.none,
                    counterText: '',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
              GestureDetector(
                onTap: _sendComment,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.send, color: theme.colorScheme.primary, size: 24),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // === 아바타 ===
  Widget _buildAvatar(String? userId) {
    if (userId == null) return const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 20));
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          photoUrl = snapshot.data!['profileImageUrl'] as String?;
        }
        return CircleAvatar(
          radius: 16,
          backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
          child: photoUrl?.isNotEmpty != true ? const Icon(Icons.person, size: 20, color: Colors.grey) : null,
        );
      },
    );
  }

  // === 프로필 다이얼로그 (완전 구현!) ===
  void _showProfile(String userId) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = currentUid == userId;

    showDialog(
      context: context,
      builder: (_) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          if (!snapshot.data!.exists || snapshot.data!.data() == null) {
            return UserProfileDialog(koreanName: '프로필 없음', isMe: isMe, userId: userId);
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final hasProfile = data['hasProfile'] == true;
          if (!hasProfile) {
            return UserProfileDialog(koreanName: '프로필 미완료', isMe: isMe, userId: userId);
          }

          final koreanName = data['koreanName']?.toString().trim() ?? '이름 없음';
          final englishName = data['englishName']?.toString().trim();
          final photoUrl = data['profileImageUrl'] as String?;
          final shopName = data['shopName']?.toString().trim();

          final barrelName = data['barrelName']?.toString().trim() ?? '';
          final shaft = data['shaft']?.toString().trim() ?? '';
          final flight = data['flight']?.toString().trim() ?? '';
          final tip = data['tip']?.toString().trim() ?? '';
          final barrelImageUrl = data['barrelImageUrl'] as String?;

          final hasBarrelInfo = barrelName.isNotEmpty ||
              shaft.isNotEmpty ||
              flight.isNotEmpty ||
              tip.isNotEmpty ||
              (barrelImageUrl?.isNotEmpty == true);

          return UserProfileDialog(
            koreanName: koreanName,
            englishName: englishName,
            photoUrl: photoUrl,
            shopName: shopName,
            barrelData: hasBarrelInfo
                ? {
              'barrelImageUrl': barrelImageUrl,
              'barrelName': barrelName,
              'shaft': shaft,
              'flight': flight,
              'tip': tip,
            }
                : null,
            isMe: isMe,
            userId: userId,
          );
        },
      ),
    );
  }

  // === 긴 댓글 전체 보기 ===
  void _showFullComment(String name, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기'))
        ],
      ),
    );
  }
}