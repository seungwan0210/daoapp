// lib/presentation/screens/community/circle/widgets/post_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/presentation/screens/community/circle/widgets/like_button.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/comment_button.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/comment_preview.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/user_profile_dialog.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/utils/badge_utils.dart';

class PostCard extends ConsumerStatefulWidget {
  final QueryDocumentSnapshot doc;
  final String? currentUserId;
  final void Function(double)? onHeightCalculated;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  // (기존 유지) 상위에서 미리 계산해준 값들
  final Map<String, String?>? barrelData;
  final String? monthlyBadge;
  final String? adminBadge;

  /// ✅ (옵션) Grid → List Hero 연결용
  /// 예: heroTag: 'post_$postId'
  final Object? heroTag;

  const PostCard({
    super.key,
    required this.doc,
    this.currentUserId,
    this.onHeightCalculated,
    this.onEdit,
    this.onDelete,
    this.barrelData,
    this.monthlyBadge,
    this.adminBadge,
    this.heroTag,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isContentExpanded = false;
  late final GlobalKey _cardKey = GlobalKey();

  static const String _fallbackImageAsset = 'assets/images/circle_main.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportHeight());
  }

  void _reportHeight() {
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && widget.onHeightCalculated != null) {
      widget.onHeightCalculated!(box.size.height);
    }
  }

  String? _extractPhotoUrl(Map<String, dynamic> data) {
    // 1) imageUrls 배열 우선
    final dynamic images = data['imageUrls'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
    }
    // 2) 예전 방식 photoUrl
    final p = (data['photoUrl'] as String?)?.trim();
    if (p != null && p.isNotEmpty) return p;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.doc.data() as Map<String, dynamic>;
    final postId = widget.doc.id;

    final String? postUserId = (data['userId'] as String?)?.trim();
    final content = (data['content'] ?? '').toString();
    final likes = data['likes'] as int? ?? 0;
    final comments = data['comments'] as int? ?? 0;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

    // ✅ 사진 없으면 null, 나중에 fallback asset로 보여줌
    final photoUrl = _extractPhotoUrl(data);

    final isAuthor = postUserId != null && postUserId == widget.currentUserId;
    final isAdmin = ref
        .watch(isAdminProvider)
        .when(data: (v) => v, loading: () => false, error: (_, __) => false);

    final canEdit = isAuthor && widget.onEdit != null;
    final canDelete = isAuthor || isAdmin;
    final bool isLongContent = content.length > 100 || content.contains('\n');

    // ✅ 유저 문서 실시간(1개 StreamBuilder로 통합)
    final userStream = (postUserId == null)
        ? null
        : FirebaseFirestore.instance.collection('users').doc(postUserId).snapshots();

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
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userStream,
        builder: (context, snap) {
          final userData = (snap.hasData && snap.data!.exists)
              ? (snap.data!.data() ?? <String, dynamic>{})
              : <String, dynamic>{};

          final koreanName = (userData['koreanName']?.toString().trim().isNotEmpty == true)
              ? userData['koreanName'].toString().trim()
              : (data['userName']?.toString().trim().isNotEmpty == true
              ? data['userName'].toString().trim()
              : 'Unknown');

          final profileImageUrl = (userData['profileImageUrl'] as String?)?.trim();
          final fallbackUserPhotoUrl = (data['userPhotoUrl'] as String?)?.trim();

          // ✅ 배지는 상위에서 이미 주면 그걸 우선 사용
          String? monthlyBadge = widget.monthlyBadge;
          String? adminBadge = widget.adminBadge;

          if (monthlyBadge == null || adminBadge == null) {
            final badgesMap = BadgeUtils.extractBadges(userData);
            monthlyBadge ??= BadgeUtils.getLatestMonthlyBadge(badgesMap);
            adminBadge ??= BadgeUtils.getLatestAdminBadge(badgesMap);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === 1. 프로필 + 더보기 + 배지 ===
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: postUserId != null ? () => _showUserProfileDialog(postUserId!) : null,
                      child: _ProfileAvatar(
                        radius: 20,
                        primaryColor: theme.colorScheme.primaryContainer,
                        photoUrl: profileImageUrl?.isNotEmpty == true
                            ? profileImageUrl
                            : (fallbackUserPhotoUrl?.isNotEmpty == true ? fallbackUserPhotoUrl : null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  koreanName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (monthlyBadge != null)
                                Tooltip(
                                  message: BadgeUtils.getBadgeTooltip(monthlyBadge),
                                  child: BadgeWidget(
                                    badgeKey: monthlyBadge,
                                    size: 18,
                                  ),
                                ),
                              if (adminBadge != null)
                                Tooltip(
                                  message: BadgeUtils.getBadgeTooltip(adminBadge),
                                  child: BadgeWidget(
                                    badgeKey: adminBadge,
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                          if (timestamp != null)
                            Text(
                              AppDateUtils.formatRelativeTime(timestamp),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (canEdit || canDelete)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 22,
                          color: Colors.grey[600],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (v) {
                          if (v == 'edit') widget.onEdit?.call();
                          if (v == 'delete') widget.onDelete?.call();
                        },
                        itemBuilder: (_) => [
                          if (canEdit)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('수정'),
                            ),
                          if (canDelete)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                '삭제',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),

              // === 2. 사진 (없어도 기본 이미지 보여줌) ===
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _buildPostImage(photoUrl, widget.heroTag),
              ),

              // === 3. 좋아요/댓글/공유 ===
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    LikeButton(
                      postId: postId,
                      currentUserId: widget.currentUserId,
                      likesCount: likes,
                    ),
                    const SizedBox(width: 16),
                    CommentButton(
                      postId: postId,
                      commentsCount: comments,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.send_outlined, size: 24),
                      onPressed: () => Share.share('$content\n${photoUrl ?? ''}'),
                      color: theme.colorScheme.primary,
                    ),
                    const Spacer(),
                    const Icon(Icons.bookmark_border, size: 24),
                  ],
                ),
              ),

              // === 4. 내용 ===
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
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(
                                text: '$koreanName ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              TextSpan(text: content),
                            ],
                          ),
                          maxLines: _isContentExpanded ? null : 2,
                          overflow: _isContentExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
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
          );
        },
      ),
    );
  }

  Widget _buildPostImage(String? photoUrl, Object? heroTag) {
    final child = (photoUrl == null || photoUrl.isEmpty)
        ? Image.asset(
      _fallbackImageAsset,
      width: double.infinity,
      height: 300,
      fit: BoxFit.cover,
    )
        : Image.network(
      photoUrl,
      width: double.infinity,
      height: 300,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Image.asset(
        _fallbackImageAsset,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
      ),
    );

    if (heroTag == null) return child;

    return Hero(
      tag: heroTag,
      child: child,
    );
  }

  void _showUserProfileDialog(String userId) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = currentUid == userId;

    showDialog(
      context: context,
      builder: (_) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists || snapshot.data!.data() == null) {
            return UserProfileDialog(
              koreanName: '프로필 없음',
              isMe: isMe,
              userId: userId,
            );
          }

          final data = snapshot.data!.data() ?? <String, dynamic>{};
          final hasProfile = data['hasProfile'] == true;
          if (!hasProfile) {
            return UserProfileDialog(
              koreanName: '프로필 미완료',
              isMe: isMe,
              userId: userId,
            );
          }

          final koreanName = data['koreanName']?.toString().trim() ?? '이름 없음';
          final englishName = data['englishName']?.toString().trim();
          final photoUrl = (data['profileImageUrl'] as String?)?.trim();
          final shopName = data['shopName']?.toString().trim();

          final barrelData = widget.barrelData ??
              (data['barrelName']?.toString().isNotEmpty == true ||
                  data['shaft']?.toString().isNotEmpty == true ||
                  data['flight']?.toString().isNotEmpty == true ||
                  data['tip']?.toString().isNotEmpty == true ||
                  (data['barrelImageUrl'] as String?)?.isNotEmpty == true
                  ? {
                'barrelImageUrl': data['barrelImageUrl'] as String?,
                'barrelName': data['barrelName']?.toString().trim() ?? '',
                'shaft': data['shaft']?.toString().trim() ?? '',
                'flight': data['flight']?.toString().trim() ?? '',
                'tip': data['tip']?.toString().trim() ?? '',
              }
                  : null);

          return UserProfileDialog(
            koreanName: koreanName,
            englishName: englishName,
            photoUrl: photoUrl,
            shopName: shopName,
            barrelData: barrelData,
            isMe: isMe,
            userId: userId,
          );
        },
      ),
    );
  }
}

/// ===============================
/// 프로필 아바타(실시간 데이터 기반)
/// ===============================
class _ProfileAvatar extends StatelessWidget {
  final double radius;
  final Color primaryColor;
  final String? photoUrl;

  const _ProfileAvatar({
    required this.radius,
    required this.primaryColor,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: primaryColor,
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
          photoUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Icon(
            Icons.person,
            size: radius,
            color: Colors.white,
          ),
        )
            : Icon(
          Icons.person,
          size: radius,
          color: Colors.white,
        ),
      ),
    );
  }
}
