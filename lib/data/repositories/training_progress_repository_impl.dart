// lib/data/repositories/training_progress_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/data/models/training_progress_model.dart';
import 'package:daoapp/data/repositories/training_progress_repository.dart';

class TrainingProgressRepositoryImpl implements TrainingProgressRepository {
  final FirebaseFirestore _firestore;

  TrainingProgressRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// users/{userId}/trainingMeta/trainingProgress
  DocumentReference<Map<String, dynamic>> _progressDoc(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingMeta')
        .doc('trainingProgress');
  }

  /// 🔹 새 유저용 기본 Progress 생성
  ///    👉 이제 tier와 상관없이 무조건 cycleSize = 1000
  TrainingProgressModel _initialProgressForNewUser(String userId) {
    const DaoTrainingTier defaultTier = DaoTrainingTier.beginner;

    return TrainingProgressModel.initial(
      userId: userId,
      tier: defaultTier,
      cycleSize: 1000,   // <── 여기 고정
    );
  }

  @override
  Future<TrainingProgressModel> getProgress(String userId) async {
    final doc = await _progressDoc(userId).get();
    final data = doc.data();

    if (!doc.exists || data == null) {
      return _initialProgressForNewUser(userId);
    }

    return TrainingProgressModel.fromJson(
      userId,
      data,
    );
  }

  @override
  Stream<TrainingProgressModel> watchProgress(String userId) {
    return _progressDoc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return _initialProgressForNewUser(userId);
      }
      return TrainingProgressModel.fromJson(userId, data);
    });
  }

  @override
  Future<TrainingProgressModel> addXp({
    required String userId,
    required int xpToAdd,
  }) async {
    if (xpToAdd <= 0) {
      return getProgress(userId);
    }

    return _firestore.runTransaction<TrainingProgressModel>((tx) async {
      final docRef = _progressDoc(userId);
      final snapshot = await tx.get(docRef);

      TrainingProgressModel current;
      if (!snapshot.exists || snapshot.data() == null) {
        current = _initialProgressForNewUser(userId);
      } else {
        current = TrainingProgressModel.fromJson(
          userId,
          snapshot.data() as Map<String, dynamic>,
        );
      }

      // XP 증가
      final updated = current.withAddedXp(xpToAdd);

      tx.set(docRef, updated.toJson(), SetOptions(merge: true));
      return updated;
    });
  }

  @override
  Future<TrainingProgressModel> markRatingChecked({
    required String userId,
    required DaoTrainingTier newTier,
  }) async {
    return _firestore.runTransaction<TrainingProgressModel>((tx) async {
      final docRef = _progressDoc(userId);
      final snapshot = await tx.get(docRef);

      TrainingProgressModel current;
      if (!snapshot.exists || snapshot.data() == null) {
        current = TrainingProgressModel.initial(
          userId: userId,
          tier: newTier,
          cycleSize: 1000,   // <── 최초 생성도 동일
        );
      } else {
        current = TrainingProgressModel.fromJson(
          userId,
          snapshot.data() as Map<String, dynamic>,
        );
      }

      // 🔁 레이팅 체크 시 cycleSize도 1000으로 재설정
      final updated = current.withRatingChecked(
        newTier: newTier,
        newCycleSize: 1000,  // <── 여기 고정
      );

      tx.set(docRef, updated.toJson(), SetOptions(merge: true));
      return updated;
    });
  }
}
