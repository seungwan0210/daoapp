// lib/data/repositories/point_record_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/point_record_model.dart';
import '../models/ranking_user.dart';
import '../models/user_model.dart';

abstract class PointRecordRepository {
  Future<void> awardPoints(PointRecord record);

  /// 랭킹 조회
  /// - top9Mode: true면 상위 9개 경기 포인트만 합산
  Stream<List<RankingUser>> getRanking({
    required String seasonId,
    required String phase,
    required String gender,
    required bool top9Mode, // 추가!
  });
}