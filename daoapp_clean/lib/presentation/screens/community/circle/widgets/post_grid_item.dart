// lib/presentation/screens/community/circle/widgets/post_grid_item.dart
import 'package:flutter/material.dart';

class PostGridItem extends StatelessWidget {
  final String photoUrl;
  final VoidCallback onTap;

  const PostGridItem({
    super.key,
    required this.photoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.network(photoUrl, fit: BoxFit.cover),
    );
  }
}