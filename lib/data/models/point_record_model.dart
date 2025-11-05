// lib/data/models/point_record_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PointRecord {
  final String? id;           // ← required 제거 + nullable
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
  final int? rank;  // ← 추가 (UI용)

  PointRecord({
    this.id,                  // ← required 제거
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
    this.rank,  // ← 추가
  });

  /// Firestore에 저장할 때 사용할 Map
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

  /// Firestore 문서 → PointRecord 변환
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

  /// 기존 객체 복사 + 일부 필드만 변경 (수정 모드에서 필수!)
  PointRecord copyWith({
    String? id,
    String? userId,
    String? seasonId,
    String? phase,
    int? points,
    String? eventName,
    String? shopName,
    DateTime? date,
    String? awardedBy,
    String? koreanName,
    String? englishName,
    int? rank,  // ← 추가
  }) {
    return PointRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      seasonId: seasonId ?? this.seasonId,
      phase: phase ?? this.phase,
      points: points ?? this.points,
      eventName: eventName ?? this.eventName,
      shopName: shopName ?? this.shopName,
      date: date ?? this.date,
      awardedBy: awardedBy ?? this.awardedBy,
      koreanName: koreanName ?? this.koreanName,
      englishName: englishName ?? this.englishName,
    );
  }
}