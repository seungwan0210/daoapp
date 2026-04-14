// lib/presentation/screens/community/circle/widgets/like_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LikeButton extends ConsumerStatefulWidget {
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
  ConsumerState<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<LikeButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final uid = widget.currentUserId;

    if (uid == null) {
      return _buildLikeRow(context, false, widget.likesCount);
    }

    final likeDocStream = FirebaseFirestore.instance
        .collection('community')
        .doc(widget.postId)
        .collection('likes')
        .doc(uid)
        .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: likeDocStream,
      builder: (context, snapshot) {
        final isLiked = snapshot.data?.exists ?? false;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _busy ? null : () => _toggleLike(uid: uid, isLiked: isLiked),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: _buildLikeRow(context, isLiked, widget.likesCount),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLikeRow(BuildContext context, bool isLiked, int count) {
    final iconColor = isLiked ? Colors.red : Colors.grey[600];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          color: iconColor,
          size: 24,
        ),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: iconColor,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _toggleLike({
    required String uid,
    required bool isLiked,
  }) async {
    setState(() => _busy = true);

    try {
      final postRef =
      FirebaseFirestore.instance.collection('community').doc(widget.postId);
      final likeRef = postRef.collection('likes').doc(uid);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        if (isLiked) {
          tx.delete(likeRef);
          tx.update(postRef, {'likes': FieldValue.increment(-1)});
        } else {
          tx.set(likeRef, {'timestamp': FieldValue.serverTimestamp()});
          tx.update(postRef, {'likes': FieldValue.increment(1)});
        }
      });
    } catch (e) {
      // 필요하면 스낵바 추가 가능
      debugPrint('toggleLike error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
