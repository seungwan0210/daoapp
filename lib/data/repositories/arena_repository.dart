// lib/data/repositories/arena_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';

abstract class ArenaRepository {
  Future<String> createTournament(TournamentModel tournament);
  Future<void> updateTournament(TournamentModel tournament);
  Future<void> deleteTournament(String tournamentId);
  Stream<List<TournamentModel>> getTournaments({required String filter, required int limit, DocumentSnapshot? startAfter});
  Stream<List<TournamentModel>> getMyHostedTournaments({required String userUid, required String userEmail, required int limit, DocumentSnapshot? startAfter});
  Future<TournamentModel?> getTournament(String tournamentId);
  Stream<TournamentModel?> watchTournament(String tournamentId);
  Future<void> submitEntry({required String tournamentId, required TournamentEntryModel entry});
  Future<void> cancelEntry({required String tournamentId, required String userUid});
  Stream<List<TournamentEntryModel>> getEntries(String tournamentId);

  // ✅ 이 함수가 인터페이스에 있어야 스크린에서 에러 없이 호출 가능합니다.
  Future<void> updatePaymentStatus(String tournamentId, String userUid, bool isPaid);
}