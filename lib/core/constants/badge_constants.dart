// lib/core/constants/badge_constants.dart
class BadgeConstants {
  static const Map<String, String> _badgeMap = {
    // 예: monthly_2025_11_pro
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
  };

  static String? getImagePath(String key) {
    // key 예: monthly_2025_11_pro
    final parts = key.split('_');
    if (parts.length >= 4 && parts[0] == 'monthly') {
      final badgeKey = parts.last; // pro, emerald 등
      return _badgeMap[badgeKey];
    }
    return null;
  }

  static String? fromKey(String key) => getImagePath(key);
}