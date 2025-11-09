// lib/presentation/screens/community/circle/widgets/like_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LikeButton extends ConsumerWidget {
  final String postId;
  final String? currentUserId;

  const LikeButton({super.key, required this.postId, this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (currentUserId == null) {
      return IconButton(icon: const Icon(Icons.favorite_border), onPressed: null);
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
        return IconButton(
          icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : null, size: 26),
          onPressed: () => _toggleLike(isLiked),
        );
      },
    );
  }

  Future<void> _toggleLike(bool isLiked) async {
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