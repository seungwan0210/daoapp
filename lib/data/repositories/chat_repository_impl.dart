import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'chat_repository.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepositoryImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  @override
  Stream<List<ChatMessage>> getChatStream() {
    return _firestore
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        try {
          // JSON 데이터를 ChatMessage 모델로 변환 (ID 포함)
          return ChatMessage.fromJson({
            ...data,
            'id': doc.id,
          });
        } catch (e) {
          // 데이터 구조가 모델과 맞지 않을 때만 에러 로그 출력
          debugPrint('❌ [ChatRepository] 모델 파싱 실패 (ID: ${doc.id}): $e');
          rethrow;
        }
      }).toList();
    });
  }

  @override
  Future<void> sendMessage(ChatMessage message) async {
    try {
      final chatCollection = _firestore.collection('chats');

      // 1. 모델을 JSON으로 변환
      final Map<String, dynamic> data = message.toJson();

      // 2. ID는 Firestore 문서 생성 시 자동 부여되므로 데이터에서 제거
      data.remove('id');

      // 3. category나 targetId가 null로 전송되는 것 방지 (방어적 코드)
      data['category'] = data['category'] ?? '';
      data['targetId'] = data['targetId'] ?? '';

      // 4. 전송 시간은 서버 타임스탬프 권장
      data['timestamp'] = FieldValue.serverTimestamp();

      await chatCollection.add(data);
    } catch (e) {
      debugPrint('❌ [ChatRepository] 메시지 전송 실패: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      debugPrint('❌ [ChatRepository] 메시지 삭제 실패 (ID: $chatId): $e');
      rethrow;
    }
  }
}