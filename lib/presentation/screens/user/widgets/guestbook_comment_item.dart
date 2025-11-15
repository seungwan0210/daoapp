// lib/presentation/widgets/guestbook_comment_item.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/user_profile_dialog.dart';

class GuestbookCommentItem extends ConsumerStatefulWidget {
  final String writerId;           // 유지
  // final String writerName;      ← 완전 삭제!
  final String message;
  final DateTime timestamp;
  final String docId;
  final String guestbookOwnerId;

  const GuestbookCommentItem({
    super.key,
    required this.writerId,
    // required this.writerName,  ← 삭제
    required this.message,
    required this.timestamp,
    required this.docId,
    required this.guestbookOwnerId,
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
                // 실시간 이름 조회 (FutureBuilder)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.writerId)
                      .get(),
                  builder: (context, snapshot) {
                    String name = 'Unknown';
                    if (snapshot.hasData && snapshot.data!.exists) {
                      name = snapshot.data!['koreanName']?.toString().trim() ?? 'Unknown';
                    }
                    return Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  widget.message,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
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
              icon: const Icon(Icons.more_horiz, size: 18),
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

  // === 아바타 ===
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
          backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
          child: photoUrl?.isNotEmpty != true ? const Icon(Icons.person, size: 24) : null,
        );
      },
    );
  }

  // === 프로필 다이얼로그 ===
  void _showWriterProfile(BuildContext context, String writerId) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = currentUid == writerId;

    showDialog(
      context: context,
      builder: (_) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(writerId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          if (!snapshot.data!.exists || snapshot.data!.data() == null) {
            return UserProfileDialog(koreanName: '프로필 없음', isMe: isMe, userId: writerId);
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final hasProfile = data['hasProfile'] == true;
          if (!hasProfile) {
            return UserProfileDialog(koreanName: '프로필 미완료', isMe: isMe, userId: writerId);
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
            userId: writerId,
          );
        },
      ),
    );
  }

  // === 수정 바텀시트 ===
  void _showEditBottomSheet(BuildContext context, String currentContent) {
    final controller = TextEditingController(text: currentContent);
    final focusNode = FocusNode();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final mediaQuery = MediaQuery.of(context);
        final bottomInset = mediaQuery.viewInsets.bottom;
        final screenHeight = mediaQuery.size.height;
        final targetHeight = screenHeight * 0.8;

        return Container(
          height: targetHeight + bottomInset,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: bottomInset + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const Text(
                  '방명록 수정',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    maxLines: null,
                    minLines: 4,
                    decoration: InputDecoration(
                      hintText: '수정할 내용을 입력하세요...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('취소', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final newText = controller.text.trim();
                          if (newText.isEmpty || newText == currentContent) {
                            Navigator.pop(ctx);
                            return;
                          }

                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.guestbookOwnerId)
                                .collection('guestbook')
                                .doc(widget.docId)
                                .update({'message': newText});

                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('수정되었습니다'), duration: Duration(seconds: 1)),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              print("방명록 수정 실패: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('수정 실패: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        child: const Text('수정 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      controller.dispose();
      focusNode.dispose();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) focusNode.requestFocus();
    });
  }

  // === 삭제 ===
  Future<void> _deleteComment(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 방명록을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.guestbookOwnerId)
          .collection('guestbook')
          .doc(widget.docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제되었습니다'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        print("방명록 삭제 실패: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }
}