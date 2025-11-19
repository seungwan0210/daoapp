// lib/data/repositories/arena_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';

class ArenaRepositoryImpl implements ArenaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<String> createTournament(TournamentModel tournament) async {
    final ref = await _firestore.collection('tournaments').add(tournament.toJson());
    return ref.id;
  }

  @override
  Stream<List<TournamentModel>> getTournaments({
    required String filter,
    required int limit,
    DocumentSnapshot? startAfter,
  }) {
    Query query = _firestore
        .collection('tournaments')
        .orderBy('eventDate', descending: true);

    final now = Timestamp.now();

    switch (filter) {
      case 'open':
        query = query
            .where('entryStartDate', isLessThanOrEqualTo: now)
            .where('entryEndDate', isGreaterThanOrEqualTo: now);
        break;
      case 'upcoming':
        query = query.where('entryStartDate', isGreaterThan: now);
        break;
      case 'closed':
        query = query
            .where('entryEndDate', isLessThan: now)
            .where('eventDate', isGreaterThan: now);
        break;
      case 'finished':
        query = query.where('eventDate', isLessThan: now);
        break;
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TournamentModel.fromJson(doc.data() as Map<String, dynamic>).copyWith(id: doc.id))
          .toList();
    });
  }

  // ★★★ 완벽한 내가 주최한 대회 쿼리 (Firestore 10.0 이상에서만 동작) ★★★
  @override
  Stream<List<TournamentModel>> getMyHostedTournaments({
    required String userUid,
    required String userEmail,
    required int limit,
    DocumentSnapshot? startAfter,
  }) {
    return _firestore
        .collection('tournaments')
        .where(Filter.or(
      Filter('createdByUid', isEqualTo: userUid),
      Filter('organizerEmails', arrayContains: userEmail),
    ))
        .orderBy('eventDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final Map<String, TournamentModel> unique = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final model = TournamentModel.fromJson(data).copyWith(id: doc.id);
        unique[doc.id] = model; // 중복 자동 제거
      }
      return unique.values.toList();
    });
  }

  @override
  Future<TournamentModel?> getTournament(String tournamentId) async {
    final doc = await _firestore.collection('tournaments').doc(tournamentId).get();
    if (!doc.exists) return null;
    return TournamentModel.fromJson(doc.data()!).copyWith(id: doc.id);
  }

  @override
  Future<void> submitEntry({
    required String tournamentId,
    required TournamentEntryModel entry,
  }) async {
    await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('entries')
        .add(entry.toJson());
  }

  @override
  Stream<List<TournamentEntryModel>> getEntries(String tournamentId) {
    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('entries')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TournamentEntryModel.fromJson(doc.data()).copyWith(id: doc.id))
        .toList());
  }
}