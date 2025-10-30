// lib/presentation/providers/ranking_provider.dart
import 'dart:async';
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
  String selectedPhase = 'total'; // 통합 기본값
  String selectedGender = 'male';
  bool _top9Mode = false; // 상위 9개 모드

  List<RankingUser> get rankings => _rankings;
  bool get loading => _loading;
  bool get top9Mode => _top9Mode;

  RankingProvider(this._repo) {
    _subscribeToRanking();
  }

  void updateFilters(String year, String phase, String gender) {
    selectedYear = year;
    selectedPhase = phase;
    selectedGender = gender;

    // 통합으로 변경 시 상위 9개 자동 비활성화
    if (phase == 'total' && _top9Mode) {
      _top9Mode = false;
    }

    _subscribeToRanking();
  }

  void toggleTop9Mode() {
    // 통합에서는 토글 불가
    if (selectedPhase == 'total') {
      return;
    }

    _top9Mode = !_top9Mode;
    _subscribeToRanking();
    notifyListeners();
  }

  void loadRanking() {
    _subscribeToRanking();
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
      top9Mode: _top9Mode && selectedPhase != 'total', // 통합이면 false
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