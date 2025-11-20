// lib/presentation/providers/arena_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';

final arenaRepositoryProvider = Provider<ArenaRepository>((ref) {
  return sl<ArenaRepository>();
});

class ArenaState {
  final List<TournamentModel> tournaments;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final String currentFilter; // 'all', 'open', 'upcoming', 'closed'

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
  final _auth = sl<FirebaseAuth>();
  final _repo = sl<ArenaRepository>();

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
      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));

      Query query = _firestore
          .collection('tournaments')
          .orderBy('eventDate', descending: true);

      // 대회 종료 후 3일 지난 건 일반 사용자에겐 숨김
      query = query.where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(threeDaysAgo));

      switch (state.currentFilter) {
        case 'open':
          query = query
              .where('entryStartDate', isLessThanOrEqualTo: Timestamp.now())
              .where('entryEndDate', isGreaterThanOrEqualTo: Timestamp.now());
          break;
        case 'upcoming':
          query = query.where('entryStartDate', isGreaterThan: Timestamp.now());
          break;
        case 'closed':
          query = query.where('entryEndDate', isLessThan: Timestamp.now());
          break;
        case 'all':
        default:
        // 아무 조건 없이 전체 (종료 3일 지난 건 위에서 이미 필터링됨)
          break;
      }

      if (!reset && state.lastDocument != null) {
        query = query.startAfterDocument(state.lastDocument!);
      }

      final snapshot = await query.limit(_limit).get();

      final newList = snapshot.docs
          .map((doc) => TournamentModel.fromJson(doc.data() as Map<String, dynamic>)
          .copyWith(id: doc.id))
          .toList();

      final updatedList = reset ? newList : [...state.tournaments, ...newList];

      final lastDoc = newList.isNotEmpty
          ? await _firestore.collection('tournaments').doc(newList.last.id).get()
          : state.lastDocument;

      state = state.copyWith(
        tournaments: updatedList,
        isLoading: false,
        hasMore:  newList.length == _limit,
        lastDocument: lastDoc,
      );
    } catch (e) {
      print('Arena load error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(tournaments: [], lastDocument: null, hasMore: true);
    await loadTournaments(reset: true);
  }
}

final arenaProvider = StateNotifierProvider<ArenaNotifier, ArenaState>((ref) {
  return ArenaNotifier();
});