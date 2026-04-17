// lib/core/constants/badge_constants.dart
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

  /// ✅ [수정완료] RankingListItem의 badgeImages 순서와 100% 일치시킴
  /// 1: pro, 2: diamond, 3: emerald, 4: platinum1, 5: platinum2...
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
}