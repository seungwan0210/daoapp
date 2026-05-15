import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/presentation/providers/chat/chat_provider.dart';
import 'package:daoapp/presentation/screens/community/chat/widgets/chat_message_bubble.dart';
import 'package:daoapp/presentation/screens/community/chat/widgets/chat_input_field.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

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
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // 필터링이 완료된 채팅 프로바이더 구독
    final chatAsync = ref.watch(filteredChatProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      appBar: null, // OverlaySheet에서 헤더 담당
      body: currentUserId == null
          ? Center(child: Text(s.chat_login_required, style: const TextStyle(color: Colors.white))) // 🔹 다국어 적용
          : Column(
        children: [
          Expanded(
            child: chatAsync.when(
              data: (visibleMessages) {
                if (visibleMessages.isEmpty) {
                  return _buildEmptyState(s); // 🔹 s 전달
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // 하단부터 정렬
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
              error: (e, __) => Center(
                  child: Text(s.chat_error_load, // 🔹 다국어 적용
                      style: const TextStyle(color: Colors.white24))),
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

  Widget _buildEmptyState(AppLocalizations s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 48, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 12),
          Text(
            '${s.chat_empty_title}\n${s.chat_empty_subtitle}', // 🔹 다국어 적용
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}