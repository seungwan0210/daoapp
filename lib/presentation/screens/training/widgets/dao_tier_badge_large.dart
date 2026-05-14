// lib/presentation/screens/training/widgets/dao_tier_badge_large.dart
import 'package:flutter/material.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';

class DaoTierBadgeLarge extends StatelessWidget {
  final DaoTrainingTier tier;
  final bool showGlow;

  const DaoTierBadgeLarge({
    super.key, // super.key로 간결하게 수정
    required this.tier,
    this.showGlow = true,
  });

  /// 각 DAO 티어별 대표 색상 지정
  Color get color => switch (tier) {
    DaoTrainingTier.beginner   => const Color(0xFFFF8EC7),
    DaoTrainingTier.learner    => Colors.blueGrey,
    DaoTrainingTier.competitor => Colors.blue,
    DaoTrainingTier.challenger => Colors.green,
    DaoTrainingTier.elite      => Colors.orange,
    DaoTrainingTier.pro        => Colors.redAccent,
    DaoTrainingTier.master     => Colors.purpleAccent,
  };

  /// 🔹 현재 언어 설정에 맞는 티어 라벨을 가져오는 헬퍼
  String _getLocalizedLabel(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final String langCode = locale.languageCode;
    final String? scriptCode = locale.scriptCode;

    if (langCode == 'ja') return tier.labelJa;
    if (langCode == 'en') return tier.labelEn;
    if (langCode == 'zh') {
      return (scriptCode == 'Hant') ? tier.labelZhHant : tier.labelZhHans;
    }
    return tier.labelKo; // 기본값 한국어
  }

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
          /// 🔹 영문 티어명 (디자인 아이덴티티를 위해 영문은 항상 노출)
          Text(
            tier.labelEn.toUpperCase(), // 대문자로 강조
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 4,
            ),
          ),

          const SizedBox(height: 6),

          /// 🔹 현지화된 티어명 (사용자 언어 설정에 맞게 변경)
          Text(
            _getLocalizedLabel(context),
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