// lib/presentation/widgets/badge_widget.dart
import 'package:flutter/material.dart';
import 'package:daoapp/core/constants/badge_constants.dart';

class BadgeWidget extends StatelessWidget {
  final String badgeKey;
  final double size; // 추가!

  const BadgeWidget({
    super.key,
    required this.badgeKey,
    this.size = 40, // 기본값
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = BadgeConstants.fromKey(badgeKey);
    if (imagePath == null) return const SizedBox.shrink();

    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.error, size: 20),
    );
  }
}