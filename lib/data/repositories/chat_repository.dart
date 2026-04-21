import '../models/chat_message_model.dart';

abstract class ChatRepository {
  /// 최신 채팅 메시지 100개를 실시간 스트림으로 가져옵니다.
  Stream<List<ChatMessage>> getChatStream();

  /// 새로운 채팅 메시지를 전송합니다.
  Future<void> sendMessage(ChatMessage message);

  /// 특정 메시지를 삭제합니다 (본인 또는 어드민).
  Future<void> deleteMessage(String chatId);
}