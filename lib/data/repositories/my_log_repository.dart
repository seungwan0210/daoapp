// lib/data/repositories/my_log_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/my_log_model.dart';

class MyLogRepository {
  // ✅ 타입까지 명시 (Map<String, dynamic>)
  final CollectionReference<Map<String, dynamic>> _myLogsCollection =
  FirebaseFirestore.instance.collection('my_logs');

  final CollectionReference<Map<String, dynamic>> _communityCollection =
  FirebaseFirestore.instance.collection('community');

  // 🔹 내 마이로그 전체 가져오기 (최신순)
  Stream<List<MyLogModel>> getMyLogs(String userId) {
    return _myLogsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (doc) => MyLogModel.fromJson(doc.data()).copyWith(id: doc.id),
      )
          .toList(),
    );
  }

  // 🔹 단일 마이로그 감시 (상세 화면에서 사용)
  Stream<MyLogModel?> watchLog(String logId) {
    return _myLogsCollection.doc(logId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      return MyLogModel.fromJson(data).copyWith(id: doc.id);
    });
  }

  // 🔹 마이로그 저장 (생성 or 수정) → 항상 logId 반환
  Future<String> saveLog(MyLogModel log) async {
    // toJson에서 id는 제거하고, userId는 반드시 포함되도록 보정
    final data = <String, dynamic>{
      ...log.toJson()..remove('id'),
    };

    // ⚠️ 혹시라도 모델에 userId가 안 들어왔을 경우 대비 (규칙 통과용)
    if (!data.containsKey('userId') || data['userId'] == null) {
      data['userId'] = log.userId;
    }

    if (log.id == null) {
      // 신규 생성
      final docRef = await _myLogsCollection.add(data);
      // 문서 안에도 id 저장 (선택 사항이지만 디버깅에 도움)
      await docRef.update({'id': docRef.id});
      return docRef.id;
    } else {
      // 기존 수정
      await _myLogsCollection.doc(log.id).update(data);
      return log.id!;
    }
  }

  // 🔹 마이로그 삭제 + 연결된 피드 글도 같이 삭제
  Future<void> deleteLog(String logId) async {
    // 1) 먼저, 이 일기에서 공유된 피드 글 찾아서 삭제
    final relatedPosts = await _communityCollection
        .where('fromMyLog', isEqualTo: true)
        .where('originalMyLogId', isEqualTo: logId)
        .get();

    for (final doc in relatedPosts.docs) {
      await doc.reference.delete();
    }

    // 2) 마지막으로, 마이로그 자체 삭제
    await _myLogsCollection.doc(logId).delete();
  }

  // 🔹 서클(피드)에 공유하기
  Future<void> shareToCircle(MyLogModel log) async {
    if (log.content == null || log.content!.trim().isEmpty) return;

    final shareContent = """
${log.content!.trim()}

— 마이로그에서 공유됨 —
""";

    await _communityCollection.add({
      'userId': log.userId,
      'content': shareContent.trim(),
      // ✅ 사진 여러 장 지원 (없으면 빈 리스트)
      'imageUrls': log.photoUrls,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'comments': 0,
      // ✅ 마이로그에서 왔다는 표시
      'fromMyLog': true,
      'originalMyLogId': log.id,
      'isSharedFromMyLog': true,
    });

    // 마이로그 문서에도 “공유 완료” 표시
    if (log.id != null) {
      await _myLogsCollection.doc(log.id).update({
        'isSharedToCircle': true,
      });
    }
  }
}
