// lib/presentation/screens/community/circle/circle_preview.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CirclePreview extends StatelessWidget {
  final VoidCallback onSeeAllPressed;

  const CirclePreview({super.key, required this.onSeeAllPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // === 최근 게시물 ===
        _buildRecentPosts(context),

        const SizedBox(height: 12),

        // === 인기 게시물 ===
        _buildPopularPosts(context),
      ],
    );
  }

  // 최근 게시물
  Widget _buildRecentPosts(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 120);
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const SizedBox();
        }

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
                  return _buildPreviewItem(context, data, onSeeAllPressed);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // 인기 게시물
  Widget _buildPopularPosts(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community')
          .orderBy('likes', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 120);
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const SizedBox();
        }

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
                  final likes = data['likes'] as int? ?? 0;
                  return _buildPopularItem(context, data, likes, onSeeAllPressed);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // 미리보기 아이템 (클릭 → 전체 피드)
  Widget _buildPreviewItem(BuildContext context, Map<String, dynamic> data, VoidCallback onTap) {
    final photoUrl = data['photoUrl'] as String?;
    final likes = data['likes'] as int? ?? 0;
    final comments = data['comments'] as int? ?? 0;

    if (photoUrl == null || photoUrl.isEmpty) {
      return const SizedBox(width: 100);
    }

    return GestureDetector(
      onTap: onTap, // ← 클릭 시 전체 피드
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                width: 100,
                height: 100,
              ),
            ),
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

  // 인기 게시물 아이템 (클릭 → 전체 피드)
  Widget _buildPopularItem(BuildContext context, Map<String, dynamic> data, int likes, VoidCallback onTap) {
    final photoUrl = data['photoUrl'] as String?;

    if (photoUrl == null || photoUrl.isEmpty) {
      return const SizedBox(width: 100);
    }

    return GestureDetector(
      onTap: onTap, // ← 클릭 시 전체 피드
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                width: 100,
                height: 100,
              ),
            ),
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
                    Text('$likes', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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