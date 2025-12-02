// lib/presentation/screens/training/widgets/dao_tier_badge_large.dart
import 'package:flutter/material.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';

class DaoTierBadgeLarge extends StatelessWidget {
  final DaoTrainingTier tier;
  final bool showGlow;

  const DaoTierBadgeLarge({
    Key? key,
    required this.tier,
    this.showGlow = true,
  }) : super(key: key);

  /// 각 DAO 티어별 대표 색상 지정
  Color get color => switch (tier) {
    DaoTrainingTier.beginner   => Colors.grey,
    DaoTrainingTier.learner    => Colors.blueGrey,
    DaoTrainingTier.competitor => Colors.blue,
    DaoTrainingTier.challenger => Colors.green,
    DaoTrainingTier.elite      => Colors.orange,
    DaoTrainingTier.pro        => Colors.redAccent,
    DaoTrainingTier.master     => Colors.purpleAccent,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.35), color.withOpacity(0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.7), width: 3),
        boxShadow: showGlow
            ? [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 32,
            spreadRadius: 6,
            offset: const Offset(0, 6),
          ),
        ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 영문 티어명
          Text(
            tier.labelEn,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 4,
            ),
          ),

          const SizedBox(height: 6),

          /// 한글 티어명
          Text(
            tier.labelKo,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ],
      ),
    );
  }
}
