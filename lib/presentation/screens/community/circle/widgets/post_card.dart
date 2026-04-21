import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import 'package:daoapp/presentation/screens/community/circle/widgets/like_button.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/comment_button.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/comment_preview.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/user_profile_dialog.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart'; // 🆕 추가
import 'package:daoapp/core/utils/badge_utils.dart'; // 🆕 추가

class PostCard extends ConsumerStatefulWidget {
  final QueryDocumentSnapshot doc;
  final String? currentUserId;
  final void Function(double)? onHeightCalculated;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  final Map<String, String?>? barrelData;
  final String? monthlyBadge;
  final String? adminBadge;
  final int? currentRank; // 🆕 실시간 순위 파라미터 추가

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
    this.currentRank, // 🆕 생성자 추가
    this.heroTag,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isContentExpanded = false;
  late final GlobalKey _cardKey = GlobalKey();
  int _currentPage = 0;

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

  List<String> _extractImageUrls(Map<String, dynamic> data) {
    final dynamic images = data['imageUrls'];
    if (images is List && images.isNotEmpty) {
      return List<String>.from(images);
    }
    final p = (data['photoUrl'] as String?)?.trim();
    if (p != null && p.isNotEmpty) return [p];
    return [];
  }

  DocumentReference<Map<String, dynamic>> _blockedDocRef({
    required String blockerUid,
    required String blockedUid,
  }) {
    return FirebaseFirestore.instance.collection('users').doc(blockerUid).collection('blockedUsers').doc(blockedUid);
  }

  Future<void> _createReport({
    required String title,
    required String content,
    required String type,
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
    await FirebaseFirestore.instance.collection('reports').add({
      'title': title,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'processed': false,
      'processedAt': null,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterEmail': reporterEmail,
      'type': type,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'postId': postId,
      'imageUrl': imageUrl,
      'reason': reason,
      'detail': (detail ?? '').trim(),
    });
  }

  Future<Map<String, String?>> _getReporterInfo(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!snap.exists || snap.data() == null) return {'name': '익명', 'email': null};
      final data = snap.data()!;
      final name = data['koreanName']?.toString().trim();
      final email = data['email']?.toString().trim();
      return {'name': (name?.isNotEmpty == true) ? name! : '익명', 'email': email};
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
        backgroundColor: Colors.grey[900], // 다크 테마 적용
        title: const Text('사용자 차단', style: TextStyle(color: Colors.white)),
        content: Text('$blockedName 님을 차단할까요?\n\n차단하면 이 사용자의 게시글이 보이지 않습니다.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('차단', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (ok != true) return;

    try {
      // ✅ 중앙 DB에 차단 기록 (이게 들어가면 전광판/피드/채팅 다 사라짐)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(me)
          .collection('blockedUsers')
          .doc(blockedUid)
          .set({
        'blockedUserId': blockedUid,
        'name': blockedName, // 나중에 차단 관리 목록에서 이름을 보여주기 위해 저장
        'createdAt': FieldValue.serverTimestamp(),
      });

      final reporterInfo = await _getReporterInfo(me);
      await _createReport(
        title: '커뮤니티 차단 접수',
        content: '사용자가 "$blockedName" 를 차단했습니다.',
        type: 'community_block',
        reporterId: me,
        reporterName: reporterInfo['name']!,
        reporterEmail: reporterInfo['email'],
        targetUserId: blockedUid,
        targetUserName: blockedName,
        postId: postId,
        imageUrl: postImageUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$blockedName 님을 차단했어요')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('차단 실패: $e')));
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

    final reasons = <String>['스팸/도배', '욕설/혐오', '괴롭힘/따돌림', '성적인 콘텐츠', '폭력/위협', '기타'];
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
                items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => selected = v ?? selected),
                decoration: const InputDecoration(labelText: '신고 사유', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: detailCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: '추가 설명(선택)', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('신고')),
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
        content: '사유: $selected\n내용: $postContentPreview',
        type: 'community_post',
        reporterId: me,
        reporterName: reporterInfo['name']!,
        reporterEmail: reporterInfo['email'],
        targetUserId: reportedUid,
        targetUserName: reportedName,
        postId: postId,
        imageUrl: postImageUrl,
        reason: selected,
        detail: detailCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('신고가 접수되었어요.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('신고 실패: $e')));
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

    final imageUrls = _extractImageUrls(data);
    final isAuthor = postUserId != null && postUserId == widget.currentUserId;
    final isAdmin = ref.watch(isAdminProvider).when(data: (v) => v, loading: () => false, error: (_, __) => false);

    final canEdit = isAuthor && widget.onEdit != null;
    final canDelete = isAuthor || isAdmin;
    final bool isLongContent = content.length > 100 || content.contains('\n');

    final userStream = (postUserId == null) ? null : FirebaseFirestore.instance.collection('users').doc(postUserId).snapshots();
    final me = widget.currentUserId;
    final blockedStream = (me != null && postUserId != null && me != postUserId) ? _blockedDocRef(blockerUid: me, blockedUid: postUserId).snapshots() : null;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: blockedStream,
      builder: (context, blockedSnap) {
        if (blockedSnap.data?.exists ?? false) return const SizedBox.shrink();

        return Container(
          key: _cardKey,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primaryContainer, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: userStream,
            builder: (context, snap) {
              final userData = (snap.hasData && snap.data!.exists) ? (snap.data!.data() ?? {}) : {};
              final koreanName = (userData['koreanName']?.toString().isNotEmpty == true) ? userData['koreanName'] : (data['userName'] ?? 'Unknown');
              final profileImageUrl = userData['profileImageUrl'] as String?;
              final fallbackUserPhotoUrl = data['userPhotoUrl'] as String?;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, postUserId, koreanName, profileImageUrl ?? fallbackUserPhotoUrl, isAuthor, canEdit, canDelete, content, imageUrls, postId),
                  _buildImageSlider(imageUrls, widget.heroTag),
                  _buildActionBar(theme, postId, likes, comments, content, imageUrls.isNotEmpty ? imageUrls.first : null),
                  if (content.isNotEmpty) _buildBodyContent(theme, koreanName, content, isLongContent),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: CommentPreview(postId: postId, currentUserId: widget.currentUserId),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildImageSlider(List<String> urls, Object? heroTag) {
    if (urls.isEmpty) {
      return ClipRRect(child: Image.asset(_fallbackImageAsset, width: double.infinity, height: 350, fit: BoxFit.cover));
    }
    return Stack(
      children: [
        SizedBox(
          height: 350,
          child: PageView.builder(
            itemCount: urls.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final img = Image.network(urls[index], width: double.infinity, height: 350, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, __, ___) => Image.asset(_fallbackImageAsset, fit: BoxFit.cover));
              return (index == 0 && heroTag != null) ? Hero(tag: heroTag, child: img) : img;
            },
          ),
        ),
        if (urls.length > 1)
          Positioned(
            top: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(16)),
              child: Text('${_currentPage + 1}/${urls.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, String? postUserId, String name, String? photo, bool isAuthor, bool canEdit, bool canDelete, String content, List<String> imageUrls, String postId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: postUserId != null ? () => _showUserProfileDialog(postUserId) : null,
            child: _ProfileAvatar(
              radius: 20,
              primaryColor: theme.colorScheme.primaryContainer,
              photoUrl: photo,
              currentRank: widget.currentRank, // 사진 옆 배지만 유지
              monthlyBadge: widget.monthlyBadge,
              adminBadge: widget.adminBadge,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 텍스트(이름) 옆 배지는 중복이라 제거하고 이름만 깔끔하게 표시
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppDateUtils.formatRelativeTime(widget.doc['timestamp']?.toDate() ?? DateTime.now()),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (widget.currentUserId != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 22),
              onSelected: (v) async {
                final currentUrl = imageUrls.isNotEmpty ? imageUrls[_currentPage] : null;
                final preview = content.length > 50 ? '${content.substring(0, 50)}...' : content;
                if (v == 'share') { Share.share('$content\n${currentUrl ?? ''}'); return; }
                if (v == 'edit') widget.onEdit?.call();
                if (v == 'delete') widget.onDelete?.call();
                if (postUserId == null) return;
                if (v == 'report') await _openReportDialog(postId: postId, reportedUid: postUserId, reportedName: name, postContentPreview: preview, postImageUrl: currentUrl);
                if (v == 'block') await _confirmAndBlock(blockedUid: postUserId, blockedName: name, postId: postId, postImageUrl: currentUrl);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'share', child: Text('공유')),
                if (!isAuthor) ...[
                  const PopupMenuItem(value: 'report', child: Text('신고')),
                  const PopupMenuItem(value: 'block', child: Text('차단')),
                ],
                if (canEdit) const PopupMenuItem(value: 'edit', child: Text('수정')),
                if (canDelete) const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(color: Colors.red))),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme, String postId, int likes, int comments, String content, String? firstPhoto) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          LikeButton(postId: postId, currentUserId: widget.currentUserId, likesCount: likes),
          const SizedBox(width: 16),
          CommentButton(postId: postId, commentsCount: comments),
          const SizedBox(width: 16),
          IconButton(icon: const Icon(Icons.send_outlined, size: 24), onPressed: () => Share.share('$content\n${firstPhoto ?? ''}'), color: theme.colorScheme.primary),
          const Spacer(),
          const Icon(Icons.bookmark_border, size: 24),
        ],
      ),
    );
  }

  Widget _buildBodyContent(ThemeData theme, String name, String content, bool isLong) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            maxLines: _isContentExpanded ? null : 2,
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              children: [
                TextSpan(text: '$name ', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                TextSpan(text: content),
              ],
            ),
          ),
          if (isLong)
            GestureDetector(
              onTap: () => setState(() => _isContentExpanded = !_isContentExpanded),
              child: Text(_isContentExpanded ? '간략히' : '더 보기', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }

  void _showUserProfileDialog(String userId) {
    final isMe = widget.currentUserId == userId;
    showDialog(
      context: context,
      builder: (_) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data?.data() ?? {};
          return UserProfileDialog(
            koreanName: data['koreanName'] ?? '이름 없음',
            englishName: data['englishName'],
            photoUrl: data['profileImageUrl'],
            shopName: data['shopName'],
            barrelData: data['barrelName'] != null ? {
              'barrelImageUrl': data['barrelImageUrl'],
              'barrelName': data['barrelName'],
              'shaft': data['shaft'],
              'flight': data['flight'],
              'tip': data['tip'],
            } : null,
            isMe: isMe,
            userId: userId,
          );
        },
      ),
    );
  }
}

// 🆕 _ProfileAvatar 수정: 아바타 좌측 상단에 배지 중첩 표시
class _ProfileAvatar extends StatelessWidget {
  final double radius;
  final Color primaryColor;
  final String? photoUrl;
  final int? currentRank;
  final String? monthlyBadge;
  final String? adminBadge;

  const _ProfileAvatar({
    required this.radius,
    required this.primaryColor,
    this.photoUrl,
    this.currentRank,
    this.monthlyBadge,
    this.adminBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: primaryColor,
          child: ClipOval(
            child: (photoUrl != null && photoUrl!.isNotEmpty)
                ? Image.network(photoUrl!, width: radius * 2, height: radius * 2, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person))
                : const Icon(Icons.person, color: Colors.white),
          ),
        ),
        // 실시간 랭킹 배지 (좌측 상단)
        if (currentRank != null)
          Positioned(
            left: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)]),
              child: BadgeWidget(rank: currentRank, size: 16),
            ),
          ),
      ],
    );
  }
}