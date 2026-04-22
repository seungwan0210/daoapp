// lib/data/repositories/arena_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';

class ArenaRepositoryImpl implements ArenaRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ArenaRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // ======================
  // Internal helpers
  // ======================

  Map<String, dynamic> _tournamentDocJson(TournamentModel t) {
    final json = t.toJson();
    json.remove('id');
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
    final ref = await _firestore.collection('tournaments').add({
      ..._tournamentDocJson(tournament),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  @override
  Future<void> updateTournament(TournamentModel tournament) async {
    final tid = (tournament.id ?? '').trim();
    if (tid.isEmpty) throw ArgumentError('updateTournament: id required');

    await _firestore.collection('tournaments').doc(tid).update({
      'title': tournament.title,
      'location': tournament.location,
      'maxParticipants': tournament.maxParticipants,
      'posterUrl': tournament.posterUrl,
      'description': tournament.description,
      'entryFee': tournament.entryFee,
      'eventDate': tournament.eventDate,
      'entryStartDate': tournament.entryStartDate,
      'entryEndDate': tournament.entryEndDate,
      'hostName': tournament.hostName,
      'hostPhone': tournament.hostPhone,
      'isCanceled': tournament.isCanceled,
      'organizerEmails': tournament.organizerEmails,
      'customQuestions': tournament.customQuestions,
      'type': tournament.type,
      'teamSize': tournament.teamSize,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteTournament(String tournamentId) async {
    final tid = tournamentId.trim();
    if (tid.isEmpty) return;

    try {
      final doc = await _firestore.collection('tournaments').doc(tid).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final String? posterUrl = data['posterUrl'];

      if (posterUrl != null && posterUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(posterUrl).delete();
        } catch (e) {
          debugPrint("⚠️ 이미지 삭제 실패: $e");
        }
      }

      final entries = await _firestore.collection('tournaments').doc(tid).collection('entries').get();
      final batch = _firestore.batch();
      for (var entryDoc in entries.docs) {
        batch.delete(entryDoc.reference);
      }

      batch.delete(_firestore.collection('tournaments').doc(tid));
      await batch.commit();

    } catch (e) {
      throw Exception("대회 삭제에 실패했습니다.");
    }
  }

  @override
  Future<void> autoCleanOldTournaments() async {
    try {
      final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
      final snapshots = await _firestore
          .collection('tournaments')
          .where('entryEndDate', isLessThan: Timestamp.fromDate(ninetyDaysAgo))
          .get();

      if (snapshots.docs.isEmpty) return;

      for (var doc in snapshots.docs) {
        await deleteTournament(doc.id);
      }
    } catch (e) {
      debugPrint("❌ 자동 청소 중 오류: $e");
    }
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
      list.sort((a, b) => b.eventDate.toDate().compareTo(a.eventDate.toDate()));
      return list;
    });
  }

  // ======================
  // 🎯 Entries 핵심 수정 (수동 등록 지원)
  // ======================

  @override
  Future<void> submitEntry({
    required String tournamentId,
    required TournamentEntryModel entry,
  }) async {
    final tid = tournamentId.trim();
    final userUid = entry.userUid.trim();
    if (tid.isEmpty || userUid.isEmpty) throw Exception('필수 정보 누락');

    final tRef = _firestore.collection('tournaments').doc(tid);

    // ✅ [수정] 수동 등록(isManual)인 경우 랜덤 문서 ID 생성, 일반 신청은 유저 UID 사용
    final DocumentReference eRef = entry.isManual
        ? tRef.collection('entries').doc() // 🎯 수동: 랜덤 ID
        : tRef.collection('entries').doc(userUid); // 👤 일반: 유저 UID

    await _firestore.runTransaction((tx) async {
      final tSnap = await tx.get(tRef);
      if (!tSnap.exists) throw Exception('대회 없음');

      final tData = tSnap.data() as Map<String, dynamic>;
      final int maxParticipants = (tData['maxParticipants'] as int?) ?? 9999;
      if (tData['isCanceled'] == true) throw Exception('취소된 대회');

      // ✅ [수정] 일반 유저 신청인 경우에만 중복 신청 체크
      if (!entry.isManual) {
        final eSnap = await tx.get(eRef);
        if (eSnap.exists) throw Exception('이미 신청됨');
      }

      final int currentCount = (tData['entryCount'] as int?) ?? 0;
      if (currentCount >= maxParticipants) throw Exception('정원 마감');

      tx.set(eRef, {
        ..._entryDocJson(entry),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // ✅ [수정] 주최자 수동 등록은 입금 확인 상태(confirmed)로 간주하거나 수동 관리
        'isPaid': entry.isManual ? true : false,
      });

      tx.update(tRef, {
        'entryCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> cancelEntry({
    required String tournamentId,
    required String userUid, // 💡 여기서 userUid는 '문서 ID' 역할을 수행함
  }) async {
    final tid = tournamentId.trim();
    final uid = userUid.trim();
    if (tid.isEmpty || uid.isEmpty) return;

    final tRef = _firestore.collection('tournaments').doc(tid);
    final eRef = tRef.collection('entries').doc(uid);

    await _firestore.runTransaction((tx) async {
      final tSnap = await tx.get(tRef);
      final eSnap = await tx.get(eRef);
      if (!tSnap.exists || !eSnap.exists) return;

      tx.delete(eRef);

      final currentCount = (tSnap.data()?['entryCount'] as int?) ?? 0;
      tx.update(tRef, {
        'entryCount': currentCount <= 0 ? 0 : FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> updatePaymentStatus(String tournamentId, String entryId, bool isPaid) async {
    // ✅ [수정] userUid 대신 entryId(문서ID)를 인자로 받아 수동 입력 건도 처리 가능하게 함
    final eRef = _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('entries')
        .doc(entryId);

    await eRef.update({
      'isPaid': isPaid,
      'status': isPaid ? 'confirmed' : 'applied',
      'updatedAt': FieldValue.serverTimestamp(),
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
        ).copyWith(id: doc.id), // 🎯 [중요] 문서 ID를 id 필드에 꽂아줌
      )
          .toList(),
    );
  }
}