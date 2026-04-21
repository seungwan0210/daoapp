import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ 수정된 chat_provider와 중앙 차단 목록을 쓰기 위해 임포트 확인
import 'package:daoapp/presentation/providers/chat/chat_provider.dart';
import 'package:daoapp/presentation/screens/community/chat/widgets/chat_message_bubble.dart';
import 'package:daoapp/presentation/screens/community/chat/widgets/chat_input_field.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // 🔥 [핵심 수정] 이제 StreamBuilder를 쓰지 않고
    // 이미 필터링이 완료된 filteredChatProvider를 바로 구독합니다.
    final chatAsync = ref.watch(filteredChatProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      // ❌ [수정] OverlaySheet에서 헤더를 담당하므로 AppBar는 삭제합니다.
      appBar: null,
      body: currentUserId == null
          ? const Center(child: Text('로그인이 필요합니다.', style: TextStyle(color: Colors.white)))
          : Column(
        children: [
          // ❌ [수정] OverlaySheet와 중복되는 상단 핸들러(회색 바) 제거
          Expanded(
            child: chatAsync.when(
              data: (visibleMessages) {
                if (visibleMessages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // 하단부터 정렬
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), // 상단 패딩 조절
                  itemCount: visibleMessages.length,
                  itemBuilder: (context, index) {
                    return ChatMessageBubble(
                      message: visibleMessages[index],
                      isMe: visibleMessages[index].uid == currentUserId,
                    );
                  },
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.teal)),
              error: (e, __) => const Center(
                  child: Text('에러 발생',
                      style: TextStyle(color: Colors.white24))),
            ),
          ),
          SafeArea(
            top: false,
            child: ChatInputField(currentUserId: currentUserId),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 48, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 12),
          Text(
            'DAO 라이브 톡에 오신 것을 환영합니다!\n첫 번째 메시지를 남겨보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}