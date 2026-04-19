// lib/data/repositories/arena_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';

abstract class ArenaRepository {
  Future<String> createTournament(TournamentModel tournament);
  Future<void> updateTournament(TournamentModel tournament);

  // ✅ 완전 삭제 로직 (사진 + 하위 명단 + 문서 전체 삭제)
  Future<void> deleteTournament(String tournamentId);

  Stream<List<TournamentModel>> getTournaments({
    required String filter,
    required int limit,
    DocumentSnapshot? startAfter
  });

  Stream<List<TournamentModel>> getMyHostedTournaments({
    required String userUid,
    required String userEmail,
    required int limit,
    DocumentSnapshot? startAfter
  });

  Future<TournamentModel?> getTournament(String tournamentId);
  Stream<TournamentModel?> watchTournament(String tournamentId);

  Future<void> submitEntry({required String tournamentId, required TournamentEntryModel entry});
  Future<void> cancelEntry({required String tournamentId, required String userUid});
  Stream<List<TournamentEntryModel>> getEntries(String tournamentId);

  Future<void> updatePaymentStatus(String tournamentId, String userUid, bool isPaid);

  // ✅ [추가] 관리자 앱 접속 시 3개월 지난 데이터를 자동으로 청소하는 기능
  Future<void> autoCleanOldTournaments();
}