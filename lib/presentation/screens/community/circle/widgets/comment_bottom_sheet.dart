// lib/presentation/screens/community/circle/widgets/comment_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/user_profile_dialog.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

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

  String? _writerIdFrom(Map<String, dynamic> data) {
    return (data['writerId'] as String?) ?? (data['userId'] as String?);
  }

  Future<void> _reportComment({
    required String postId,
    required String commentId,
    required String reportedUserId,
    required String reason,
    required AppLocalizations s,
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.comment_report_success)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.comment_report_fail(e.toString()))));
    }
  }

  Future<void> _openReportDialog({
    required String postId,
    required String commentId,
    required String reportedUserId,
    required String contentPreview,
    required AppLocalizations s,
  }) async {
    final reasons = <String>[s.post_card_report_r1, s.post_card_report_r2, s.post_card_report_r3, s.post_card_report_r4, s.post_card_report_r5, s.post_card_report_r6];
    String selected = reasons.first;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(s.comment_report_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(alignment: Alignment.centerLeft, child: Text(s.comment_report_select_reason)),
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
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.common_cancel)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.post_card_report, style: const TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
    if (result == true) {
      await _reportComment(postId: postId, commentId: commentId, reportedUserId: reportedUserId, reason: selected, contentPreview: contentPreview, s: s);
    }
  }

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

  Future<void> _deleteComment(String commentId, AppLocalizations s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.comment_delete_title),
        content: Text(s.comment_delete_body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.common_cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.common_delete, style: const TextStyle(color: Colors.red))),
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
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final blockedIds = ref.watch(blockedUserIdsProvider).value ?? {};
    final isAdmin = ref.watch(isAdminProvider).when(data: (v) => v, loading: () => false, error: (_, __) => false);

    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(s.comment_title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const Divider(height: 1),
        Expanded(child: _buildCommentsList(theme: theme, isAdmin: isAdmin, currentUserId: _currentUid, blockedIds: blockedIds, s: s)),
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
                  decoration: InputDecoration(hintText: s.comment_hint, border: InputBorder.none),
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
    required AppLocalizations s,
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
        if (docs.isEmpty) return Center(child: Text(s.comment_empty));

        final filteredDocs = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final String? writerId = _writerIdFrom(data);
          return writerId == null || !blockedIds.contains(writerId.trim());
        }).toList();

        if (filteredDocs.isEmpty) return Center(child: Text(s.comment_no_visible));

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
            final timeStr = timestamp != null ? AppDateUtils.formatRelativeTime(timestamp.toDate()) : s.comment_time_just_now;

            final isMyComment = writerId != null && writerId == currentUserId;
            final canDelete = isMyComment || isAdmin;
            final isLong = content.length > 80 || content.contains('\n');

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
                      GestureDetector(onTap: userId != null ? () => _showProfile(userId, s) : null, child: _buildAvatar(userId)),
                      if (currentRank != null)
                        Positioned(left: -4, top: -4, child: BadgeWidget(rank: currentRank, size: 14)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWriterName(theme, userId, s),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: isLong ? () => _showFullComment(s.comment_title, content, s) : null,
                          child: Text(content, style: const TextStyle(fontSize: 13, color: Colors.black87), maxLines: isLong ? 2 : null, overflow: isLong ? TextOverflow.ellipsis : null),
                        ),
                        Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, size: 16),
                    onSelected: (value) async {
                      if (value == 'delete') await _deleteComment(commentId, s);
                      if (value == 'report' && writerId != null) await _openReportDialog(postId: widget.postId, commentId: commentId, reportedUserId: writerId, contentPreview: content, s: s);
                    },
                    itemBuilder: (_) => [
                      if (!isMyComment && writerId != null) PopupMenuItem(value: 'report', child: Text(s.post_card_report, style: const TextStyle(color: Colors.red))),
                      if (canDelete) PopupMenuItem(value: 'delete', child: Text(s.common_delete, style: const TextStyle(color: Colors.red))),
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

  Widget _buildWriterName(ThemeData theme, String? userId, AppLocalizations s) {
    if (userId == null) return Text(s.common_anonymous, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey));
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, userSnap) {
        String name = s.common_anonymous;
        if (userSnap.hasData && userSnap.data!.exists) {
          name = (userSnap.data!.data() as Map<String, dynamic>?)?['koreanName'] ?? s.common_anonymous;
        }
        return Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary));
      },
    );
  }

  void _showProfile(String userId, AppLocalizations s) {
    showDialog(
      context: context,
      builder: (_) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          return UserProfileDialog(
            koreanName: data['koreanName'] ?? s.member_list_no_name,
            photoUrl: data['profileImageUrl'],
            userId: userId,
            isMe: _currentUid == userId,
          );
        },
      ),
    );
  }

  void _showFullComment(String title, String content, AppLocalizations s) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(title), content: SingleChildScrollView(child: Text(content)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.common_cancel.replaceAll('취소', '닫기')))]));
  }
}