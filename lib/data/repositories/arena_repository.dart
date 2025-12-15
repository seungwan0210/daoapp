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
  /// - ⚠️ entryCount 같은 서버 관리 필드는 덮어쓰지 않도록 구현체에서 주의
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

  /// 참가 엔트리 취소 (userUid 기반)
  Future<void> cancelEntry({
    required String tournamentId,
    required String userUid,
  });

  /// 특정 대회의 참가자 리스트 스트림
  Stream<List<TournamentEntryModel>> getEntries(String tournamentId);
}

/// ===============================================
/// ✅ Firestore 구현체 (정원/중복/기간 서버 보장)
/// ===============================================
class FirestoreArenaRepository implements ArenaRepository {
  final FirebaseFirestore _db;

  FirestoreArenaRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tournaments =>
      _db.collection('tournaments');

  DocumentReference<Map<String, dynamic>> _tRef(String id) => _tournaments.doc(id);

  CollectionReference<Map<String, dynamic>> _entriesRef(String tournamentId) =>
      _tRef(tournamentId).collection('entries');

  // ----------------------
  // Tournament CRUD
  // ----------------------

  @override
  Future<String> createTournament(TournamentModel tournament) async {
    final doc = await _tournaments.add(tournament.toJson());
    return doc.id;
  }

  @override
  Future<void> updateTournament(TournamentModel tournament) async {
    final id = tournament.id;
    if (id == null || id.isEmpty) {
      throw Exception('updateTournament: tournament.id가 비어있습니다.');
    }

    // ✅ 중요: tournament.toJson()을 그대로 update하면
    // entryCount, entrySummarySent 같은 서버 관리 필드까지 덮어쓸 수 있음.
    // 그래서 "수정 화면에서 바뀌는 필드만" 업데이트하도록 제한.
    final updateData = <String, dynamic>{
      'title': tournament.title,
      'location': tournament.location,
      'maxParticipants': tournament.maxParticipants,
      'posterUrl': tournament.posterUrl,
      'description': tournament.description,
      'entryFee': tournament.entryFee,
      'eventDate': tournament.eventDate,
      'entryStartDate': tournament.entryStartDate,
      'entryEndDate': tournament.entryEndDate,
      'createdByUid': tournament.createdByUid,
      'organizerEmails': tournament.organizerEmails,
      'hostName': tournament.hostName,
      'hostPhone': tournament.hostPhone,
      'isCanceled': tournament.isCanceled,
      'updatedAt': Timestamp.now(),
    };

    // posterUrl이 null이면 기존 값을 지우고 싶지 않은 경우가 많아서
    // null이면 아예 업데이트에서 제외 (필요하면 아래 줄을 지워서 null도 반영 가능)
    if (tournament.posterUrl == null) {
      updateData.remove('posterUrl');
    }

    await _tournaments.doc(id).update(updateData);
  }

  @override
  Future<void> deleteTournament(String tournamentId) async {
    await _tournaments.doc(tournamentId).delete();
  }

  @override
  Future<TournamentModel?> getTournament(String tournamentId) async {
    final snap = await _tournaments.doc(tournamentId).get();
    if (!snap.exists || snap.data() == null) return null;
    return TournamentModel.fromJson(snap.data()!).copyWith(id: snap.id);
  }

  @override
  Stream<TournamentModel?> watchTournament(String tournamentId) {
    return _tournaments.doc(tournamentId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return TournamentModel.fromJson(snap.data()!).copyWith(id: snap.id);
    });
  }

  // ----------------------
  // Lists (filter)
  // ----------------------

  @override
  Stream<List<TournamentModel>> getTournaments({
    required String filter,
    required int limit,
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> q = _tournaments;

    // ✅ 기본: eventDate 최신순
    q = q.orderBy('eventDate', descending: true);

    // ✅ 취소 여부는 서버에서만 필터 가능
    if (filter == 'canceled') {
      q = q.where('isCanceled', isEqualTo: true);
    } else {
      q = q.where('isCanceled', isEqualTo: false);
    }

    if (startAfter != null) q = q.startAfterDocument(startAfter);
    q = q.limit(limit);

    return q.snapshots().map((qs) {
      final list = qs.docs
          .map((d) => TournamentModel.fromJson(d.data()).copyWith(id: d.id))
          .toList();

      // ✅ 상태(open/upcoming/closed/...)는 클라에서 적용
      if (filter == 'all' || filter == 'canceled') return list;

      final now = DateTime.now();
      return list.where((t) => _matchesFilter(t, filter, now)).toList();
    });
  }

  @override
  Stream<List<TournamentModel>> getMyHostedTournaments({
    required String userUid,
    required String userEmail,
    required int limit,
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> q =
    _tournaments.orderBy('eventDate', descending: true).limit(limit);

    if (startAfter != null) q = q.startAfterDocument(startAfter);

    final emailLower = userEmail.trim().toLowerCase();

    return q.snapshots().map((qs) {
      final all = qs.docs
          .map((d) => TournamentModel.fromJson(d.data()).copyWith(id: d.id))
          .toList();

      return all.where((t) {
        final created = (t.createdByUid == userUid);
        final inOrg = emailLower.isNotEmpty &&
            t.organizerEmails.map((e) => e.toLowerCase()).contains(emailLower);
        return created || inOrg;
      }).toList();
    });
  }

  bool _matchesFilter(TournamentModel t, String filter, DateTime now) {
    if (t.isCanceled == true) return filter == 'canceled';

    final entryStart = t.entryStartDate.toDate();
    final entryEnd = t.entryEndDate.toDate();
    final eventDt = t.eventDate.toDate();

    // ✅ 경계값 통일:
    // - open: entryStart <= now <= entryEnd
    // (너가 UI에서 00:00 ~ 23:59로 고정하니까 "같은 시각"도 포함하는게 자연스러움)
    final isOpen = !now.isBefore(entryStart) && !now.isAfter(entryEnd);

    switch (filter) {
      case 'open':
        return isOpen;
      case 'upcoming':
        return now.isBefore(entryStart);
      case 'closed':
      // 엔트리 마감 후 ~ 대회 전
        return now.isAfter(entryEnd) && now.isBefore(eventDt);
      case 'inProgress':
      // 단순 진행중: eventDt 이후 24시간 이내
        return now.isAfter(eventDt) && now.difference(eventDt).inHours < 24;
      case 'finished':
        return now.isAfter(eventDt);
      default:
        return true;
    }
  }

  // ----------------------
  // Entries (Transaction)
  // ----------------------

  bool _isEntryOpen({
    required DateTime now,
    required DateTime entryStart,
    required DateTime entryEnd,
    required DateTime eventDt,
  }) {
    // ✅ 경계 포함 + 대회 시작 이전이어야 함
    if (now.isBefore(entryStart)) return false;
    if (now.isAfter(entryEnd)) return false;
    if (!now.isBefore(eventDt)) return false;
    return true;
  }

  @override
  Future<void> submitEntry({
    required String tournamentId,
    required TournamentEntryModel entry,
  }) async {
    final tRef = _tRef(tournamentId);
    final eRef = _entriesRef(tournamentId).doc(entry.userUid); // ✅ docId = userUid

    await _db.runTransaction((tx) async {
      final tSnap = await tx.get(tRef);
      if (!tSnap.exists || tSnap.data() == null) {
        throw Exception('대회 정보를 찾을 수 없습니다.');
      }

      final t = TournamentModel.fromJson(tSnap.data()!).copyWith(id: tSnap.id);

      if (t.isCanceled == true) {
        throw Exception('취소된 대회입니다.');
      }

      final now = DateTime.now();
      final entryStart = t.entryStartDate.toDate();
      final entryEnd = t.entryEndDate.toDate();
      final eventDt = t.eventDate.toDate();

      if (!_isEntryOpen(
        now: now,
        entryStart: entryStart,
        entryEnd: entryEnd,
        eventDt: eventDt,
      )) {
        throw Exception('현재는 엔트리 신청이 가능한 시간이 아닙니다.');
      }

      // ✅ 이미 신청했는지
      final exist = await tx.get(eRef);
      if (exist.exists) {
        throw Exception('이미 참가 신청한 유저입니다.');
      }

      // ✅ 정원 체크
      final maxP = t.maxParticipants;
      final currentCount = t.entryCount < 0 ? 0 : t.entryCount;
      if (currentCount >= maxP) {
        throw Exception('정원이 마감되었습니다.');
      }

      tx.set(eRef, entry.toJson());
      tx.update(tRef, {
        'entryCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    });
  }

  @override
  Future<void> cancelEntry({
    required String tournamentId,
    required String userUid,
  }) async {
    final tRef = _tRef(tournamentId);
    final eRef = _entriesRef(tournamentId).doc(userUid);

    await _db.runTransaction((tx) async {
      final tSnap = await tx.get(tRef);
      if (!tSnap.exists || tSnap.data() == null) {
        throw Exception('대회 정보를 찾을 수 없습니다.');
      }

      final t = TournamentModel.fromJson(tSnap.data()!).copyWith(id: tSnap.id);

      if (t.isCanceled == true) {
        throw Exception('취소된 대회입니다.');
      }

      final now = DateTime.now();
      final entryStart = t.entryStartDate.toDate();
      final entryEnd = t.entryEndDate.toDate();
      final eventDt = t.eventDate.toDate();

      // ✅ 정책 통일: “엔트리 오픈 기간”에만 앱 취소 가능
      if (!_isEntryOpen(
        now: now,
        entryStart: entryStart,
        entryEnd: entryEnd,
        eventDt: eventDt,
      )) {
        throw Exception('엔트리 마감 이후에는 앱에서 취소할 수 없습니다.');
      }

      final eSnap = await tx.get(eRef);
      if (!eSnap.exists) {
        throw Exception('참가 신청 내역이 없습니다.');
      }

      tx.delete(eRef);
      tx.update(tRef, {
        'entryCount': FieldValue.increment(-1),
        'updatedAt': Timestamp.now(),
      });
    });

    // ✅ 후처리 보정 (아주 드문 방어)
    final t = await getTournament(tournamentId);
    if (t != null && t.entryCount < 0) {
      await _tRef(tournamentId).update({'entryCount': 0});
    }
  }

  @override
  Stream<List<TournamentEntryModel>> getEntries(String tournamentId) {
    return _entriesRef(tournamentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((qs) => qs.docs
        .map((d) => TournamentEntryModel.fromJson(d.data()).copyWith(id: d.id))
        .toList());
  }
}
