// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
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
    );
  }

  Map<String, dynamic> toMap() {
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
    );
  }
}