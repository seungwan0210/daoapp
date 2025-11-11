// lib/data/models/ranking_user.dart
class RankingUser {
  final String userId;
  final String koreanName;
  final String englishName;
  final String shopName;
  final String gender;
  int totalPoints;
  int? top9Points; // 상위 9개 포인트 (null이면 전체 포인트 사용)
  int rank;

  RankingUser({
    required this.userId,
    required this.koreanName,
    required this.englishName,
    required this.shopName,
    required this.gender,
    this.totalPoints = 0,
    this.top9Points,
    this.rank = 0,
  });

  // UI에서 사용할 포인트 값
  int get displayPoints => top9Points ?? totalPoints;

  // UI에서 사용할 라벨 (예: "상위9" 또는 "전체")
  String get displayLabel => top9Points != null ? '상위9' : '전체';
}