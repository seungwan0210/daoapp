import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_repository.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepositoryImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  @override
  Stream<List<ChatMessage>> getChatStream() {
    return _firestore
        .collection('chats')
        .orderBy('timestamp', descending: true) // 최신순으로 가져옴
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage.fromJson({
          ...data,
          'id': doc.id,
        });
      }).toList(); // ❌ .reversed.toList() 를 제거했습니다!
    });
  }

  @override
  Future<void> sendMessage(ChatMessage message) async {
    final chatCollection = _firestore.collection('chats');

    // 모델을 JSON으로 변환
    final Map<String, dynamic> data = message.toJson();

    // ID는 문서 생성 시 자동 부여되므로 제거
    data.remove('id');

    // 규칙상 서버 타임스탬프가 권장되므로 전송 직전에 교체
    data['timestamp'] = FieldValue.serverTimestamp();

    await chatCollection.add(data);
  }

  @override
  Future<void> deleteMessage(String chatId) async {
    await _firestore.collection('chats').doc(chatId).delete();
  }
}