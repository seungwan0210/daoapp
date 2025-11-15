// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart'; // firstWhereOrNull 사용

class AppUser {
  final String id;
  final String email;
  final String? koreanName;
  final String? englishName;
  final String? shopName;
  final String? gender;
  final int totalPoints;
  final bool hasProfile;
  final String? profileImageUrl;
  final bool isPhoneVerified;

  // 월간 배지: 예) badges.monthly_2025_11_pro: true
  final Map<String, bool> monthlyBadges;
  final String? lastMonthlyBadge; // 예: "2025년 11월 1위"

  AppUser({
    required this.id,
    required this.email,
    this.koreanName,
    this.englishName,
    this.shopName,
    this.gender,
    this.totalPoints = 0,
    this.hasProfile = false,
    this.profileImageUrl,
    this.isPhoneVerified = false,
    this.monthlyBadges = const {},
    this.lastMonthlyBadge,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    final badgesMap = map['badges'] as Map<String, dynamic>?;
    final monthlyBadges = <String, bool>{};

    if (badgesMap != null) {
      badgesMap.forEach((key, value) {
        if (key.startsWith('monthly_') && value is bool) {
          monthlyBadges[key] = value;
        }
      });
    }

    return AppUser(
      id: id,
      email: map['email'] ?? '',
      koreanName: map['koreanName'] as String?,
      englishName: map['englishName'] as String?,
      shopName: map['shopName'] as String?,
      gender: map['gender'] as String?,
      totalPoints: map['totalPoints'] ?? 0,
      hasProfile: map['hasProfile'] ?? false,
      profileImageUrl: map['profileImageUrl'] as String?,
      isPhoneVerified: map['isPhoneVerified'] ?? false,
      monthlyBadges: monthlyBadges,
      lastMonthlyBadge: map['lastMonthlyBadge'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final badges = <String, bool>{};
    monthlyBadges.forEach((key, value) {
      badges[key] = value;
    });

    return {
      'email': email,
      'koreanName': koreanName,
      'englishName': englishName,
      'shopName': shopName,
      'gender': gender,
      'totalPoints': totalPoints,
      'hasProfile': hasProfile,
      'profileImageUrl': profileImageUrl,
      'isPhoneVerified': isPhoneVerified,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'badges': badges,
      if (lastMonthlyBadge != null) 'lastMonthlyBadge': lastMonthlyBadge,
    };
  }

  AppUser copyWith({
    String? koreanName,
    String? englishName,
    String? shopName,
    String? gender,
    bool? hasProfile,
    String? profileImageUrl,
    bool? isPhoneVerified,
    Map<String, bool>? monthlyBadges,
    String? lastMonthlyBadge,
  }) {
    return AppUser(
      id: id,
      email: email,
      koreanName: koreanName ?? this.koreanName,
      englishName: englishName ?? this.englishName,
      shopName: shopName ?? this.shopName,
      gender: gender ?? this.gender,
      totalPoints: totalPoints,
      hasProfile: hasProfile ?? this.hasProfile,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      monthlyBadges: monthlyBadges ?? this.monthlyBadges,
      lastMonthlyBadge: lastMonthlyBadge ?? this.lastMonthlyBadge,
    );
  }

  // === 추가: 현재 월 배지 키 추출 ===
  String? get currentMonthlyBadgeKey {
    final now = DateTime.now().toUtc().add(const Duration(hours: 9)); // KST
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final prefix = 'monthly_${year}_${month}';

    return monthlyBadges.keys
        .firstWhereOrNull((key) => key.startsWith(prefix));
  }
}