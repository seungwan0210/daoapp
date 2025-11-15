// lib/core/utils/ranking_utils.dart
class RankingUtils {
  static String getCurrentRankingCollection() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 9)); // KST
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    return 'checkout_practice_rankings_${year}_$month';
  }
}