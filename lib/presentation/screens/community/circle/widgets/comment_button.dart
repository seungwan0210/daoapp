// lib/presentation/screens/community/circle/widgets/comment_button.dart
import 'package:flutter/material.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/comment_bottom_sheet.dart';

class CommentButton extends StatelessWidget {
  final String postId;
  final int commentsCount;

  const CommentButton({
    super.key,
    required this.postId,
    required this.commentsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => CommentBottomSheet.show(context, postId),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline, size: 24, color: Colors.black87),
              if (commentsCount > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '$commentsCount',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
