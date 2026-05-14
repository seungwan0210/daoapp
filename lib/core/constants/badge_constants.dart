import 'package:daoapp/l10n/app_localizations.dart';

class BadgeConstants {
  static const Map<String, String> _badgeMap = {
    'pro': 'assets/badges/pro.png',          // 1위
    'diamond': 'assets/badges/diamond.png',  // 2위
    'emerald': 'assets/badges/emerald.png',  // 3위
    'platinum1': 'assets/badges/platinum1.png', // 4위
    'platinum2': 'assets/badges/platinum2.png', // 5위
    'gold1': 'assets/badges/gold1.png',      // 6위
    'gold2': 'assets/badges/gold2.png',      // 7위
    'silver1': 'assets/badges/silver1.png',  // 8위
    'silver2': 'assets/badges/silver2.png',  // 9위
    'bronze1': 'assets/badges/bronze1.png',  // 10위
    'bronze2': 'assets/badges/bronze2.png',
    'bronze3': 'assets/badges/bronze3.png',
    'tro': 'assets/badges/tro.png',

    'season':  'assets/badges/season.png',
    'season1': 'assets/badges/season1.png',
    'season2': 'assets/badges/season2.png',
    'season3': 'assets/badges/season3.png',
  };

  static List<String> get allBadges => _badgeMap.keys.toList();

  static String? getImagePath(String key) {
    if (key.startsWith('monthly_')) {
      final parts = key.split('_');
      if (parts.length >= 4) {
        final badgeKey = parts.last;
        return _badgeMap[badgeKey];
      }
      return null;
    }

    if (key.startsWith('admin_')) {
      final badgeKey = key.substring('admin_'.length);
      return _badgeMap[badgeKey];
    }

    return _badgeMap[key];
  }

  static String? fromKey(String key) => getImagePath(key);

  /// ✅ 랭킹 순서에 따른 배지 키값 반환
  static String? badgeKeyForRank(int rank) {
    switch (rank) {
      case 1: return 'pro';
      case 2: return 'diamond';
      case 3: return 'emerald';
      case 4: return 'platinum1';
      case 5: return 'platinum2';
      case 6: return 'gold1';
      case 7: return 'gold2';
      case 8: return 'silver1';
      case 9: return 'silver2';
      case 10: return 'bronze1';
      default: return null;
    }
  }

  /// ✅ [l10n 적용을 위한 헬퍼] 배지 키값으로 번역된 이름을 가져오는 로직
  /// UI에서 l10n.badge_name_pro 대신 BadgeConstants.getBadgeName(l10n, key) 형태로 사용 가능합니다.
  static String getBadgeName(AppLocalizations l10n, String key) {
    switch (key) {
      case 'pro': return l10n.badge_name_pro;
      case 'emerald': return l10n.badge_name_emerald;
      case 'diamond': return l10n.badge_name_diamond;
      case 'platinum': return l10n.badge_name_platinum;
      case 'platinum1': return l10n.badge_name_platinum1;
      case 'platinum2': return l10n.badge_name_platinum2;
      case 'gold': return l10n.badge_name_gold;
      case 'gold1': return l10n.badge_name_gold1;
      case 'gold2': return l10n.badge_name_gold2;
      case 'silver': return l10n.badge_name_silver;
      case 'silver1': return l10n.badge_name_silver1;
      case 'silver2': return l10n.badge_name_silver2;
      case 'bronze': return l10n.badge_name_bronze;
      case 'bronze1': return l10n.badge_name_bronze1;
      case 'bronze2': return l10n.badge_name_bronze2;
      case 'bronze3': return l10n.badge_name_bronze3;
      case 'tro': return l10n.badge_name_trophy;
      case 'season': return l10n.badge_name_season_general;
      case 'season1': return l10n.badge_name_season_rank1;
      case 'season2': return l10n.badge_name_season_rank2;
      case 'season3': return l10n.badge_name_season_rank3;
      default: return l10n.badge_name_monthly;
    }
  }
}