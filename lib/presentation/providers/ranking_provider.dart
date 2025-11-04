// lib/presentation/providers/ranking_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/data/repositories/point_record_repository_impl.dart';
import 'package:daoapp/data/repositories/point_record_repository.dart';
import 'package:daoapp/data/models/ranking_user.dart';

final pointRecordRepositoryProvider = Provider<PointRecordRepository>((ref) {
  return PointRecordRepositoryImpl();
});

class RankingNotifier extends StateNotifier<AsyncValue<List<RankingUser>>> {
  final PointRecordRepository _repo;
  StreamSubscription<List<RankingUser>>? _subscription;

  String selectedYear = '2026';
  String selectedPhase = 'total';
  String selectedGender = 'all';
  bool _top9Mode = false;

  // 외부에서 접근 가능한 getter 추가!
  bool get top9Mode => _top9Mode;

  RankingNotifier(this._repo) : super(const AsyncValue.loading()) {
    _subscribeToRanking();
  }

  void updateFilters(String year, String phase, String gender) {
    selectedYear = year;
    selectedPhase = phase;
    selectedGender = gender;

    if (phase == 'total' && _top9Mode) {
      _top9Mode = false;
    }

    _subscribeToRanking();
  }

  void toggleTop9Mode() {
    if (selectedPhase == 'total') return;
    _top9Mode = !_top9Mode;
    _subscribeToRanking();
  }

  void loadRanking() {
    _subscribeToRanking();
  }

  void _subscribeToRanking() {
    state = const AsyncValue.loading();
    _subscription?.cancel();

    _subscription = _repo
        .getRanking(
      seasonId: selectedYear,
      phase: selectedPhase,
      gender: selectedGender,
      top9Mode: _top9Mode && selectedPhase != 'total',
    )
        .listen(
          (data) => state = AsyncValue.data(data),
      onError: (e) => state = AsyncValue.error(e, StackTrace.current),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final rankingProvider = StateNotifierProvider<RankingNotifier, AsyncValue<List<RankingUser>>>((ref) {
  final repo = ref.read(pointRecordRepositoryProvider);
  return RankingNotifier(repo);
});