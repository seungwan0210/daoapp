// lib/presentation/screens/community/circle/widgets/comment_preview.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/user_profile_dialog.dart';
import 'comment_bottom_sheet.dart';

class CommentPreview extends StatelessWidget {
  final String postId;
  final String? currentUserId;

  const CommentPreview({
    super.key,
    required this.postId,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community')
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final writerId = data['userId'] as String?;
              final content = data['content'] as String? ?? '';

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
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                          children: [
                            WidgetSpan(
                              child: writerId != null
                                  ? FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(writerId)
                                    .get(),
                                builder: (context, snapshot) {
                                  String name = '익명';
                                  if (snapshot.hasData && snapshot.data!.exists) {
                                    name = snapshot.data!['koreanName']?.toString().trim() ?? '익명';
                                  }
                                  return GestureDetector(
                                    onTap: writerId != null ? () => _showProfile(context, writerId) : null,
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            if (docs.length >= 3)
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

  Widget _buildAvatar(String? userId) {
    if (userId == null) {
      return const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 16));
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          photoUrl = snapshot.data!['profileImageUrl'] as String?;
        }
        return CircleAvatar(
          radius: 12,
          backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
          child: photoUrl?.isNotEmpty != true
              ? const Icon(Icons.person, size: 16, color: Colors.grey)
              : null,
        );
      },
    );
  }

  void _showProfile(BuildContext context, String userId) {
    final isMe = currentUserId == userId;

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