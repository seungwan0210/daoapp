import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/providers/chat/chat_provider.dart';

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

  void _onSend() async {
    final text = _controller.text.trim();

    // 빈 메시지거나 이미 보내는 중이거나 쿨타임 중이면 무시
    if (text.isEmpty || _isSending || _isCoolingDown) return;

    // 🔥 [UX 개선] 전송 로직 시작과 동시에 입력창부터 비웁니다. (속도감 체감)
    final messageToSend = text;
    _controller.clear();
    setState(() => _isSending = true);

    try {
      // 1. 유저 정보 가져오기 (승완님 기존 필드명 유지)
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();
      final userData = userSnap.data() ?? {};

      // 2. 메시지 전송
      await ref.read(chatProvider.notifier).sendMessage(
        uid: widget.currentUserId,
        userName: userData['koreanName'] ?? '익명',
        userProfile: userData['profileImageUrl'],
        message: messageToSend,
      );

      // 3. 전송 완료 후 쿨타임 상태로 전환 (1초)
      if (mounted) {
        setState(() {
          _isSending = false;
          _isCoolingDown = true;
        });
      }
    } catch (e) {
      // 에러 시 텍스트 복구 (선택 사항)
      _controller.text = messageToSend;
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('전송 실패: $e')),
        );
      }
    } finally {
      // ✅ 1초 후 쿨타임 해제
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _isCoolingDown = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 4, // 상단 여백을 살짝 줄여서 더 타이트하게 배치
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      // 배경색을 조금 더 어둡게 해서 블러 배경 위에서 가독성 확보
      color: Colors.black.withOpacity(0.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // 메시지가 길어질 때 아래쪽 정렬
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 5, // 최대 5줄까지 늘어남
              minLines: 1,
              decoration: InputDecoration(
                hintText: _isCoolingDown ? '잠시 대기 중...' : '메시지를 입력하세요...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => _onSend(),
            ),
          ),
          // 전송 버튼 영역 고정 높이 확보 (버튼 전환 시 튕김 방지)
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
              onPressed: _onSend,
            ),
          ),
        ],
      ),
    );
  }
}