import 'package:daoapp/di/service_locator.dart'; // sl이 정의된 파일
import 'package:daoapp/data/repositories/chat_repository.dart';
import 'package:daoapp/data/models/chat_message_model.dart';

class ChatUtils {
  static Future<void> sendSystemNotice(String message) async {
    // ❌ final chatRepo = getIt<ChatRepository>();
    // ✅ sl로 수정
    final chatRepo = sl<ChatRepository>();

    final systemMsg = ChatMessage(
      id: '',
      uid: 'SYSTEM_BOT',
      userName: 'DAO 시스템',
      message: message,
      type: 'SYSTEM',
      timestamp: DateTime.now(),
    );

    await chatRepo.sendMessage(systemMsg);
  }
}