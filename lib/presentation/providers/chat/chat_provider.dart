import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/data/repositories/chat_repository.dart';
import 'package:daoapp/data/models/chat_message_model.dart';
// ✅ 차단 목록 프로바이더를 쓰기 위해 임포트 추가
import 'package:daoapp/presentation/providers/app_providers.dart';

/// 1. 원본 채팅 스트림 (DB에서 가져오는 쌩 데이터)
/// 이름을 rawChatStreamProvider로 변경하여 내부에서만 관리합니다.
final rawChatStreamProvider = StreamProvider.autoDispose<List<ChatMessage>>((ref) {
  final chatRepo = sl<ChatRepository>();
  return chatRepo.getChatStream();
});

/// 2. ✅ 필터링된 채팅 프로바이더 (실제로 UI에서 사용할 것)
/// 차단된 유저의 메시지를 실시간으로 걸러냅니다.
final filteredChatProvider = Provider.autoDispose<AsyncValue<List<ChatMessage>>>((ref) {
  // 원본 메시지 감시
  final chatAsync = ref.watch(rawChatStreamProvider);
  // 중앙 차단 목록 감시
  final blockedIdsAsync = ref.watch(blockedUserIdsProvider);

  return chatAsync.whenData((messages) {
    // 차단 목록 데이터가 없으면 빈 Set으로 처리
    final blockedIds = blockedIdsAsync.value ?? {};

    // 🔥 차단된 유저의 UID가 없는 메시지만 필터링
    return messages.where((m) => !blockedIds.contains(m.uid)).toList();
  });
});

/// 3. 채팅 전송 및 상태 관리를 위한 Notifier
final chatProvider = StateNotifierProvider<ChatNotifier, AsyncValue<void>>((ref) {
  return ChatNotifier(sl<ChatRepository>());
});

class ChatNotifier extends StateNotifier<AsyncValue<void>> {
  final ChatRepository _repository;

  ChatNotifier(this._repository) : super(const AsyncValue.data(null));

  /// 메시지 전송 로직
  Future<void> sendMessage({
    required String uid,
    required String userName,
    String? userProfile,
    required String message,
    String type = 'USER',
  }) async {
    state = const AsyncValue.loading();

    try {
      final newMessage = ChatMessage(
        id: '',
        uid: uid,
        userName: userName,
        userProfile: userProfile,
        message: message,
        type: type,
        timestamp: DateTime.now(),
      );

      await _repository.sendMessage(newMessage);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 메시지 삭제 로직
  Future<void> deleteMessage(String chatId) async {
    try {
      await _repository.deleteMessage(chatId);
    } catch (e) {
      // 삭제 실패 로직
    }
  }
}