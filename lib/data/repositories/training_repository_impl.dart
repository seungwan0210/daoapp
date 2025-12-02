// lib/data/repositories/training_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/data/repositories/training_repository.dart';

class TrainingRepositoryImpl implements TrainingRepository {
  final FirebaseFirestore _firestore;

  TrainingRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sessionCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingSessions');
  }

  @override
  Future<String> createSession(TrainingSessionModel session) async {
    final ref = await _sessionCollection(session.userId).add(session.toJson());
    return ref.id;
  }

  @override
  Future<void> updateSession(TrainingSessionModel session) async {
    if (session.id == null || session.id!.isEmpty) {
      throw ArgumentError('Session id is required for update.');
    }
    await _sessionCollection(session.userId)
        .doc(session.id)
        .update(session.toJson());
  }

  @override
  Stream<List<TrainingSessionModel>> watchRecentSessions({
    required String userId,
    int limit = 50, // 🔹 인터페이스 기본값과 맞춤
  }) {
    return _sessionCollection(userId)
        .orderBy('endedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        return TrainingSessionModel.fromJson(doc.id, doc.data());
      }).toList();
    });
  }

  @override
  Future<List<TrainingSessionModel>> fetchSessionsByDrill({
    required String userId,
    required String drillId,
    int limit = 100, // 🔹 인터페이스 기본값과 맞춤
  }) async {
    final snap = await _sessionCollection(userId)
        .where('drillId', isEqualTo: drillId)
        .orderBy('endedAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs
        .map((doc) => TrainingSessionModel.fromJson(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<TrainingSessionModel?> fetchLastSessionForDrill({
    required String userId,
    required String drillId,
  }) async {
    final snap = await _sessionCollection(userId)
        .where('drillId', isEqualTo: drillId)
        .orderBy('endedAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return TrainingSessionModel.fromJson(doc.id, doc.data());
  }
}
