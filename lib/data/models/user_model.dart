// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore users 컬렉션의 사용자 모델
class User {
  final String id;
  final String email;
  final String? koreanName;
  final String? englishName;
  final String? shopName;
  final String? gender; // "male" or "female"
  final int totalPoints;
  final bool hasProfile; // 프로필 등록 여부 (koreanName 등 입력 완료)

  User({
    required this.id,
    required this.email,
    this.koreanName,
    this.englishName,
    this.shopName,
    this.gender,
    this.totalPoints = 0,
    this.hasProfile = false, // 기본값: 등록 전
  });

  /// Firestore 문서 → User 객체
  factory User.fromMap(String id, Map<String, dynamic> map) {
    return User(
      id: id,
      email: map['email'] ?? '',
      koreanName: map['koreanName'] as String?,
      englishName: map['englishName'] as String?,
      shopName: map['shopName'] as String?,
      gender: map['gender'] as String?,
      totalPoints: map['totalPoints'] ?? 0,
      hasProfile: map['hasProfile'] ?? false,
    );
  }

  /// User 객체 → Firestore 문서
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'koreanName': koreanName,
      'englishName': englishName,
      'shopName': shopName,
      'gender': gender,
      'totalPoints': totalPoints,
      'hasProfile': hasProfile,
      'lastLoginAt': FieldValue.serverTimestamp(), // 로그인 시간 갱신
    };
  }

  /// 프로필 등록 시 사용 (부분 업데이트)
  User copyWith({
    String? koreanName,
    String? englishName,
    String? shopName,
    String? gender,
    bool? hasProfile,
  }) {
    return User(
      id: id,
      email: email,
      koreanName: koreanName ?? this.koreanName,
      englishName: englishName ?? this.englishName,
      shopName: shopName ?? this.shopName,
      gender: gender ?? this.gender,
      totalPoints: totalPoints,
      hasProfile: hasProfile ?? this.hasProfile,
    );
  }
}