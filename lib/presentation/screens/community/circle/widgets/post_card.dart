import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/like_button.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/comment_button.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/comment_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';

class PostCard extends ConsumerWidget {
  final QueryDocumentSnapshot doc;
  final String? currentUserId;
  final void Function(double)? onHeightCalculated;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  late final GlobalKey cardKey;

  // 캐시
  static final Map<String, String?> _photoCache = {};

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

    final isAuthor = postUserId == currentUserId;
    final isAdmin = ref.watch(isAdminProvider).when(data: (v) => v, loading: () => false, error: (_, __) => false);
    final canEdit = isAuthor && onEdit != null;
    final canDelete = isAuthor || isAdmin;

    return Container(
      key: cardKey,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === 1. 프로필 + 더보기 ===
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                _buildProfileAvatar(postUserId, data['userPhotoUrl'] as String?),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (timestamp != null)
                        Text(
                          AppDateUtils.formatRelativeTime(timestamp),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                // 더보기 버튼
                if (canEdit || canDelete)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 22, color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (v) {
                      if (v == 'edit') onEdit?.call();
                      if (v == 'delete') onDelete?.call();
                    },
                    itemBuilder: (_) => [
                      if (canEdit) const PopupMenuItem(value: 'edit', child: Text('수정')),
                      if (canDelete) const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(color: Colors.red))),
                    ],
                  ),
              ],
            ),
          ),

          // === 2. 사진 ===
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(photoUrl, width: double.infinity, height: 300, fit: BoxFit.cover),
          ),

          // === 3. 좋아요/댓글/공유 ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                LikeButton(postId: postId, currentUserId: currentUserId),
                const SizedBox(width: 16),
                CommentButton(postId: postId, commentsCount: comments),
                const SizedBox(width: 16),
                IconButton(icon: const Icon(Icons.send_outlined, size: 24), onPressed: () => Share.share('$content\n$photoUrl')),
                const Spacer(),
                const Icon(Icons.bookmark_border, size: 24),
              ],
            ),
          ),

          // === 4. 좋아요 수 ===
          if (likes > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('$likes명이 좋아합니다', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),

          // === 5. 내용 ===
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 13),
                      children: [
                        TextSpan(text: '$displayName ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: content),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (content.split('\n').length > 3 || content.length > 120)
                    TextButton(
                      onPressed: () => _showFullContent(context, displayName, content),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      child: const Text('더 보기', style: TextStyle(fontSize: 12, color: Colors.blue)),
                    ),
                ],
              ),
            ),

          // === 6. 댓글 미리보기 ===
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
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black, fontSize: 12),
                            children: [
                              TextSpan(text: '$cDisplayName ', style: const TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: cContent),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    if (totalComments > 3)
                      TextButton(
                        onPressed: () => CommentBottomSheet.show(context, postId),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        child: Text('+${totalComments - 3}개 더 보기', style: const TextStyle(fontSize: 12, color: Colors.blue)),
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

  // 실시간 프로필 사진 + 캐시
  Widget _buildProfileAvatar(String? userId, String? fallbackUrl) {
    if (userId == null) {
      return const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 20));
    }

    // 캐시 확인
    final cached = _photoCache[userId];
    if (cached != null) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: cached.isNotEmpty ? NetworkImage(cached) : null,
        child: cached.isEmpty ? const Icon(Icons.person, size: 20) : null,
      );
    }

    // 크기 고정 + null 체크
    return SizedBox(
      width: 36,
      height: 36,
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 20));
          }

          final photoUrl = snapshot.data!.get('profileImageUrl') as String? ?? fallbackUrl;
          if (photoUrl != null && photoUrl.isNotEmpty) {
            _photoCache[userId] = photoUrl;
          }

          return CircleAvatar(
            radius: 18,
            backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
            child: photoUrl?.isNotEmpty != true ? const Icon(Icons.person, size: 20) : null,
          );
        },
      ),
    );
  }

  void _showFullContent(BuildContext context, String displayName, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(radius: 14, child: Text(displayName.isNotEmpty ? displayName[0] : '?')),
            const SizedBox(width: 8),
            Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(child: Text(content)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기'))],
      ),
    );
  }
}