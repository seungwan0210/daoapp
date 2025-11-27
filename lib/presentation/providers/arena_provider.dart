// lib/presentation/providers/arena_provider.dart (최종 완벽 버전)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/core/utils/arena_utils.dart';

final arenaRepositoryProvider = Provider<ArenaRepository>((ref) {
  return sl<ArenaRepository>();
});

class ArenaState {
  final List<TournamentModel> tournaments;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final String currentFilter;

  ArenaState({
    this.tournaments = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDocument,
    this.currentFilter = 'all',
  });

  ArenaState copyWith({
    List<TournamentModel>? tournaments,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    String? currentFilter,
  }) {
    return ArenaState(
      tournaments: tournaments ?? this.tournaments,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

class ArenaNotifier extends StateNotifier<ArenaState> {
  ArenaNotifier() : super(ArenaState()) {
    loadTournaments(reset: true);
  }

  final _limit = 12;
  final _firestore = FirebaseFirestore.instance;

  Future<void> changeFilter(String filter) async {
    if (state.currentFilter == filter) return;

    state = state.copyWith(
      currentFilter: filter,
      tournaments: [],
      lastDocument: null,
      hasMore: true,
    );

    await loadTournaments(reset: true);
  }

  Future<void> loadTournaments({bool reset = false}) async {
    if (state.isLoading || (!state.hasMore && !reset)) return;

    state = state.copyWith(isLoading: true);

    try {
      final now = nowKst(); // ← 최신 nowKst() 사용

      final sixMonthsAgo = Timestamp.fromDate(
        now.subtract(const Duration(days: 180)),
      );

      Query query = _firestore
          .collection('tournaments')
          .orderBy('eventDate', descending: true)
          .where('eventDate', isGreaterThanOrEqualTo: sixMonthsAgo);

      if (!reset && state.lastDocument != null) {
        query = query.startAfterDocument(state.lastDocument!);
      }

      final snapshot = await query.limit(_limit).get();

      final fetched = snapshot.docs
          .where((doc) => doc.exists)
          .map((doc) => TournamentModel.fromJson(doc.data() as Map<String, dynamic>)
          .copyWith(id: doc.id))
          .toList();

      final filtered = _applyFilter(
        list: fetched,
        filter: state.currentFilter,
        now: now, // ← now 전달 필수!
      );

      final updatedList = reset ? filtered : [...state.tournaments, ...filtered];
      final lastDoc = fetched.isNotEmpty ? snapshot.docs.last : state.lastDocument;

      state = state.copyWith(
        tournaments: updatedList,
        isLoading: false,
        hasMore: fetched.length == _limit,
        lastDocument: lastDoc,
      );
    } catch (e) {
      print('Arena load error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  // ← 이 함수만 정확하면 모든 게 해결됨 (완전 정답 버전)
  List<TournamentModel> _applyFilter({
    required List<TournamentModel> list,
    required String filter,
    required DateTime now,
  }) {
    return list.where((t) {
      // 100% 정확한 상태 판단 → ArenaUtils.getEntryStatus() 재사용
      final status = ArenaUtils.getEntryStatus(
        entryStartDate: t.entryStartDate,
        entryEndDate: t.entryEndDate,
        eventDate: t.eventDate,
      );

      return switch (filter) {
        'open' => status == EntryStatus.open,
        'upcoming' => status == EntryStatus.upcoming,
        'closed' => status == EntryStatus.closed,
        'inProgress' => status == EntryStatus.inProgress,
        _ => true, // 'all' 또는 기타 필터
      };
    }).toList();
  }

  Future<void> refresh() async {
    state = state.copyWith(
      tournaments: [],
      lastDocument: null,
      hasMore: true,
    );
    await loadTournaments(reset: true);
  }
}

final arenaProvider = StateNotifierProvider<ArenaNotifier, ArenaState>((ref) {
  return ArenaNotifier();
});