// lib/presentation/providers/ranking_provider.dart
import 'package:flutter/foundation.dart';
import '../../data/repositories/point_record_repository.dart';
import '../../data/models/ranking_user.dart';

class RankingProvider extends ChangeNotifier {
  final PointRecordRepository _repo;

  List<RankingUser> _rankings = [];
  bool _loading = false;

  String selectedYear = '2026';
  String selectedPhase = 'season1'; // 기본값
  String selectedGender = 'male';

  List<RankingUser> get rankings => _rankings;
  bool get loading => _loading;

  RankingProvider(this._repo) {
    loadRanking();
  }

  void updateFilters(String year, String phase, String gender) {
    selectedYear = year;
    selectedPhase = phase;
    selectedGender = gender;
    loadRanking();
  }

  void loadRanking() {
    _loading = true;
    notifyListeners();

    _repo.getRanking(
      seasonId: selectedYear,
      phase: selectedPhase,
      gender: selectedGender,
    ).listen((data) {
      _rankings = data;
      _loading = false;
      notifyListeners();
    });
  }
}