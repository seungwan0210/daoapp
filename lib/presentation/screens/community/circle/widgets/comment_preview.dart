import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/user_profile_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'comment_bottom_sheet.dart';

class CommentPreview extends StatelessWidget {
  final String postId;
  final String? currentUserId;

  const CommentPreview({
    super.key,
    required this.postId,
    this.currentUserId,
  });

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Stream<Set<String>> _blockedIdsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('blockedUsers')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  String? _writerIdFrom(Map<String, dynamic> data) {
    // ✅ writerId 우선, 없으면 userId fallback
    return (data['writerId'] as String?) ?? (data['userId'] as String?);
  }

  bool _isBlockedWriter(Map<String, dynamic> data, Set<String> blockedIds) {
    final writerId = _writerIdFrom(data);
    if (writerId == null || writerId.trim().isEmpty) return false;
    return blockedIds.contains(writerId.trim());
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    // ✅ 로그인/uid 없으면(원칙상 커뮤니티는 로그인 후 이용이지만)
    // 안전하게 차단 필터 없이 기존 방식으로 렌더
    if (uid == null) {
      return _buildCommentPreviewBody(context, const <String>{});
    }

    return StreamBuilder<Set<String>>(
      stream: _blockedIdsStream(uid),
      builder: (context, snap) {
        final blockedIds = snap.data ?? <String>{};
        return _buildCommentPreviewBody(context, blockedIds);
      },
    );
  }

  Widget _buildCommentPreviewBody(BuildContext context, Set<String> blockedIds) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community')
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .limit(8) // ✅ 차단 필터로 빠질 수 있으니 조금 넉넉히
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final allDocs = snapshot.data!.docs;

        // ✅ 차단 유저 댓글 제거
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return !_isBlockedWriter(data, blockedIds);
        }).toList();

        if (filteredDocs.isEmpty) return const SizedBox.shrink();

        // ✅ 프리뷰는 최대 3개만
        final previewDocs = filteredDocs.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...previewDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              final String? writerId = _writerIdFrom(data);
              final content = (data['content'] as String?) ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: writerId != null ? () => _showProfile(context, writerId) : null,
                      child: _buildAvatar(writerId),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          children: [
                            WidgetSpan(
                              child: writerId != null
                                  ? FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(writerId)
                                    .get(),
                                builder: (context, userSnapshot) {
                                  String name = '익명';
                                  if (userSnapshot.hasData &&
                                      userSnapshot.data!.exists) {
                                    final userData = userSnapshot.data!.data()
                                    as Map<String, dynamic>?;
                                    name = userData?['koreanName']
                                        ?.toString()
                                        .trim() ??
                                        '익명';
                                  }
                                  return GestureDetector(
                                    onTap: () => _showProfile(context, writerId),
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              )
                                  : const Text(
                                '익명',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const WidgetSpan(child: SizedBox(width: 4)),
                            TextSpan(text: content),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            // ✅ "댓글 모두 보기"는 차단 제외 후에도 3개 이상일 때만
            if (filteredDocs.length >= 3)
              TextButton(
                onPressed: () => CommentBottomSheet.show(context, postId),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '댓글 모두 보기',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // 완전 안전한 아바타
  Widget _buildAvatar(String? userId) {
    if (userId == null) {
      return CircleAvatar(
        radius: 12,
        backgroundColor: Colors.grey[300],
        child: const Icon(Icons.person, size: 16, color: Colors.grey),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          photoUrl = data?['profileImageUrl'] as String?;
        }

        return CircleAvatar(
          radius: 12,
          backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
          backgroundColor: photoUrl?.isNotEmpty != true ? Colors.grey[300] : null,
          child: photoUrl?.isNotEmpty != true
              ? const Icon(Icons.person, size: 16, color: Colors.white)
              : null,
        );
      },
    );
  }

  // 프로필 다이얼로그
  void _showProfile(BuildContext context, String userId) {
    final isMe = currentUserId == userId;

    showDialog(
      context: context,
      builder: (_) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
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

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
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
          final String? photoUrl = data['profileImageUrl'] as String?;
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
