// lib/presentation/widgets/guestbook_comment_item.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/user_profile_dialog.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/utils/badge_utils.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class GuestbookCommentItem extends ConsumerStatefulWidget {
  final String writerId;
  final String message;
  final DateTime timestamp;
  final String docId;
  final String guestbookOwnerId;
  final String? monthlyBadge;
  final String? adminBadge;
  final int? currentRank;

  const GuestbookCommentItem({
    super.key,
    required this.writerId,
    required this.message,
    required this.timestamp,
    required this.docId,
    required this.guestbookOwnerId,
    this.monthlyBadge,
    this.adminBadge,
    this.currentRank,
  });

  @override
  ConsumerState<GuestbookCommentItem> createState() => _GuestbookCommentItemState();
}

class _GuestbookCommentItemState extends ConsumerState<GuestbookCommentItem> {
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isAdminAsync = ref.watch(isAdminProvider);
    final isAdmin = isAdminAsync.when(data: (v) => v, loading: () => false, error: (_, __) => false);

    final bool isMyComment = widget.writerId.isNotEmpty && widget.writerId == currentUserId;
    final bool isMyGuestbook = widget.guestbookOwnerId == currentUserId;
    final bool canEdit = isMyComment || isAdmin;
    final bool canDelete = isMyComment || isMyGuestbook || isAdmin;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showWriterProfile(context, widget.writerId, s),
            child: _buildAvatar(widget.writerId),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(widget.writerId).snapshots(),
                  builder: (context, snapshot) {
                    String name = s.guestbook_unknown_user; // 🔹 다국어 적용
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final userData = snapshot.data!.data() as Map<String, dynamic>;
                      name = userData['koreanName']?.toString().trim() ?? s.guestbook_unknown_user;
                    }

                    return Row(
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 6),
                        if (widget.currentRank != null)
                          BadgeWidget(rank: widget.currentRank, size: 18),
                        const SizedBox(width: 4),
                        if (widget.monthlyBadge != null)
                          Tooltip(
                            message: BadgeUtils.getBadgeTooltip(widget.monthlyBadge!),
                            child: BadgeWidget(badgeKey: widget.monthlyBadge, size: 18),
                          ),
                        const SizedBox(width: 2),
                        if (widget.adminBadge != null)
                          Tooltip(
                            message: BadgeUtils.getBadgeTooltip(widget.adminBadge!),
                            child: BadgeWidget(badgeKey: widget.adminBadge, size: 18),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  widget.message,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 6),
                Text(
                  AppDateUtils.formatRelativeTime(widget.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (canEdit || canDelete)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
              onSelected: (value) async {
                if (value == 'edit' && canEdit) {
                  _showEditBottomSheet(context, widget.message, s);
                } else if (value == 'delete' && canDelete) {
                  await _deleteComment(context, s);
                }
              },
              itemBuilder: (_) => [
                if (canEdit) PopupMenuItem(value: 'edit', child: Text(s.guestbook_menu_edit)), // 🔹 다국어 적용
                if (canDelete) PopupMenuItem(value: 'delete', child: Text(s.guestbook_menu_delete, style: const TextStyle(color: Colors.red))), // 🔹 다국어 적용
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String writerId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(writerId).snapshots(),
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          photoUrl = data['profileImageUrl'] as String?;
        }
        return CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[200],
          backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
          child: photoUrl?.isNotEmpty != true ? const Icon(Icons.person, size: 24, color: Colors.grey) : null,
        );
      },
    );
  }

  void _showWriterProfile(BuildContext context, String writerId, AppLocalizations s) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = currentUid == writerId;

    showDialog(
      context: context,
      builder: (_) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(writerId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

          return UserProfileDialog(
            koreanName: data['koreanName'] ?? s.guestbook_unknown_user,
            englishName: data['englishName'],
            photoUrl: data['profileImageUrl'],
            shopName: data['shopName'],
            isMe: isMe,
            userId: writerId,
          );
        },
      ),
    );
  }

  void _showEditBottomSheet(BuildContext context, String currentContent, AppLocalizations s) {
    final controller = TextEditingController(text: currentContent);
    final focusNode = FocusNode();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.guestbook_edit_title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // 🔹 다국어 적용
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.common_cancel))),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (controller.text.trim().isEmpty) return;
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.guestbookOwnerId)
                          .collection('guestbook')
                          .doc(widget.docId)
                          .update({'message': controller.text.trim()});
                      if (mounted) Navigator.pop(ctx);
                    },
                    child: Text(s.guestbook_edit_complete), // 🔹 다국어 적용
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteComment(BuildContext context, AppLocalizations s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.guestbook_delete_confirm_title), // 🔹 다국어 적용
        content: Text(s.guestbook_delete_confirm_body), // 🔹 다국어 적용
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.common_cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.guestbook_menu_delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.guestbookOwnerId)
        .collection('guestbook')
        .doc(widget.docId)
        .delete();
  }
}