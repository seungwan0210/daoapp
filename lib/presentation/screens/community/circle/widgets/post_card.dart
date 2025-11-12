// lib/presentation/screens/community/circle/widgets/post_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/post_item_widget.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/like_button.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/comment_button.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/comment_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';
// 맨 위에 추가
import 'package:daoapp/presentation/providers/app_providers.dart';

class PostCard extends ConsumerWidget {
  final QueryDocumentSnapshot doc;
  final String? currentUserId;
  final void Function(double)? onHeightCalculated;
  final VoidCallback? onEdit;     // 추가
  final VoidCallback? onDelete;   // 추가
  late final GlobalKey cardKey;

  PostCard({
    super.key,
    required this.doc,
    this.currentUserId,
    this.onHeightCalculated,
    this.onEdit,
    this.onDelete,
  }) : cardKey = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = doc.data() as Map<String, dynamic>;
    final postId = doc.id;
    final photoUrl = data['photoUrl'] as String?;
    if (photoUrl == null || photoUrl.isEmpty) return const SizedBox.shrink();

    final displayName = data['displayName'] ?? 'Unknown';
    final content = data['content'] ?? '';
    final likes = data['likes'] as int? ?? 0;
    final comments = data['comments'] as int? ?? 0;
    final postUserId = data['userId'] as String?;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

    // 높이 측정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = cardKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && onHeightCalculated != null) {
        onHeightCalculated!(box.size.height);
      }
    });

    return Container(
      key: cardKey,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // PostItemWidget 사용
          PostItemWidget(
            title: displayName,
            content: content,
            authorName: displayName,
            timestamp: timestamp ?? DateTime.now(),
            postId: postId,
            collectionPath: 'community',
            authorId: postUserId ?? '',
            onEdit: postUserId == currentUserId ? onEdit : null,
            onDelete: (postUserId == currentUserId || ref.watch(isAdminProvider).when(
              data: (v) => v,
              loading: () => false,
              error: (_, __) => false,
            )) ? onDelete : null,
            onTap: null,
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
                IconButton(
                  icon: const Icon(Icons.send_outlined, size: 24),
                  onPressed: () => Share.share('$content\n$photoUrl'),
                ),
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

          // 댓글 미리보기
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
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
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
                          children: [
                            CircleAvatar(radius: 12, backgroundColor: Colors.grey[300], child: Text(cDisplayName[0])),
                            const SizedBox(width: 8),
                            Expanded(child: Text('$cDisplayName $cContent', style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      );
                    }).toList(),
                    if (totalComments > 3)
                      TextButton(
                        onPressed: () => CommentBottomSheet.show(context, postId),
                        child: Text('+${totalComments - 3}개 더 보기', style: TextStyle(color: Colors.blue[700])),
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