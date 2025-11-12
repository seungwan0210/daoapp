// lib/presentation/widgets/post_item_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/widgets/admin_delete_button.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';

class PostItemWidget extends ConsumerWidget {
  final String title;
  final String content;
  final String authorName;
  final DateTime timestamp;
  final String postId;
  final String collectionPath;
  final String authorId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const PostItemWidget({
    super.key,
    required this.title,
    required this.content,
    required this.authorName,
    required this.timestamp,
    required this.postId,
    required this.collectionPath,
    required this.authorId,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authStateProvider).value;
    final isAuthor = authorId == currentUser?.uid;

    // 권한 체크 수정
    final isAdmin = ref.watch(isAdminProvider).when(
      data: (v) => v,
      loading: () => false,
      error: (_, __) => false,
    );
    final canEdit = isAuthor && onEdit != null;
    final canDelete = isAuthor || isAdmin; // 수정: onDelete null 체크 제거

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  authorName,
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                ),
                const Spacer(),
                Text(
                  AppDateUtils.formatRelativeTime(timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 수정 버튼 (본인만)
            if (canEdit)
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEdit,
              ),
            // 삭제 버튼 (본인 OR 관리자)
            if (canDelete)
              AdminDeleteButton(
                collectionPath: collectionPath,
                docId: postId,
                onDeleted: isAuthor ? onDelete : null,
              ),
          ],
        ),
      ),
    );
  }
}