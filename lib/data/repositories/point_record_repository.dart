// lib/data/repositories/point_record_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/point_record_model.dart';
import '../models/ranking_user.dart';

abstract class PointRecordRepository {
  // 포인트 부여
  Future<void> awardPoints(PointRecord record);

  // 포인트 수정
  Future<void> updatePointRecord(PointRecord record);

  // 포인트 삭제
  Future<void> deletePointRecord(String recordId, String userId, int points);

  // 사용자 포인트 내역 (마이페이지)
  Stream<List<PointRecord>> getUserPointHistory(String userId);

  // 전체 포인트 내역 (관리자)
  Stream<List<PointRecord>> getAllPointRecords();

  /// 랭킹 조회
  /// - top9Mode: true면 상위 9개 경기 포인트만 합산
  Stream<List<RankingUser>> getRanking({
    required String seasonId,
    required String phase,
    required String gender,
    required bool top9Mode,
  });
}