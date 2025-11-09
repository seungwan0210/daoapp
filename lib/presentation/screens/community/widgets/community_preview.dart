// lib/presentation/screens/community/widgets/community_preview.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class CommunityPreview extends StatelessWidget {
  final VoidCallback onSeeAllPressed;

  const CommunityPreview({super.key, required this.onSeeAllPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRecentPosts(context),
        const SizedBox(height: 12),
        _buildPopularPosts(context),
      ],
    );
  }

  Widget _buildRecentPosts(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 120);
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const SizedBox();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '최근 게시물',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: onSeeAllPressed,
                    child: const Text('전체 보기'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final postId = docs[i].id;
                  return _buildPreviewItem(context, data, postId);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPopularPosts(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community')
          .orderBy('likes', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 120);
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '인기 게시물',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final postId = docs[i].id;
                  final likes = data['likes'] as int? ?? 0;
                  return _buildPopularItem(context, data, postId, likes);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewItem(BuildContext context, Map<String, dynamic> data, String postId) {
    final photoUrl = data['photoUrl'] as String?;
    final likes = data['likes'] as int? ?? 0;
    final comments = data['comments'] as int? ?? 0;

    if (photoUrl == null || photoUrl.isEmpty) return const SizedBox(width: 100);

    return GestureDetector(
      onTap: () {
        if (!context.mounted) return;
        Navigator.pushNamed(
          context,
          RouteConstants.circle,
          arguments: postId,
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Stack(
          children: [
            // 사진
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                width: 100,
                height: 100,
              ),
            ),

            // 좋아요 + 댓글
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 12),
                    const SizedBox(width: 2),
                    Text('$likes', style: const TextStyle(color: Colors.white, fontSize: 10)),
                    const SizedBox(width: 6),
                    const Icon(Icons.comment, color: Colors.white, size: 12),
                    const SizedBox(width: 2),
                    Text('$comments', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularItem(BuildContext context, Map<String, dynamic> data, String postId, int likes) {
    final photoUrl = data['photoUrl'] as String?;

    if (photoUrl == null || photoUrl.isEmpty) return const SizedBox(width: 100);

    return GestureDetector(
      onTap: () {
        if (!context.mounted) return;
        Navigator.pushNamed(
          context,
          RouteConstants.circle,
          arguments: postId,
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Stack(
          children: [
            // 사진
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                width: 100,
                height: 100,
              ),
            ),

            // 좋아요 수
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      '$likes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}