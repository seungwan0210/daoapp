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

class GuestbookCommentItem extends ConsumerStatefulWidget {
  final String writerId;
  final String message;
  final DateTime timestamp;
  final String docId;
  final String guestbookOwnerId;
  final String? monthlyBadge;
  final String? adminBadge;
  final int? currentRank; // 🆕 실시간 순위 파라미터 추가

  const GuestbookCommentItem({
    super.key,
    required this.writerId,
    required this.message,
    required this.timestamp,
    required this.docId,
    required this.guestbookOwnerId,
    this.monthlyBadge,
    this.adminBadge,
    this.currentRank, // 🆕 생성자 추가
  });

  @override
  ConsumerState<GuestbookCommentItem> createState() => _GuestbookCommentItemState();
}

class _GuestbookCommentItemState extends ConsumerState<GuestbookCommentItem> {
  @override
  Widget build(BuildContext context) {
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
          // === 작성자 아바타 ===
          GestureDetector(
            onTap: () => _showWriterProfile(context, widget.writerId),
            child: _buildAvatar(widget.writerId),
          ),
          const SizedBox(width: 12),

          // === 내용 + 시간 ===
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이름 + 배지 영역
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(widget.writerId).snapshots(),
                  builder: (context, snapshot) {
                    String name = 'Unknown';
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final userData = snapshot.data!.data() as Map<String, dynamic>;
                      name = userData['koreanName']?.toString().trim() ?? 'Unknown';
                    }

                    return Row(
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 6),

                        // 🔥 1. 실시간 랭킹 배지 (최우선)
                        if (widget.currentRank != null)
                          BadgeWidget(rank: widget.currentRank, size: 18),

                        const SizedBox(width: 4),

                        // 2. 월간 배지
                        if (widget.monthlyBadge != null)
                          Tooltip(
                            message: BadgeUtils.getBadgeTooltip(widget.monthlyBadge!),
                            child: BadgeWidget(badgeKey: widget.monthlyBadge, size: 18),
                          ),

                        const SizedBox(width: 2),

                        // 3. 관리자 배지
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

          // === 수정/삭제 메뉴 ===
          if (canEdit || canDelete)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
              onSelected: (value) async {
                if (value == 'edit' && canEdit) {
                  _showEditBottomSheet(context, widget.message);
                } else if (value == 'delete' && canDelete) {
                  await _deleteComment(context);
                }
              },
              itemBuilder: (_) => [
                if (canEdit) const PopupMenuItem(value: 'edit', child: Text('수정')),
                if (canDelete) const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(color: Colors.red))),
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

  void _showWriterProfile(BuildContext context, String writerId) {
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
            koreanName: data['koreanName'] ?? '이름 없음',
            englishName: data['englishName'],
            photoUrl: data['profileImageUrl'],
            shopName: data['shopName'],
            isMe: isMe,
            userId: writerId,
            // 배럴 정보 등은 UserProfileDialog 내부에서 처리하도록 구성됨
          );
        },
      ),
    );
  }

  // --- 수정 및 삭제 로직 (기존 유지) ---
  void _showEditBottomSheet(BuildContext context, String currentContent) {
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
            const Text('방명록 수정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소'))),
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
                    child: const Text('수정 완료'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteComment(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 방명록을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
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