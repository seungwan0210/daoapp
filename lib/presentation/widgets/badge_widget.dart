// lib/presentation/widgets/badge_widget.dart
import 'package:flutter/material.dart';
import 'package:daoapp/core/constants/badge_constants.dart';

class BadgeWidget extends StatelessWidget {
  final int? rank;         // 실시간 등수 (1~10)
  final String? badgeKey;  // 특정 배지 키 (admin_pro, monthly_ 등)
  final double size;

  const BadgeWidget({
    super.key,
    this.rank,
    this.badgeKey,
    this.size = 26, // RankingListItem 기준 기본 사이즈
  });

  @override
  Widget build(BuildContext context) {
    String? effectiveKey;

    // 1. rank가 들어온 경우: 실시간 순위 배지 결정 (최우선순위)
    if (rank != null && rank! >= 1 && rank! <= 10) {
      effectiveKey = BadgeConstants.badgeKeyForRank(rank!);
    }
    // 2. rank는 없지만 badgeKey가 직접 들어온 경우 (어드민/보유 배지)
    else if (badgeKey != null) {
      effectiveKey = badgeKey;
    }

    // 최종적으로 보여줄 배지 키가 없으면 아무것도 안 그림
    if (effectiveKey == null) return const SizedBox.shrink();

    final imagePath = BadgeConstants.getImagePath(effectiveKey);

    if (imagePath == null) {
      return const SizedBox.shrink();
    }

    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: BoxFit.contain, // 배지 모양이 찌그러지지 않게 contain 권장
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}