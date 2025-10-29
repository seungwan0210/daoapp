// lib/data/repositories/point_record_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/point_record_model.dart';
import '../models/ranking_user.dart';
import '../models/user_model.dart';

abstract class PointRecordRepository {
  Future<void> awardPoints(PointRecord record);
  Stream<List<RankingUser>> getRanking({
    required String seasonId,
    required String phase,
    required String gender,
  });
}