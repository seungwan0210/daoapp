import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/providers/chat/chat_provider.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class ChatInputField extends ConsumerStatefulWidget {
  final String currentUserId;
  const ChatInputField({super.key, required this.currentUserId});

  @override
  ConsumerState<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends ConsumerState<ChatInputField> {
  final _controller = TextEditingController();
  bool _isCoolingDown = false;
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSend(AppLocalizations s) async { // 🔹 s 전달
    final text = _controller.text.trim();

    if (text.isEmpty || _isSending || _isCoolingDown) return;

    final messageToSend = text;
    _controller.clear();
    setState(() => _isSending = true);

    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();
      final userData = userSnap.data() ?? {};

      await ref.read(chatProvider.notifier).sendMessage(
        uid: widget.currentUserId,
        userName: userData['koreanName'] ?? s.common_anonymous, // 🔹 공통 키 활용
        userProfile: userData['profileImageUrl'],
        message: messageToSend,
      );

      if (mounted) {
        setState(() {
          _isSending = false;
          _isCoolingDown = true;
        });
      }
    } catch (e) {
      _controller.text = messageToSend;
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.chat_input_send_fail(e.toString()))), // 🔹 다국어 적용
        );
      }
    } finally {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _isCoolingDown = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 4,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      color: Colors.black.withOpacity(0.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 5,
              minLines: 1,
              decoration: InputDecoration(
                hintText: _isCoolingDown ? s.chat_input_cooldown : s.chat_input_hint, // 🔹 다국어 적용
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => _onSend(s), // 🔹 s 전달
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: (_isSending || _isCoolingDown)
                ? const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.tealAccent,
                ),
              ),
            )
                : IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.tealAccent),
              onPressed: () => _onSend(s), // 🔹 s 전달
            ),
          ),
        ],
      ),
    );
  }
}