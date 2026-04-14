// lib/presentation/providers/arena_provider.dart
// ✅ 실시간 + 페이지네이션 구조 유지
// ✅ allTournaments(원본) 추가: 프리뷰/기타 화면에서 필터 영향 없이 안전하게 사용 가능

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/core/utils/arena_utils.dart';
import 'package:daoapp/core/utils/date_utils.dart'; // nowKst()
import 'package:daoapp/data/models/tournament_model.dart';

class ArenaState {
  /// ✅ 필터 적용 전 원본 합본 리스트 (realtime + older merge)
  final List<TournamentModel> allTournaments;

  /// ✅ UI가 주로 쓰는 필터 적용 리스트
  final List<TournamentModel> tournaments;

  final bool isLoading;

  /// ✅ 페이징 더 가져올 수 있는지
  final bool hasMore;

  /// ✅ older 페이지네이션 마지막 문서
  final DocumentSnapshot<Map<String, dynamic>>? pagingLastDoc;

  final String currentFilter;

  const ArenaState({
    this.allTournaments = const [],
    this.tournaments = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.pagingLastDoc,
    this.currentFilter = 'all',
  });

  ArenaState copyWith({
    List<TournamentModel>? allTournaments,
    List<TournamentModel>? tournaments,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot<Map<String, dynamic>>? pagingLastDoc,
    String? currentFilter,
  }) {
    return ArenaState(
      allTournaments: allTournaments ?? this.allTournaments,
      tournaments: tournaments ?? this.tournaments,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      pagingLastDoc: pagingLastDoc ?? this.pagingLastDoc,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

class ArenaNotifier extends StateNotifier<ArenaState> {
  ArenaNotifier() : super(const ArenaState()) {
    _startRealtime(reset: true);
  }

  final int _limit = 12;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _realtimeSub;

  // ✅ 실시간(상위 최신 N개) + 페이지네이션(그 아래)
  List<TournamentModel> _realtimeRaw = [];
  List<TournamentModel> _olderRaw = [];

  /// ✅ 실시간 구간 마지막 문서(older 페이징 시작점)
  QueryDocumentSnapshot<Map<String, dynamic>>? _realtimeLastDocForPaging;

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  /// ✅ 필터 변경:
  /// - 실시간 구독을 리셋하지 않는다(딜레이/읽기 증가 방지)
  /// - 현재 allTournaments 기준으로 tournaments만 다시 계산
  Future<void> changeFilter(String filter) async {
    if (state.currentFilter == filter) return;

    final filtered = _applyFilter(list: state.allTournaments, filter: filter);

    state = state.copyWith(
      currentFilter: filter,
      tournaments: filtered,
    );
  }

  /// ✅ Pull-to-refresh 같은 “전체 새로고침”
  Future<void> refresh() async {
    state = state.copyWith(
      allTournaments: const [],
      tournaments: const [],
      pagingLastDoc: null,
      hasMore: true,
      isLoading: false,
      currentFilter: state.currentFilter, // 유지
    );
    await _startRealtime(reset: true);
  }

  /// ✅ “더보기” 버튼/무한스크롤에서 호출
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final now = nowKst();
      final sixMonthsAgo = Timestamp.fromDate(
        now.subtract(const Duration(days: 180)),
      );

      Query<Map<String, dynamic>> query = _firestore
          .collection('tournaments')
          .orderBy('eventDate', descending: true)
          .where('eventDate', isGreaterThanOrEqualTo: sixMonthsAgo);

      // ✅ 페이징 시작점:
      // 1) 이미 older를 가져온 적이 있으면 pagingLastDoc 이어서
      // 2) 아니면 실시간 구간의 마지막 문서부터 시작
      final startAfter = state.pagingLastDoc ?? _realtimeLastDocForPaging;
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.limit(_limit).get();

      final fetchedRaw = snapshot.docs
          .where((doc) => doc.exists)
          .map((doc) => TournamentModel.fromJson(doc.data()).copyWith(id: doc.id))
          .toList();

      // ✅ 중복 제거(실시간/older에 이미 있으면 제외)
      final existingIds = <String>{
        for (final t in _realtimeRaw) (t.id ?? '').trim(),
        for (final t in _olderRaw) (t.id ?? '').trim(),
      };

      final fetched = fetchedRaw.where((t) {
        final id = (t.id ?? '').trim();
        return id.isNotEmpty && !existingIds.contains(id);
      }).toList();

      _olderRaw = [..._olderRaw, ...fetched];

      final bool hasMore =
          snapshot.docs.length == _limit && snapshot.docs.isNotEmpty;

      // ✅ 원본(all)
      final mergedAll = _mergeAndSortAll([..._realtimeRaw, ..._olderRaw]);

      // ✅ 필터 적용
      final mergedFiltered = _applyFilter(
        list: mergedAll,
        filter: state.currentFilter,
      );

      state = state.copyWith(
        allTournaments: mergedAll,
        tournaments: mergedFiltered,
        isLoading: false,
        hasMore: hasMore,
        pagingLastDoc:
        snapshot.docs.isNotEmpty ? snapshot.docs.last : state.pagingLastDoc,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Arena loadMore error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// ✅ 초기/리셋 시 실시간 구독
  Future<void> _startRealtime({required bool reset}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    if (reset) {
      _olderRaw = [];
      _realtimeRaw = [];
      _realtimeLastDocForPaging = null;

      await _realtimeSub?.cancel();
      _realtimeSub = null;

      state = state.copyWith(
        allTournaments: const [],
        tournaments: const [],
        pagingLastDoc: null,
        hasMore: true,
      );
    }

    try {
      final now = nowKst();
      final sixMonthsAgo = Timestamp.fromDate(
        now.subtract(const Duration(days: 180)),
      );

      final query = _firestore
          .collection('tournaments')
          .orderBy('eventDate', descending: true)
          .where('eventDate', isGreaterThanOrEqualTo: sixMonthsAgo)
          .limit(_limit);

      _realtimeSub = query.snapshots().listen(
            (snapshot) {
          final realtime = snapshot.docs
              .where((doc) => doc.exists)
              .map((doc) =>
              TournamentModel.fromJson(doc.data()).copyWith(id: doc.id))
              .toList();

          _realtimeRaw = realtime;

          // ✅ 실시간 구간 마지막 문서 = older 페이징 시작점
          _realtimeLastDocForPaging =
          snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

          // ✅ older 중에서 실시간과 겹치면 제거
          final realtimeIds = <String>{
            for (final t in _realtimeRaw) (t.id ?? '').trim(),
          };

          _olderRaw = _olderRaw.where((t) {
            final id = (t.id ?? '').trim();
            return id.isNotEmpty && !realtimeIds.contains(id);
          }).toList();

          // ✅ 원본(all)
          final mergedAll = _mergeAndSortAll([..._realtimeRaw, ..._olderRaw]);

          // ✅ 필터 적용
          final mergedFiltered = _applyFilter(
            list: mergedAll,
            filter: state.currentFilter,
          );

          state = state.copyWith(
            allTournaments: mergedAll,
            tournaments: mergedFiltered,
            isLoading: false,
            // pagingLastDoc는 “더보기 진행 상태”라 유지
            pagingLastDoc: state.pagingLastDoc,
          );
        },
        onError: (e) {
          // ignore: avoid_print
          print('Arena realtime error: $e');
          state = state.copyWith(isLoading: false);
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print('Arena realtime setup error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// ✅ 합치고 eventDate desc 정렬 + id 중복 제거
  List<TournamentModel> _mergeAndSortAll(List<TournamentModel> list) {
    final map = <String, TournamentModel>{};

    for (final t in list) {
      final id = (t.id ?? '').trim();
      if (id.isEmpty) continue;
      map[id] = t;
    }

    final merged = map.values.toList();

    merged.sort((a, b) {
      final aDate = a.eventDate.toDate();
      final bDate = b.eventDate.toDate();
      return bDate.compareTo(aDate);
    });

    return merged;
  }

  /// ✅ 필터 의미를 UI와 1:1로 맞춤
  List<TournamentModel> _applyFilter({
    required List<TournamentModel> list,
    required String filter,
  }) {
    return list.where((t) {
      final status = ArenaUtils.getEntryStatus(
        entryStartDate: t.entryStartDate,
        entryEndDate: t.entryEndDate,
        eventDate: t.eventDate,
      );

      switch (filter) {
        case 'open':
          return status == EntryStatus.open;
        case 'upcoming':
          return status == EntryStatus.upcoming;
        case 'closed':
          return status == EntryStatus.closed ||
              status == EntryStatus.inProgress ||
              status == EntryStatus.finished;
        case 'inProgress':
          return status == EntryStatus.inProgress;
        default:
          return true; // all
      }
    }).toList();
  }
}

final arenaProvider = StateNotifierProvider<ArenaNotifier, ArenaState>((ref) {
  return ArenaNotifier();
});
