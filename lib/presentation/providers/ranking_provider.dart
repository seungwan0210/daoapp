// lib/presentation/providers/ranking_provider.dart
import 'dart:async'; // 이 줄 추가!
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/point_record_repository.dart';
import '../../data/models/ranking_user.dart';

class RankingProvider extends ChangeNotifier {
  final PointRecordRepository _repo;

  List<RankingUser> _rankings = [];
  bool _loading = false;
  StreamSubscription<List<RankingUser>>? _subscription;

  String selectedYear = '2026';
  String selectedPhase = 'season1';
  String selectedGender = 'male';

  List<RankingUser> get rankings => _rankings;
  bool get loading => _loading;

  RankingProvider(this._repo) {
    _subscribeToRanking();
  }

  void updateFilters(String year, String phase, String gender) {
    selectedYear = year;
    selectedPhase = phase;
    selectedGender = gender;
    _subscribeToRanking();
  }

  void loadRanking() {
    _subscribeToRanking(); // 강제 재구독 → 실시간 반영
  }

  void _subscribeToRanking() {
    _loading = true;
    notifyListeners();

    _subscription?.cancel();

    _subscription = _repo
        .getRanking(
      seasonId: selectedYear,
      phase: selectedPhase,
      gender: selectedGender,
    )
        .listen(
          (data) {
        _rankings = data;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        _loading = false;
        notifyListeners();
        debugPrint('Ranking error: $e');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}