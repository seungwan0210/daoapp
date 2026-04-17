import 'package:cloud_firestore/cloud_firestore.dart';

class RankingRecord {
  final String userId;
  final String nickname;
  final String? profileImageUrl;
  final double bestPpd;    // 501 최고 기록
  final double bestMpr;    // 크리켓 최고 기록
  final int bestCountUp;   // 카운트업 최고 기록
  final DateTime updatedAt;

  RankingRecord({
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
    this.bestPpd = 0.0,
    this.bestMpr = 0.0,
    this.bestCountUp = 0,
    required this.updatedAt,
  });

  factory RankingRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RankingRecord(
      userId: doc.id,
      nickname: data['nickname'] ?? '이름 없음',
      profileImageUrl: data['profileImageUrl'],
      bestPpd: (data['bestPpd'] as num?)?.toDouble() ?? 0.0,
      bestMpr: (data['bestMpr'] as num?)?.toDouble() ?? 0.0,
      bestCountUp: (data['bestCountUp'] as num?)?.toInt() ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'bestPpd': bestPpd,
      'bestMpr': bestMpr,
      'bestCountUp': bestCountUp,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}