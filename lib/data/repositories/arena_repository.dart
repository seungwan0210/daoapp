// lib/data/repositories/arena_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';

/// 아레나(토너먼트) 관련 Firestore 접근 레포지토리 인터페이스
abstract class ArenaRepository {
  // ======================
  // 토너먼트(대회) 관련
  // ======================

  /// 대회 생성
  Future<String> createTournament(TournamentModel tournament);

  /// 대회 수정
  Future<void> updateTournament(TournamentModel tournament);

  /// 대회 삭제
  Future<void> deleteTournament(String tournamentId);

  /// 필터별 대회 리스트 스트림 (무한스크롤용)
  Stream<List<TournamentModel>> getTournaments({
    required String filter,
    required int limit,
    DocumentSnapshot? startAfter,
  });

  /// 내가 주최(또는 공동주최)한 대회 스트림
  Stream<List<TournamentModel>> getMyHostedTournaments({
    required String userUid,
    required String userEmail,
    required int limit,
    DocumentSnapshot? startAfter,
  });

  /// 단일 대회 한 번 조회
  Future<TournamentModel?> getTournament(String tournamentId);

  /// 단일 대회 실시간 감시 스트림
  Stream<TournamentModel?> watchTournament(String tournamentId);

  // ======================
  // 참가 엔트리 관련
  // ======================

  /// 참가 엔트리 제출
  Future<void> submitEntry({
    required String tournamentId,
    required TournamentEntryModel entry,
  });

  /// 참가 엔트리 취소 (userUid 기반으로 찾음)
  Future<void> cancelEntry({
    required String tournamentId,
    required String userUid,  // ← entryId → userUid로 변경!
  });

  /// 특정 대회의 참가자 리스트 스트림
  Stream<List<TournamentEntryModel>> getEntries(String tournamentId);
}