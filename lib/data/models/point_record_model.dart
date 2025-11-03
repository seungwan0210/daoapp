// lib/data/models/point_record_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PointRecord {
  final String id;
  final String userId;
  final String seasonId;
  final String phase;
  final int points;
  final String eventName;
  final String shopName;
  final DateTime date;
  final String awardedBy;

  // 추가: 사용자 이름 (UI 표시용)
  final String koreanName;
  final String englishName;

  PointRecord({
    required this.id,
    required this.userId,
    required this.seasonId,
    required this.phase,
    required this.points,
    required this.eventName,
    required this.shopName,
    required this.date,
    required this.awardedBy,
    this.koreanName = '',
    this.englishName = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'seasonId': seasonId,
      'phase': phase,
      'points': points,
      'eventName': eventName,
      'shopName': shopName,
      'date': Timestamp.fromDate(date),
      'awardedBy': awardedBy,
    };
  }

  factory PointRecord.fromMap(String id, Map<String, dynamic> map, Map<String, dynamic>? userData) {
    return PointRecord(
      id: id,
      userId: map['userId'] ?? '',
      seasonId: map['seasonId'] ?? '',
      phase: map['phase'] ?? '',
      points: map['points'] ?? 0,
      eventName: map['eventName'] ?? '',
      shopName: map['shopName'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      awardedBy: map['awardedBy'] ?? '',
      koreanName: userData?['koreanName'] ?? '',
      englishName: userData?['englishName'] ?? '',
    );
  }
}