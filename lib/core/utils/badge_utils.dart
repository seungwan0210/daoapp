// lib/core/utils/badge_utils.dart
class BadgeUtils {
  /// Firestore `users` 문서에서 `badges` 맵 추출
  static Map<String, dynamic> extractBadges(Map<String, dynamic> data) {
    return (data['badges'] as Map<String, dynamic>?) ?? {};
  }

  /// 모든 활성화된 배지 키 (monthly_*, admin_*) → 최신순 정렬
  static List<String> extractActiveBadges(Map<String, dynamic> badgesMap) {
    final active = badgesMap.entries
        .where((e) =>
    e.value == true &&
        (e.key.startsWith('monthly_') || e.key.startsWith('admin_')))
        .map((e) => e.key)
        .toList();

    active.sort((a, b) => b.compareTo(a)); // 최신 월간 배지가 맨 앞
    return active;
  }

  /// 최신 월간 배지 1개만 반환 (예: monthly_2025_11_pro)
  static String? getLatestMonthlyBadge(Map<String, dynamic> badgesMap) {
    final monthly = badgesMap.keys
        .where((k) => k.startsWith('monthly_') && badgesMap[k] == true)
        .toList();

    if (monthly.isEmpty) return null;
    monthly.sort((a, b) => b.compareTo(a));
    return monthly.first;
  }

  /// 관리자 배지 1개만 반환 (예: admin_pro) → 알파벳순
  static String? getLatestAdminBadge(Map<String, dynamic> badgesMap) {
    final admin = badgesMap.keys
        .where((k) => k.startsWith('admin_') && badgesMap[k] == true)
        .toList();

    if (admin.isEmpty) return null;
    admin.sort(); // 알파벳순
    return admin.first;
  }

  /// 대표 배지: 월간 > 관리자
  static String? getCurrentBadgeKey(Map<String, dynamic> badgesMap) {
    return getLatestMonthlyBadge(badgesMap) ?? getLatestAdminBadge(badgesMap);
  }

  /// 특정 배지 보유 여부
  static bool hasBadge(Map<String, dynamic> badgesMap, String badgeKey) {
    return badgesMap[badgeKey] == true;
  }

  /// 툴팁용 텍스트 생성
  /// - monthly_2025_11_pro → "2025년 11월 Pro"
  /// - admin_pro → "관리자 배지: Pro"
  static String getBadgeTooltip(String key) {
    if (key.startsWith('monthly_')) {
      final parts = key.split('_');
      if (parts.length < 4) return key;
      final year = parts[1];
      final month =
          int.tryParse(parts[2])?.toString().padLeft(2, '0') ?? parts[2];
      final rank = _formatRank(parts[3]);
      return '$year년 $month월 $rank';
    } else if (key.startsWith('admin_')) {
      final rank = _formatRank(key.substring('admin_'.length));
      return '관리자 배지: $rank';
    }
    // 그 외(직접 키를 넣은 경우)는 raw 키 그대로
    return key;
  }

  /// 배지 등급 포맷팅 (Pro, Emerald 등)
  static String _formatRank(String raw) {
    const map = <String, String>{
      'pro': 'Pro',
      'emerald': 'Emerald',
      'diamond': 'Diamond',
      'platinum1': 'Platinum 1',
      'platinum2': 'Platinum 2',
      'gold1': 'Gold 1',
      'gold2': 'Gold 2',
      'silver1': 'Silver 1',
      'silver2': 'Silver 2',
      'bronze1': 'Bronze 1',
      'bronze2': 'Bronze 2',
      'bronze3': 'Bronze 3',
      'tro': '야미 트로피',

      // 🔥 시즌 배지 표시 이름
      'season': 'Season Champion', // 시즌 챔피언
      'season1': 'Season 1st',     // 시즌 1위
      'season2': 'Season 2nd',     // 시즌 2위
      'season3': 'Season 3rd',     // 시즌 3위
    };
    return map[raw] ?? raw.toUpperCase();
  }

  /// 디버그용: 모든 배지 키 (최신순)
  static List<String> getAllBadges(Map<String, dynamic> badgesMap) {
    return badgesMap.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList()
      ..sort((a, b) => b.compareTo(a));
  }
}
