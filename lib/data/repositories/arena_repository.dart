// lib/data/repositories/arena_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';

abstract class ArenaRepository {
  // 대회 생성
  Future<String> createTournament(TournamentModel tournament);

  // 필터별 대회 리스트 스트림 (무한스크롤용)
  Stream<List<TournamentModel>> getTournaments({
    required String filter, // 'all', 'open', 'upcoming', 'closed', 'my_hosted'
    required int limit,
    DocumentSnapshot? startAfter,
  });

  // 내가 주최한 대회 전용 스트림 (array-contains + whereEqualTo 조합)
  Stream<List<TournamentModel>> getMyHostedTournaments({
    required String userUid,
    required String userEmail,
    required int limit,
    DocumentSnapshot? startAfter,
  });

  // 단일 대회 조회
  Future<TournamentModel?> getTournament(String tournamentId);

  // 참가 엔트리 제출
  Future<void> submitEntry({
    required String tournamentId,
    required TournamentEntryModel entry,
  });

  // 특정 대회의 참가자 리스트 (주최자만)
  Stream<List<TournamentEntryModel>> getEntries(String tournamentId);
}