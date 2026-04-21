import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/providers/app_providers.dart'; // ✅ 중앙 차단 프로바이더 임포트
import 'package:daoapp/presentation/widgets/user_profile_dialog.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
// ✅ 수정 코드 (랭킹 프로바이더 하나로 통합)
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';

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

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ [삭제됨] 중앙 blockedUserIdsProvider를 쓰기 때문에 개별 스트림 함수는 이제 필요 없습니다.

  String? _writerIdFrom(Map<String, dynamic> data) {
    return (data['writerId'] as String?) ?? (data['userId'] as String?);
  }

  // =========================
  // 신고: 댓글 (동일 유지)
  // =========================
  Future<void> _reportComment({
    required String postId,
    required String commentId,
    required String reportedUserId,
    required String reason,
    String? contentPreview,
  }) async {
    final reporterUid = _currentUid;
    if (reporterUid == null) return;

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'type': 'comment',
        'postId': postId,
        'commentId': commentId,
        'reportedUserId': reportedUserId,
        'reporterUserId': reporterUid,
        'reason': reason,
        'contentPreview': (contentPreview ?? '').toString().trim().isEmpty ? null : contentPreview,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('신고가 접수되었습니다')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('신고 실패: $e')));
    }
  }

  // 신고 다이얼로그 (동일 유지)
  Future<void> _openReportDialog({
    required String postId,
    required String commentId,
    required String reportedUserId,
    required String contentPreview,
  }) async {
    final reasons = <String>['스팸/도배', '욕설/비하', '혐오/차별', '성적/선정성', '개인정보 노출', '기타'];
    String selected = reasons.first;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('댓글 신고'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(alignment: Alignment.centerLeft, child: Text('사유를 선택해 주세요')),
              const SizedBox(height: 10),
              DropdownButton<String>(
                isExpanded: true,
                value: selected,
                items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => selected = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('신고', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
    if (result == true) {
      await _reportComment(postId: postId, commentId: commentId, reportedUserId: reportedUserId, reason: selected, contentPreview: contentPreview);
    }
  }

  // 댓글 작성 (동일 유지)
  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('community').doc(widget.postId).collection('comments').add({
      'userId': user.uid,
      'writerId': user.uid,
      'content': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('community').doc(widget.postId).update({'comments': FieldValue.increment(1)});
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  // 댓글 삭제 (동일 유지)
  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('community').doc(widget.postId).collection('comments').doc(commentId).delete();
      await FirebaseFirestore.instance.collection('community').doc(widget.postId).update({'comments': FieldValue.increment(-1)});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ [핵심 수정] 중앙 차단 목록을 실시간으로 감시합니다.
    final blockedIds = ref.watch(blockedUserIdsProvider).value ?? {};

    final isAdmin = ref.watch(isAdminProvider).when(
      data: (v) => v,
      loading: () => false,
      error: (_, __) => false,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('댓글', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const Divider(height: 1),

        // === 댓글 리스트 ===
        Expanded(
          child: _buildCommentsList(
            theme: theme,
            isAdmin: isAdmin,
            currentUserId: _currentUid,
            blockedIds: blockedIds, // ✅ 이제 중앙에서 가져온 목록을 직접 전달합니다.
          ),
        ),

        // === 입력창 ===
        Container(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: '댓글을 입력하세요...', border: InputBorder.none),
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
              IconButton(onPressed: _sendComment, icon: Icon(Icons.send, color: theme.colorScheme.primary)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildCommentsList({
    required ThemeData theme,
    required bool isAdmin,
    required String? currentUserId,
    required Set<String> blockedIds,
  }) {
    final totalRanking = ref.watch(totalRankingProvider);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('아직 댓글이 없습니다'));

        // 🔥 [핵심 필터링] 중앙 차단 목록을 기준으로 실시간 필터링
        final filteredDocs = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final String? writerId = _writerIdFrom(data);
          return writerId == null || !blockedIds.contains(writerId.trim());
        }).toList();

        if (filteredDocs.isEmpty) return const Center(child: Text('표시할 댓글이 없습니다'));

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredDocs.length,
          itemBuilder: (context, i) {
            final doc = filteredDocs[i];
            final data = doc.data() as Map<String, dynamic>;
            final commentId = doc.id;
            final String? writerId = _writerIdFrom(data);
            final String? userId = (data['userId'] as String?) ?? writerId;

            final content = data['content'] as String? ?? '';
            final timestamp = data['timestamp'] as Timestamp?;
            final timeStr = timestamp != null ? AppDateUtils.formatRelativeTime(timestamp.toDate()) : '방금 전';

            final isMyComment = writerId != null && writerId == currentUserId;
            final canDelete = isMyComment || isAdmin;
            final isLong = content.length > 80 || content.contains('\n');

            // 실시간 순위 확인 (배지용)
            final rankIndex = totalRanking.indexWhere((item) => item['userId'] == userId);
            final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(onTap: userId != null ? () => _showProfile(userId) : null, child: _buildAvatar(userId)),
                      if (currentRank != null)
                        Positioned(left: -4, top: -4, child: BadgeWidget(rank: currentRank, size: 14)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWriterName(theme, userId),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: isLong ? () => _showFullComment('댓글', content) : null,
                          child: Text(content, style: const TextStyle(fontSize: 13, color: Colors.black87), maxLines: isLong ? 2 : null, overflow: isLong ? TextOverflow.ellipsis : null),
                        ),
                        Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, size: 16),
                    onSelected: (value) async {
                      if (value == 'delete') await _deleteComment(commentId);
                      if (value == 'report' && writerId != null) await _openReportDialog(postId: widget.postId, commentId: commentId, reportedUserId: writerId, contentPreview: content);
                    },
                    itemBuilder: (_) => [
                      if (!isMyComment && writerId != null) const PopupMenuItem(value: 'report', child: Text('신고', style: TextStyle(color: Colors.red))),
                      if (canDelete) const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 아바타 빌더 (승완님 로직 유지)
  Widget _buildAvatar(String? userId) {
    if (userId == null) return CircleAvatar(radius: 16, backgroundColor: Colors.grey[300], child: const Icon(Icons.person, size: 20));
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) photoUrl = (snapshot.data!.data() as Map<String, dynamic>?)?['profileImageUrl'];
        return CircleAvatar(radius: 16, backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null, backgroundColor: Colors.grey[300], child: photoUrl == null ? const Icon(Icons.person, size: 20, color: Colors.white) : null);
      },
    );
  }

  // 작성자 이름 빌더 (승완님 로직 유지)
  Widget _buildWriterName(ThemeData theme, String? userId) {
    if (userId == null) return const Text('익명', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey));
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, userSnap) {
        String name = '익명';
        if (userSnap.hasData && userSnap.data!.exists) {
          name = (userSnap.data!.data() as Map<String, dynamic>?)?['koreanName'] ?? '익명';
        }
        return Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary));
      },
    );
  }

  // 프로필 다이얼로그 (승완님 로직 유지)
  void _showProfile(String userId) {
    showDialog(
      context: context,
      builder: (_) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          return UserProfileDialog(
            koreanName: data['koreanName'] ?? '이름 없음',
            photoUrl: data['profileImageUrl'],
            userId: userId,
            isMe: _currentUid == userId,
          );
        },
      ),
    );
  }

  void _showFullComment(String title, String content) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(title), content: SingleChildScrollView(child: Text(content)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기'))]));
  }
}