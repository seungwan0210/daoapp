// lib/data/repositories/point_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// 포인트를 실제로 Firestore에 저장하는 곳
class PointRepository {
  final db = FirebaseFirestore.instance;

  /// 포인트 부여하기 (1위, 2위, 3위 + 참가자 10점)
  Future<void> 포인트_부여하기({
  required String 경기ID,
  required String? 일위_선수_UID,
  required String? 이위_선수_UID,
  required String? 삼위_선수_UID,
  required List<String> 참가자_UID_리스트,
}) async {
final batch = db.batch();

// 1위 ~ 3위 포인트
if (일위_선수_UID != null) {
final userRef = db.collection('users').doc(일위_선수_UID);
batch.update(userRef, {
'총포인트': FieldValue.increment(100),
'시즌3': FieldValue.increment(100),
});
}
// 2위, 3위도 동일

// 참가자 10점
for (var uid in 참가자_UID_리스트) {
final userRef = db.collection('users').doc(uid);
batch.update(userRef, {
'총포인트': FieldValue.increment(10),
'시즌3': FieldValue.increment(10),
});
}

await batch.commit();
}
}