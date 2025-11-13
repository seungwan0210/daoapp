// lib/presentation/screens/community/circle/widgets/like_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LikeButton extends ConsumerWidget {
  final String postId;
  final String? currentUserId;
  final int likesCount;

  const LikeButton({
    super.key,
    required this.postId,
    this.currentUserId,
    required this.likesCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (currentUserId == null) {
      return _buildLikeRow(context, false, likesCount);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community')
          .doc(postId)
          .collection('likes')
          .doc(currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        final isLiked = snapshot.data?.exists ?? false;
        return GestureDetector(
          onTap: () => _toggleLike(ref, isLiked),
          child: _buildLikeRow(context, isLiked, likesCount), // context 전달!
        );
      },
    );
  }

  // context 파라미터 추가!
  Widget _buildLikeRow(BuildContext context, bool isLiked, int count) {
    return Row(
      children: [
        Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? Colors.red : Colors.grey[600], // 빨강 고정
          size: 24,
        ),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isLiked ? Colors.red : Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _toggleLike(WidgetRef ref, bool isLiked) async {
    final likeRef = FirebaseFirestore.instance
        .collection('community')
        .doc(postId)
        .collection('likes')
        .doc(currentUserId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final postDoc = await transaction.get(FirebaseFirestore.instance.collection('community').doc(postId));
      final currentLikes = postDoc.data()?['likes'] ?? 0;

      if (isLiked) {
        transaction.delete(likeRef);
        transaction.update(FirebaseFirestore.instance.collection('community').doc(postId), {'likes': currentLikes - 1});
      } else {
        transaction.set(likeRef, {'timestamp': FieldValue.serverTimestamp()});
        transaction.update(FirebaseFirestore.instance.collection('community').doc(postId), {'likes': currentLikes + 1});
      }
    });
  }
}