// lib/presentation/providers/arena_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/core/utils/arena_utils.dart'; // nowKst()

final arenaRepositoryProvider = Provider<ArenaRepository>((ref) {
  return sl<ArenaRepository>();
});

class ArenaState {
  final List<TournamentModel> tournaments;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final String currentFilter; // all, open, upcoming, closed

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

  /// 필터 변경
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

  /// Firestore 쿼리 = eventDate 하나만 사용하여 가져오기
  /// open/upcoming/closed 필터는 앱단(Dart)에서 처리
  Future<void> loadTournaments({bool reset = false}) async {
    if (state.isLoading || (!state.hasMore && !reset)) return;

    state = state.copyWith(isLoading: true);

    try {
      final now = nowKst();
      final threeDaysAgo = now.subtract(const Duration(days: 3));

      Query query = _firestore
          .collection('tournaments')
          .orderBy('eventDate', descending: true)
          .where('eventDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(threeDaysAgo));

      if (!reset && state.lastDocument != null) {
        query = query.startAfterDocument(state.lastDocument!);
      }

      final snapshot = await query.limit(_limit).get();

      final fetched = snapshot.docs
          .map((doc) => TournamentModel.fromJson(doc.data() as Map<String, dynamic>)
          .copyWith(id: doc.id))
          .toList();

      // 🔍 여기서 필터링(Open/Upcoming/Closed)
      final filtered = _applyFilter(
        list: fetched,
        filter: state.currentFilter,
        now: now,
      );

      final updatedList = reset
          ? filtered
          : [...state.tournaments, ...filtered];

      final lastDoc = fetched.isNotEmpty
          ? snapshot.docs.last
          : state.lastDocument;

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

  /// Dart단 필터링
  List<TournamentModel> _applyFilter({
    required List<TournamentModel> list,
    required String filter,
    required DateTime now,
  }) {
    return list.where((t) {
      final start = t.entryStartDate.toDate();
      final end = t.entryEndDate.toDate();

      switch (filter) {
        case 'open':
          return start.isBefore(now) && end.isAfter(now);
        case 'upcoming':
          return start.isAfter(now);
        case 'closed':
          return end.isBefore(now);
        default:
          return true;
      }
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

final arenaProvider =
StateNotifierProvider<ArenaNotifier, ArenaState>((ref) {
  return ArenaNotifier();
});
