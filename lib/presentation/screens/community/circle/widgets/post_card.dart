// lib/presentation/screens/community/circle/widgets/post_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/like_button.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/comment_button.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/comment_preview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/user_profile_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostCard extends ConsumerStatefulWidget {
  final QueryDocumentSnapshot doc;
  final String? currentUserId;
  final void Function(double)? onHeightCalculated;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.doc,
    this.currentUserId,
    this.onHeightCalculated,
    this.onEdit,
    this.onDelete,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isContentExpanded = false;
  late final GlobalKey _cardKey = GlobalKey();

  static final Map<String, String?> _photoCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportHeight();
    });
  }

  void _reportHeight() {
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && widget.onHeightCalculated != null) {
      widget.onHeightCalculated!(box.size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);  // 이 줄 추가! (오류 해결)

    final data = widget.doc.data() as Map<String, dynamic>;
    final postId = widget.doc.id;
    final photoUrl = data['photoUrl'] as String?;
    if (photoUrl == null || photoUrl.isEmpty) return const SizedBox(); // 수정: shrink → SizedBox

    final displayName = data['displayName'] ?? 'Unknown';
    final content = data['content'] ?? '';
    final likes = data['likes'] as int? ?? 0;
    final comments = data['comments'] as int? ?? 0;
    final postUserId = data['userId'] as String?;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

    final isAuthor = postUserId == widget.currentUserId;
    final isAdmin = ref.watch(isAdminProvider).when(
      data: (v) => v,
      loading: () => false,
      error: (_, __) => false,
    );
    final canEdit = isAuthor && widget.onEdit != null;
    final canDelete = isAuthor || isAdmin;

    final bool isLongContent = content.length > 100 || content.contains('\n');

    return Container(
      key: _cardKey,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primaryContainer,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
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
                GestureDetector(
                  onTap: postUserId != null
                      ? () => _showUserProfileDialog(postUserId)
                      : null,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: _buildProfileAvatar(postUserId, data['userPhotoUrl'] as String?),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (timestamp != null)
                        Text(
                          AppDateUtils.formatRelativeTime(timestamp),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                if (canEdit || canDelete)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 22, color: Colors.grey[600]),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (v) {
                      if (v == 'edit') widget.onEdit?.call();
                      if (v == 'delete') widget.onDelete?.call();
                    },
                    itemBuilder: (_) => [
                      if (canEdit) const PopupMenuItem(value: 'edit', child: Text('수정')),
                      if (canDelete)
                        const PopupMenuItem(
                            value: 'delete', child: Text('삭제', style: TextStyle(color: Colors.red))),
                    ],
                  ),
              ],
            ),
          ),

          // === 2. 사진 ===
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              photoUrl,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 300,
                color: Colors.grey[200],
                child: const Icon(Icons.error, color: Colors.red),
              ),
            ),
          ),

          // === 3. 좋아요/댓글/공유 ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                LikeButton(postId: postId, currentUserId: widget.currentUserId, likesCount: likes),
                const SizedBox(width: 16),
                CommentButton(postId: postId, commentsCount: comments),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.send_outlined, size: 24),
                  onPressed: () => Share.share('$content\n$photoUrl'),
                  color: theme.colorScheme.primary,
                ),
                const Spacer(),
                const Icon(Icons.bookmark_border, size: 24),
              ],
            ),
          ),

          // === 4. 내용 (펼치기/접기) ===
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                        children: [
                          TextSpan(
                            text: '$displayName ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          TextSpan(text: _isContentExpanded ? content : content),
                        ],
                      ),
                      maxLines: _isContentExpanded ? null : 2,
                      overflow: _isContentExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                  ),
                  if (isLongContent)
                    GestureDetector(
                      onTap: () {
                        setState(() => _isContentExpanded = !_isContentExpanded);
                        Future.delayed(const Duration(milliseconds: 300), _reportHeight);
                      },
                      child: Text(
                        _isContentExpanded ? '간략히' : '더 보기',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // === 5. 댓글 미리보기 ===
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: CommentPreview(
              postId: postId,
              currentUserId: widget.currentUserId,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String? userId, String? fallbackUrl) {
    if (userId == null) return const Icon(Icons.person, size: 20, color: Colors.white);

    final cached = _photoCache[userId];
    if (cached != null) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: cached.isNotEmpty ? NetworkImage(cached) : null,
        child: cached.isEmpty ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          photoUrl = snapshot.data!['profileImageUrl'] as String? ?? fallbackUrl;
          if (photoUrl != null && photoUrl.isNotEmpty) _photoCache[userId] = photoUrl;
        }

        return CircleAvatar(
          radius: 18,
          backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
          child: photoUrl?.isNotEmpty != true
              ? const Icon(Icons.person, size: 20, color: Colors.white)
              : null,
        );
      },
    );
  }

  void _showUserProfileDialog(String userId) {
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
}