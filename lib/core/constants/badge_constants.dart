// lib/core/constants/badge_constants.dart
class BadgeConstants {
  static const Map<String, String> _badgeMap = {
    'pro': 'assets/badges/pro.png',
    'emerald': 'assets/badges/emerald.png',
    'diamond': 'assets/badges/diamond.png',
    'platinum1': 'assets/badges/platinum1.png',
    'platinum2': 'assets/badges/platinum2.png',
    'gold1': 'assets/badges/gold1.png',
    'gold2': 'assets/badges/gold2.png',
    'silver1': 'assets/badges/silver1.png',
    'silver2': 'assets/badges/silver2.png',
    'bronze1': 'assets/badges/bronze1.png',
    'bronze2': 'assets/badges/bronze2.png',
    'bronze3': 'assets/badges/bronze3.png',
    'tro': 'assets/badges/tro.png',
  };

  /// 모든 배지 키 리스트 제공 (관리자 수동 지정 등에 사용)
  static List<String> get allBadges => _badgeMap.keys.toList();

  /// Firestore에 저장된 badges 맵의 key → 실제 이미지 경로
  /// - monthly_YYYY_MM_badgeKey
  /// - admin_badgeKey
  /// - 그 외: badgeKey 자체
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

  /// ✅ 랭킹 순위(1~12) → 배지 키 매핑
  /// Cloud Functions BADGE_MAP 과 동일하게 맞춤
  ///
  ///  1위 → pro
  ///  2위 → emerald
  ///  3위 → diamond
  ///  4위 → platinum1
  ///  5위 → platinum2
  ///  6위 → gold1
  ///  7위 → gold2
  ///  8위 → silver1
  ///  9위 → silver2
  /// 10위 → bronze1
  /// 11위 → bronze2
  /// 12위 → bronze3
  static String? badgeKeyForRank(int rank) {
    switch (rank) {
      case 1:
        return 'pro';
      case 2:
        return 'emerald';
      case 3:
        return 'diamond';
      case 4:
        return 'platinum1';
      case 5:
        return 'platinum2';
      case 6:
        return 'gold1';
      case 7:
        return 'gold2';
      case 8:
        return 'silver1';
      case 9:
        return 'silver2';
      case 10:
        return 'bronze1';
      case 11:
        return 'bronze2';
      case 12:
        return 'bronze3';
      default:
        return null; // 13위 이후는 아이콘 매핑 없음
    }
  }
}
