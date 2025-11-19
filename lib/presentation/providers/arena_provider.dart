// lib/presentation/providers/arena_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 이거 추가!

// ===================== 여기부터 추가 (제일 위나 아래 아무 데나) =====================
final arenaProvider = ChangeNotifierProvider<ArenaProvider>((ref) {
  return ArenaProvider();
});
// ===============================================================================

class ArenaProvider extends ChangeNotifier {
  final ArenaRepository _repository = sl<ArenaRepository>();
  final User? _currentUser = sl<FirebaseAuth>().currentUser;

  String _selectedFilter = 'all';
  String get selectedFilter => _selectedFilter;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<TournamentModel> _tournaments = [];
  List<TournamentModel> get tournaments => _tournaments;

  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  void changeFilter(String filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    _tournaments.clear();
    _lastDocument = null;
    _hasMore = true;
    notifyListeners();
    loadMore(reset: true);
  }

  Future<void> loadMore({bool reset = false}) async {
    if (_isLoading || (!_hasMore && !reset) || _currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final stream = _selectedFilter == 'my_hosted'
          ? _repository.getMyHostedTournaments(
        userUid: _currentUser!.uid,
        userEmail: _currentUser!.email ?? '',
        limit: 10,
        startAfter: reset ? null : _lastDocument,
      )
          : _repository.getTournaments(
        filter: _selectedFilter == 'all' ? '' : _selectedFilter,
        limit: 10,
        startAfter: reset ? null : _lastDocument,
      );

      final list = await stream.first;

      if (list.isEmpty) {
        _hasMore = false;
      } else {
        if (reset) {
          _tournaments = list;
        } else {
          _tournaments.addAll(list);
        }
        _lastDocument = list.last.id != null
            ? await FirebaseFirestore.instance
            .collection('tournaments')
            .doc(list.last.id)
            .get()
            : null;
        _hasMore = list.length == 10;
      }
    } catch (e) {
      debugPrint('Arena load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}