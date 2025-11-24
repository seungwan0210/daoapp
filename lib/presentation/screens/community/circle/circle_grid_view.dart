// lib/presentation/screens/community/circle/circle_grid_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/post_grid_item.dart';

class CircleGridView extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final void Function(String) onItemTap;

  const CircleGridView({
    super.key,
    required this.docs,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const ValueKey('grid'),
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemCount: docs.length,
      itemBuilder: (_, i) {
        final data = docs[i].data() as Map<String, dynamic>;
        final postId = docs[i].id;

        // 1) 새 방식: imageUrls 배열
        final List<dynamic>? images = data['imageUrls'] as List<dynamic>?;
        String? photoUrl;
        if (images != null && images.isNotEmpty) {
          photoUrl = images.first as String;
        } else {
          // 2) 예전 방식: photoUrl 단일 필드
          photoUrl = data['photoUrl'] as String?;
        }

        if (photoUrl == null || photoUrl.isEmpty) {
          return const SizedBox.shrink();
        }

        return PostGridItem(
          photoUrl: photoUrl,
          onTap: () => onItemTap(postId),
        );
      },
    );
  }
}
