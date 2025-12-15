import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';

class ArenaRepositoryImpl implements ArenaRepository {
  final FirebaseFirestore _firestore;

  ArenaRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ======================
  // Internal helpers
  // ======================

  Map<String, dynamic> _tournamentDocJson(TournamentModel t) {
    final json = t.toJson();
    json.remove('id'); // Firestore 문서에는 id 저장 안 함
    return json;
  }

  Map<String, dynamic> _entryDocJson(TournamentEntryModel e) {
    final json = e.toJson();
    json.remove('id');
    return json;
  }

  // ======================
  // Tournament CRUD
  // ======================

  @override
  Future<String> createTournament(TournamentModel tournament) async {
    final ref = await _firestore
        .collection('tournaments')
        .add(_tournamentDocJson(tournament));
    return ref.id;
  }

  @override
  Future<void> updateTournament(TournamentModel tournament) async {
    final tid = (tournament.id ?? '').trim();
    if (tid.isEmpty) throw ArgumentError('updateTournament: id required');

    await _firestore
        .collection('tournaments')
        .doc(tid)
        .update(_tournamentDocJson(tournament));
  }

  @override
  Future<void> deleteTournament(String tournamentId) async {
    final tid = tournamentId.trim();
    if (tid.isEmpty) return;
    await _firestore.collection('tournaments').doc(tid).delete();
  }

  @override
  Future<TournamentModel?> getTournament(String tournamentId) async {
    final tid = tournamentId.trim();
    if (tid.isEmpty) return null;

    final doc = await _firestore.collection('tournaments').doc(tid).get();
    if (!doc.exists) return null;

    return TournamentModel.fromJson(doc.data() as Map<String, dynamic>)
        .copyWith(id: doc.id);
  }

  @override
  Stream<TournamentModel?> watchTournament(String tournamentId) {
    final tid = tournamentId.trim();
    if (tid.isEmpty) return const Stream.empty();

    return _firestore
        .collection('tournaments')
        .doc(tid)
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
  // Tournament lists
  // ======================

  @override
  Stream<List<TournamentModel>> getTournaments({
    required String filter,
    required int limit,
    DocumentSnapshot? startAfter,
  }) {
    Query query = _firestore.collection('tournaments');
    final now = Timestamp.now();

    switch (filter) {
      case 'open':
        query = query
            .where('entryStartDate', isLessThanOrEqualTo: now)
            .where('entryEndDate', isGreaterThanOrEqualTo: now)
            .orderBy('entryEndDate')
            .orderBy('eventDate');
        break;

      case 'upcoming':
        query = query
            .where('entryStartDate', isGreaterThan: now)
            .orderBy('entryStartDate')
            .orderBy('eventDate');
        break;

      case 'closed':
        query = query
            .where('entryEndDate', isLessThan: now)
            .orderBy('entryEndDate', descending: true)
            .orderBy('eventDate', descending: true);
        break;

      case 'all':
      default:
        query = query.orderBy('eventDate', descending: true);
        break;
    }

    if (startAfter != null) query = query.startAfterDocument(startAfter);
    if (limit > 0) query = query.limit(limit);

    return query.snapshots().map(
          (snapshot) => snapshot.docs
          .map(
            (doc) => TournamentModel.fromJson(
          doc.data() as Map<String, dynamic>,
        ).copyWith(id: doc.id),
      )
          .toList(),
    );
  }

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
      whereFilter = Filter.or(
        createdByFilter,
        Filter('organizerEmails', arrayContains: userEmail),
      );
    }

    Query query = _firestore.collection('tournaments').where(whereFilter);

    if (startAfter != null) query = query.startAfterDocument(startAfter);
    if (limit > 0) query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      final map = <String, TournamentModel>{};

      for (final doc in snapshot.docs) {
        final model = TournamentModel.fromJson(
          doc.data() as Map<String, dynamic>,
        ).copyWith(id: doc.id);
        final id = (model.id ?? '').trim();
        if (id.isNotEmpty) map[id] = model;
      }

      final list = map.values.toList();
      list.sort((a, b) =>
          b.eventDate.toDate().compareTo(a.eventDate.toDate()));
      return list;
    });
  }

  // ======================
  // Entries (🔥 핵심 수정 완료)
  // ======================

  @override
  Future<void> submitEntry({
    required String tournamentId,
    required TournamentEntryModel entry,
  }) async {
    final tid = tournamentId.trim();
    if (tid.isEmpty) throw Exception('대회 ID가 비어있습니다.');

    final userUid = entry.userUid.trim();
    if (userUid.isEmpty) throw Exception('유저 UID가 비어있습니다.');

    final tRef = _firestore.collection('tournaments').doc(tid);
    final eRef = tRef.collection('entries').doc(userUid);

    await _firestore.runTransaction((tx) async {
      final tSnap = await tx.get(tRef);
      if (!tSnap.exists) throw Exception('대회를 찾을 수 없습니다.');

      final tData = tSnap.data() as Map<String, dynamic>;

      final int maxParticipants =
          (tData['maxParticipants'] as int?) ?? 9999;
      final bool isCanceled = (tData['isCanceled'] as bool?) ?? false;
      if (isCanceled) throw Exception('취소된 대회입니다.');

      // 이미 참가 여부
      final eSnap = await tx.get(eRef);
      if (eSnap.exists) throw Exception('이미 참가 신청했습니다.');

      // 정원 체크
      final int currentCount = (tData['entryCount'] as int?) ?? 0;
      if (currentCount >= maxParticipants) {
        throw Exception('정원이 마감되었습니다.');
      }

      // 엔트리 생성
      tx.set(eRef, {
        ..._entryDocJson(entry),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ rules 통과: entryCount만 변경
      tx.update(tRef, {
        'entryCount': FieldValue.increment(1),
      });
    });
  }

  @override
  Future<void> cancelEntry({
    required String tournamentId,
    required String userUid,
  }) async {
    final tid = tournamentId.trim();
    final uid = userUid.trim();
    if (tid.isEmpty || uid.isEmpty) return;

    final tRef = _firestore.collection('tournaments').doc(tid);
    final eRef = tRef.collection('entries').doc(uid);

    await _firestore.runTransaction((tx) async {
      final tSnap = await tx.get(tRef);
      if (!tSnap.exists) throw Exception('대회를 찾을 수 없습니다.');

      final eSnap = await tx.get(eRef);
      if (!eSnap.exists) throw Exception('참가 기록이 없습니다.');

      tx.delete(eRef);

      final tData = tSnap.data() as Map<String, dynamic>;
      final int currentCount = (tData['entryCount'] as int?) ?? 0;

      tx.update(tRef, {
        'entryCount': currentCount <= 0
            ? 0
            : FieldValue.increment(-1),
      });
    });
  }

  @override
  Stream<List<TournamentEntryModel>> getEntries(String tournamentId) {
    final tid = tournamentId.trim();
    if (tid.isEmpty) return const Stream.empty();

    return _firestore
        .collection('tournaments')
        .doc(tid)
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
