// lib/presentation/widgets/badge_widget.dart
import 'package:flutter/material.dart';
import 'package:daoapp/core/constants/badge_constants.dart';

class BadgeWidget extends StatelessWidget {
  final String badgeKey;
  final double size;

  const BadgeWidget({
    super.key,
    required this.badgeKey,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = BadgeConstants.fromKey(badgeKey);
    if (imagePath == null) {
      // 디버그용: 배지 키는 있는데 이미지가 없을 때
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.warning_amber_rounded, size: 20, color: Colors.red),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4), // 부드러운 둥근 모서리
      child: Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover, // 꽉 채우기
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
          );
        },
      ),
    );
  }
}