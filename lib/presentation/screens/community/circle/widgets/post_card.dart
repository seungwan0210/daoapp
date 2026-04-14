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

  final Map<String, String?>? barrelData;
  final String? monthlyBadge;
  final String? adminBadge;

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
    final dynamic images = data['imageUrls'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
    }
    final p = (data['photoUrl'] as String?)?.trim();
    if (p != null && p.isNotEmpty) return p;
    return null;
  }

  // ===========================
  // 차단/신고 - Firestore 경로
  // ===========================
  DocumentReference<Map<String, dynamic>> _blockedDocRef({
    required String blockerUid,
    required String blockedUid,
  }) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(blockerUid)
        .collection('blockedUsers')
        .doc(blockedUid);
  }

  CollectionReference<Map<String, dynamic>> _reportsColRef() {
    return FirebaseFirestore.instance.collection('reports');
  }

  // ===========================
  // 신고 문서 포맷(관리자 화면 호환)
  // ===========================
  Future<void> _createReport({
    required String title,
    required String content,
    required String type, // community_post / community_block 등
    required String reporterId,
    required String reporterName,
    String? reporterEmail,
    String? targetUserId,
    String? targetUserName,
    String? postId,
    String? imageUrl,
    String? reason,
    String? detail,
  }) async {
    await _reportsColRef().add({
      // AdminReportListScreen이 보는 필드들
      'title': title,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'processed': false,
      'processedAt': null,

      // 신고자
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterEmail': reporterEmail,

      // 대상 정보(서클에서 필요)
      'type': type, // 'community_post' / 'community_block'
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'postId': postId,
      'imageUrl': imageUrl,

      // 사유/상세
      'reason': reason,
      'detail': (detail ?? '').trim(),
    });
  }

  Future<Map<String, String?>> _getReporterInfo(String uid) async {
    try {
      final snap =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!snap.exists || snap.data() == null) {
        return {'name': '익명', 'email': null};
      }
      final data = snap.data() as Map<String, dynamic>;
      final name = data['koreanName']?.toString().trim();
      final email = data['email']?.toString().trim();
      return {
        'name': (name?.isNotEmpty == true) ? name : '익명',
        'email': (email?.isNotEmpty == true) ? email : null,
      };
    } catch (_) {
      return {'name': '익명', 'email': null};
    }
  }

  Future<void> _confirmAndBlock({
    required String blockedUid,
    required String blockedName,
    required String postId,
    String? postImageUrl,
  }) async {
    final me = widget.currentUserId;
    if (me == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사용자 차단'),
        content: Text(
          '$blockedName 님을 차단할까요?\n\n'
              '차단하면 이 사용자의 게시글/댓글이 커뮤니티에서 보이지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('차단'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      // 1) 차단 문서 저장
      await _blockedDocRef(blockerUid: me, blockedUid: blockedUid).set({
        'blockedUserId': blockedUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2) ✅ 차단 시 자동으로 개발자에게 "신고" 남기기 (Apple 요구: block notify developer)
      final reporterInfo = await _getReporterInfo(me);
      await _createReport(
        title: '커뮤니티 차단 접수',
        content:
        '사용자가 커뮤니티에서 "$blockedName" 를 차단했습니다. (즉시 피드에서 숨김 처리됨)',
        type: 'community_block',
        reporterId: me,
        reporterName: reporterInfo['name'] ?? '익명',
        reporterEmail: reporterInfo['email'],
        targetUserId: blockedUid,
        targetUserName: blockedName,
        postId: postId,
        imageUrl: postImageUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$blockedName 님을 차단했어요')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('차단 실패: $e')),
      );
    }
  }

  Future<void> _confirmAndUnblock({
    required String blockedUid,
    required String blockedName,
  }) async {
    final me = widget.currentUserId;
    if (me == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('차단 해제'),
        content: Text('$blockedName 님 차단을 해제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('해제'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _blockedDocRef(blockerUid: me, blockedUid: blockedUid).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$blockedName 님 차단을 해제했어요')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('차단 해제 실패: $e')),
      );
    }
  }

  Future<void> _openReportDialog({
    required String postId,
    required String reportedUid,
    required String reportedName,
    required String postContentPreview,
    String? postImageUrl,
  }) async {
    final me = widget.currentUserId;
    if (me == null) return;

    final reasons = <String>[
      '스팸/도배',
      '욕설/혐오',
      '괴롭힘/따돌림',
      '성적인 콘텐츠',
      '폭력/위협',
      '기타',
    ];

    String selected = reasons.first;
    final detailCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('게시물 신고'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selected,
                items: reasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => selected = v ?? selected),
                decoration: const InputDecoration(
                  labelText: '신고 사유',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: detailCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '추가 설명(선택)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('신고'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) {
      detailCtrl.dispose();
      return;
    }

    try {
      final reporterInfo = await _getReporterInfo(me);

      await _createReport(
        title: '커뮤니티 게시물 신고',
        content:
        '사유: $selected\n\n대상: $reportedName\n\n내용 미리보기: $postContentPreview',
        type: 'community_post',
        reporterId: me,
        reporterName: reporterInfo['name'] ?? '익명',
        reporterEmail: reporterInfo['email'],
        targetUserId: reportedUid,
        targetUserName: reportedName,
        postId: postId,
        imageUrl: postImageUrl,
        reason: selected,
        detail: detailCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신고가 접수되었어요. 감사합니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('신고 실패: $e')),
      );
    } finally {
      detailCtrl.dispose();
    }
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

    final photoUrl = _extractPhotoUrl(data);

    final isAuthor = postUserId != null && postUserId == widget.currentUserId;
    final isAdmin = ref
        .watch(isAdminProvider)
        .when(data: (v) => v, loading: () => false, error: (_, __) => false);

    final canEdit = isAuthor && widget.onEdit != null;
    final canDelete = isAuthor || isAdmin;
    final bool isLongContent = content.length > 100 || content.contains('\n');

    // 유저 문서 실시간
    final userStream = (postUserId == null)
        ? null
        : FirebaseFirestore.instance.collection('users').doc(postUserId).snapshots();

    // 차단 여부 스트림
    final me = widget.currentUserId;
    final blockedStream = (me != null && postUserId != null && me != postUserId)
        ? _blockedDocRef(blockerUid: me, blockedUid: postUserId).snapshots()
        : null;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: blockedStream,
      builder: (context, blockedSnap) {
        final isBlocked = blockedSnap.data?.exists ?? false;

        // 차단된 유저 글은 렌더링 X
        if (isBlocked) return const SizedBox.shrink();

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

              final koreanName =
              (userData['koreanName']?.toString().trim().isNotEmpty == true)
                  ? userData['koreanName'].toString().trim()
                  : (data['userName']?.toString().trim().isNotEmpty == true
                  ? data['userName'].toString().trim()
                  : 'Unknown');

              final profileImageUrl =
              (userData['profileImageUrl'] as String?)?.trim();
              final fallbackUserPhotoUrl =
              (data['userPhotoUrl'] as String?)?.trim();

              String? monthlyBadge = widget.monthlyBadge;
              String? adminBadge = widget.adminBadge;

              if (monthlyBadge == null || adminBadge == null) {
                final badgesMap = BadgeUtils.extractBadges(userData);
                monthlyBadge ??= BadgeUtils.getLatestMonthlyBadge(badgesMap);
                adminBadge ??= BadgeUtils.getLatestAdminBadge(badgesMap);
              }

              final canShowMenu = (widget.currentUserId != null);

              final menuItems = <PopupMenuEntry<String>>[
                const PopupMenuItem(value: 'share', child: Text('공유')),
                if (!isAuthor && postUserId != null) ...[
                  const PopupMenuItem(value: 'report', child: Text('신고')),
                  const PopupMenuItem(value: 'block', child: Text('차단')),
                ],
                if (canEdit) const PopupMenuItem(value: 'edit', child: Text('수정')),
                if (canDelete)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('삭제', style: TextStyle(color: Colors.red)),
                  ),
              ];

              final preview = content.trim().isEmpty
                  ? '(내용 없음)'
                  : (content.trim().length > 80
                  ? '${content.trim().substring(0, 80)}...'
                  : content.trim());

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 프로필 + 더보기 + 배지
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: postUserId != null
                              ? () => _showUserProfileDialog(postUserId!)
                              : null,
                          child: _ProfileAvatar(
                            radius: 20,
                            primaryColor: theme.colorScheme.primaryContainer,
                            photoUrl: profileImageUrl?.isNotEmpty == true
                                ? profileImageUrl
                                : (fallbackUserPhotoUrl?.isNotEmpty == true
                                ? fallbackUserPhotoUrl
                                : null),
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
                                      child: BadgeWidget(badgeKey: monthlyBadge, size: 18),
                                    ),
                                  if (adminBadge != null)
                                    Tooltip(
                                      message: BadgeUtils.getBadgeTooltip(adminBadge),
                                      child: BadgeWidget(badgeKey: adminBadge, size: 18),
                                    ),
                                ],
                              ),
                              if (timestamp != null)
                                Text(
                                  AppDateUtils.formatRelativeTime(timestamp),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                        if (canShowMenu)
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, size: 22, color: Colors.grey[600]),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (v) async {
                              if (v == 'share') {
                                Share.share('$content\n${photoUrl ?? ''}');
                                return;
                              }

                              if (v == 'edit') widget.onEdit?.call();
                              if (v == 'delete') widget.onDelete?.call();

                              if (postUserId == null) return;

                              if (v == 'report') {
                                await _openReportDialog(
                                  postId: postId,
                                  reportedUid: postUserId,
                                  reportedName: koreanName,
                                  postContentPreview: preview,
                                  postImageUrl: photoUrl,
                                );
                                return;
                              }

                              if (v == 'block') {
                                await _confirmAndBlock(
                                  blockedUid: postUserId,
                                  blockedName: koreanName,
                                  postId: postId,
                                  postImageUrl: photoUrl,
                                );
                                return;
                              }

                              if (v == 'unblock') {
                                await _confirmAndUnblock(
                                  blockedUid: postUserId,
                                  blockedName: koreanName,
                                );
                                return;
                              }
                            },
                            itemBuilder: (_) => menuItems,
                          ),
                      ],
                    ),
                  ),

                  // 2. 사진
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: _buildPostImage(photoUrl, widget.heroTag),
                  ),

                  // 3. 좋아요/댓글/공유
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

                  // 4. 내용
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
                                Future.delayed(
                                  const Duration(milliseconds: 300),
                                  _reportHeight,
                                );
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

                  // 5. 댓글 미리보기
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
      },
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

    return Hero(tag: heroTag, child: child);
  }

  void _showUserProfileDialog(String userId) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = currentUid == userId;

    showDialog(
      context: context,
      builder: (_) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists || snapshot.data!.data() == null) {
            return UserProfileDialog(koreanName: '프로필 없음', isMe: isMe, userId: userId);
          }

          final data = snapshot.data!.data() ?? <String, dynamic>{};
          final hasProfile = data['hasProfile'] == true;
          if (!hasProfile) {
            return UserProfileDialog(koreanName: '프로필 미완료', isMe: isMe, userId: userId);
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
          errorBuilder: (_, __, ___) => Icon(Icons.person, size: radius, color: Colors.white),
        )
            : Icon(Icons.person, size: radius, color: Colors.white),
      ),
    );
  }
}
