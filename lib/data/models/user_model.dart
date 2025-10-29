// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String? koreanName;
  final String? englishName;
  final String? shopName;
  final String? gender; // "male" or "female"
  final int totalPoints;

  User({
    required this.id,
    required this.email,
    this.koreanName,
    this.englishName,
    this.shopName,
    this.gender,
    this.totalPoints = 0,
  });

  factory User.fromMap(String id, Map<String, dynamic> map) {
    return User(
      id: id,
      email: map['email'] ?? '',
      koreanName: map['koreanName'],
      englishName: map['englishName'],
      shopName: map['shopName'],
      gender: map['gender'],
      totalPoints: map['totalPoints'] ?? 0,
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
    };
  }
}