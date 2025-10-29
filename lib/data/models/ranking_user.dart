// lib/data/models/ranking_user.dart
class RankingUser {
  final String userId;
  final String koreanName;
  final String englishName;
  final String shopName;
  final String gender;
  int totalPoints;
  int rank;

  RankingUser({
    required this.userId,
    required this.koreanName,
    required this.englishName,
    required this.shopName,
    required this.gender,
    this.totalPoints = 0,
    this.rank = 0,
  });
}