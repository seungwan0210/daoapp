// lib/core/utils/badge_utils.dart
import 'package:daoapp/core/constants/badge_constants.dart';

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

  /// 최신 월간 배지 1개만 반환 (예: monthly_2026_04_pro)
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

  /// 🔥 대표 배지 결정 로직 수정
  /// 우선순위: 실시간 순위 배지 > 과거 월간 우승 배지 > 관리자 부여 배지
  static String? getCurrentBadgeKey(Map<String, dynamic> badgesMap, {int? currentRank}) {
    // 1. 실시간 순위권(1~10위)인 경우 해당 순위 배지 반환
    if (currentRank != null && currentRank >= 1 && currentRank <= 10) {
      return BadgeConstants.badgeKeyForRank(currentRank);
    }

    // 2. 순위권 밖이라면 과거 월간 배지나 어드민 배지 확인
    return getLatestMonthlyBadge(badgesMap) ?? getLatestAdminBadge(badgesMap);
  }

  /// 특정 배지 보유 여부
  static bool hasBadge(Map<String, dynamic> badgesMap, String badgeKey) {
    return badgesMap[badgeKey] == true;
  }

  /// 툴팁용 텍스트 생성
  /// - monthly_2026_04_pro → "2026년 04월 Pro"
  /// - admin_pro → "관리자 배지: Pro"
  static String getBadgeTooltip(String key, {int? currentRank}) {
    // 실시간 순위 배지인 경우
    if (currentRank != null && currentRank <= 10) {
      return "현재 실시간 $currentRank위 (${_formatRank(key)})";
    }

    if (key.startsWith('monthly_')) {
      final parts = key.split('_');
      if (parts.length < 4) return key;
      final year = parts[1];
      final month = int.tryParse(parts[2])?.toString().padLeft(2, '0') ?? parts[2];
      final rank = _formatRank(parts[3]);
      return '$year년 $month월 $rank';
    } else if (key.startsWith('admin_')) {
      final rank = _formatRank(key.substring('admin_'.length));
      return '관리자 부여: $rank';
    }

    return _formatRank(key);
  }

  /// 배지 등급 표시 이름 (BadgeConstants의 키 기준)
  static String _formatRank(String raw) {
    const map = <String, String>{
      'pro': 'Pro',
      'diamond': 'Diamond',
      'emerald': 'Emerald',
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
      'season': 'Season Champion',
      'season1': 'Season 1st',
      'season2': 'Season 2nd',
      'season3': 'Season 3rd',
    };
    // admin_ 이나 monthly_ 접두사가 붙어있을 경우를 대비해 마지막 단어만 추출
    final cleanKey = raw.split('_').last;
    return map[cleanKey] ?? cleanKey.toUpperCase();
  }
}