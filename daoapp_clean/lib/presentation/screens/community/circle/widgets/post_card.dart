// lib/presentation/screens/community/circle/widgets/post_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/like_button.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/comment_button.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/comment_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:daoapp/core/utils/date_utils.dart';

class PostCard extends ConsumerWidget {
  final QueryDocumentSnapshot doc;
  final String? currentUserId;
  final void Function(double)? onHeightCalculated; // 동적 높이 콜백
  late final GlobalKey cardKey;

  PostCard({
    super.key,
    required this.doc,
    this.currentUserId,
    this.onHeightCalculated,
  }) : cardKey = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = doc.data() as Map<String, dynamic>;
    final postId = doc.id;
    final photoUrl = data['photoUrl'] as String?;
    if (photoUrl == null) return const SizedBox.shrink();

    final displayName = data['displayName'] ?? 'Unknown';
    final content = data['content'] ?? '';
    final likes = data['likes'] as int? ?? 0;
    final comments = data['comments'] as int? ?? 0;
    final userPhotoUrl = data['userPhotoUrl'] as String?;
    final postUserId = data['userId'] as String?;
    final timestamp = data['timestamp'] as Timestamp?;

    final isAuthor = postUserId == currentUserId;
    final isAdmin = ref.watch(isAdminProvider);
    final canEditDelete = isAuthor || isAdmin;

    void sharePost() {
      Share.share('$content\n$photoUrl', subject: 'DAO 앱에서 공유');
    }

    void _showFullContent() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              CircleAvatar(radius: 14, backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null),
              const SizedBox(width: 8),
              Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(content, style: const TextStyle(fontSize: 14)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('닫기', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      );
    }

    // 높이 측정 후 콜백
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? box = cardKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && onHeightCalculated != null) {
        onHeightCalculated!(box.size.height);
      }
    });

    return Container(
      key: cardKey,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 + 시간 + 더보기 아이콘
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null,
                  child: userPhotoUrl == null ? const Icon(Icons.person, size: 20, color: Colors.grey) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (timestamp != null)
                        Text(
                          AppDateUtils.formatRelativeTime(timestamp.toDate()),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                if (canEditDelete)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 22, color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (v) async {
                      if (v == 'edit') {
                        Navigator.pushNamed(context, RouteConstants.postWrite, arguments: {'postId': postId});
                      } else if (v == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('삭제 확인'),
                            content: const Text('이 게시물을 삭제하시겠습니까?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('삭제', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await FirebaseFirestore.instance.collection('community').doc(postId).delete();
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      if (isAuthor) const PopupMenuItem(value: 'edit', child: Text('수정')),
                      const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(color: Colors.red))),
                    ],
                  ),
              ],
            ),
          ),

          // 사진
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(photoUrl, width: double.infinity, height: 300, fit: BoxFit.cover),
          ),

          // 액션바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                LikeButton(postId: postId, currentUserId: currentUserId),
                const SizedBox(width: 16),
                CommentButton(postId: postId, commentsCount: comments),
                const SizedBox(width: 16),
                IconButton(icon: const Icon(Icons.send_outlined, size: 24), onPressed: sharePost),
                const Spacer(),
                const Icon(Icons.bookmark_border, size: 24),
              ],
            ),
          ),

          // 좋아요 수
          if (likes > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('$likes명이 좋아합니다', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),

          // 내용 (3줄 제한 + 더 보기)
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$displayName $content',
                    style: const TextStyle(fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (content.split('\n').length > 3 || content.length > 120)
                    TextButton(
                      onPressed: _showFullContent,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '더 보기',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),

          // 댓글 (최신순 3개 + 더 보기)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community')
                  .doc(postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                final commentDocs = snapshot.data!.docs;
                final totalComments = data['comments'] as int? ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...commentDocs.map((doc) {
                      final cData = doc.data() as Map<String, dynamic>;
                      final cDisplayName = cData['displayName'] ?? 'Unknown';
                      final cContent = cData['content'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.grey[300],
                              child: Text(cDisplayName.isNotEmpty ? cDisplayName[0] : '?', style: const TextStyle(fontSize: 10)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$cDisplayName $cContent',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    if (totalComments > 3)
                      TextButton(
                        onPressed: () => CommentBottomSheet.show(context, postId),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '+${totalComments - 3}개 더 보기',
                          style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}