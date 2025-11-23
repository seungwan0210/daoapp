// lib/data/repositories/arena_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';

class ArenaRepositoryImpl implements ArenaRepository {
  final FirebaseFirestore _firestore;

  ArenaRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ======================
  // 토너먼트 생성/수정/삭제
  // ======================

  @override
  Future<String> createTournament(TournamentModel tournament) async {
    final ref =
    await _firestore.collection('tournaments').add(tournament.toJson());
    return ref.id;
  }

  @override
  Future<void> updateTournament(TournamentModel tournament) async {
    if (tournament.id == null) {
      throw ArgumentError('ID required');
    }
    await _firestore
        .collection('tournaments')
        .doc(tournament.id)
        .update(tournament.toJson());
  }

  @override
  Future<void> deleteTournament(String tournamentId) async {
    await _firestore.collection('tournaments').doc(tournamentId).delete();
  }

  // ======================
  // 대회 리스트 (필터별)
  // ======================

  @override
  Stream<List<TournamentModel>> getTournaments({
    required String filter,
    required int limit,
    DocumentSnapshot? startAfter,
  }) {
    final now = Timestamp.fromDate(DateTime.now());
    Query query = _firestore.collection('tournaments');

    // filter 값은 UI에서 사용하는 값에 맞춰서 조정
    switch (filter) {
      case 'entryOpen':
        query = query
            .where('entryStartDate', isLessThanOrEqualTo: now)
            .where('entryEndDate', isGreaterThanOrEqualTo: now)
            .orderBy('entryEndDate', descending: false)
            .orderBy('eventDate', descending: false);
        break;
      case 'upcoming':
        query = query
            .where('eventDate', isGreaterThanOrEqualTo: now)
            .orderBy('eventDate', descending: false);
        break;
      case 'ended':
        query = query
            .where('eventDate', isLessThan: now)
            .orderBy('eventDate', descending: true);
        break;
      case 'all':
      default:
        query = query.orderBy('eventDate', descending: true);
        break;
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    if (limit > 0) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => TournamentModel.fromJson(
          doc.data() as Map<String, dynamic>,
        ).copyWith(id: doc.id),
      )
          .toList();
    });
  }

  // ======================
  // 내가 주최/공동주최한 대회
  // ======================

  @override
  Stream<List<TournamentModel>> getMyHostedTournaments({
    required String userUid,
    required String userEmail,
    required int limit,
    DocumentSnapshot? startAfter,
  }) {
    final createdByFilter = Filter('createdByUid', isEqualTo: userUid);
    late Filter whereFilter;

    if (userEmail.isEmpty) {
      whereFilter = createdByFilter;
    } else {
      final organizerFilter =
      Filter('organizerEmails', arrayContains: userEmail);
      whereFilter = Filter.or(createdByFilter, organizerFilter);
    }

    Query query = _firestore.collection('tournaments').where(whereFilter);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    if (limit > 0) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      final Map<String, TournamentModel> unique = {};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final model =
        TournamentModel.fromJson(data).copyWith(id: doc.id);
        if (model.id != null) {
          unique[model.id!] = model;
        }
      }

      final list = unique.values.toList();
      list.sort((a, b) {
        final aDate = (a.eventDate is Timestamp)
            ? (a.eventDate as Timestamp).toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = (b.eventDate is Timestamp)
            ? (b.eventDate as Timestamp).toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ======================
  // 단일 대회 조회/감시
  // ======================

  @override
  Future<TournamentModel?> getTournament(String tournamentId) async {
    final doc =
    await _firestore.collection('tournaments').doc(tournamentId).get();
    if (!doc.exists) return null;
    return TournamentModel.fromJson(doc.data() as Map<String, dynamic>)
        .copyWith(id: doc.id);
  }

  @override
  Stream<TournamentModel?> watchTournament(String tournamentId) {
    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .snapshots()
        .map(
          (doc) => doc.exists
          ? TournamentModel.fromJson(
        doc.data() as Map<String, dynamic>,
      ).copyWith(id: doc.id)
          : null,
    );
  }

  // ======================
  // 참가 엔트리 관련
  //   - 문서 ID = userUid 고정
  //   - 인원 수는 entries 컬렉션 개수로만 판단 (entryCount 사용 X)
  // ======================

  @override
  Future<void> submitEntry({
    required String tournamentId,
    required TournamentEntryModel entry,
  }) async {
    final tRef = _firestore.collection('tournaments').doc(tournamentId);
    final entriesRef = tRef.collection('entries');
    final entryRef = entriesRef.doc(entry.userUid); // userUid를 엔트리 ID로

    // 1. 대회 문서에서 최대 인원만 확인
    final tSnap = await tRef.get();
    if (!tSnap.exists) {
      throw Exception('대회를 찾을 수 없습니다.');
    }

    final data = tSnap.data() as Map<String, dynamic>;
    final int maxParticipants = (data['maxParticipants'] as int?) ?? 9999;

    // 2. 이미 신청했는지 확인
    final existingEntry = await entryRef.get();
    if (existingEntry.exists) {
      throw Exception('이미 참가 신청하셨습니다.');
    }

    // 3. 현재 인원 = entries 컬렉션 문서 개수
    final aggregateSnapshot = await entriesRef.count().get();
    final int currentCount = aggregateSnapshot.count ?? 0;

    if (currentCount >= maxParticipants) {
      throw Exception('정원이 마감되었습니다.');
    }

    // 4. 엔트리 저장 (entryCount 필드 건드리지 않음)
    await entryRef.set(entry.toJson());
  }

  @override
  Future<void> cancelEntry({
    required String tournamentId,
    required String userUid,
  }) async {
    final tRef = _firestore.collection('tournaments').doc(tournamentId);
    final entryRef = tRef.collection('entries').doc(userUid);

    final snap = await entryRef.get();
    if (!snap.exists) {
      throw Exception('참가 기록이 없습니다.');
    }

    // 엔트리 삭제 (entryCount 필드 건드리지 않음)
    await entryRef.delete();
  }

  @override
  Stream<List<TournamentEntryModel>> getEntries(String tournamentId) {
    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('entries')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (doc) => TournamentEntryModel.fromJson(
          doc.data() as Map<String, dynamic>,
        ).copyWith(id: doc.id),
      )
          .toList(),
    );
  }
}
