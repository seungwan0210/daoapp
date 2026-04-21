import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:daoapp/presentation/screens/community/chat/chat_screen.dart';

class ChatOverlaySheet extends StatelessWidget {
  const ChatOverlaySheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Stack( // ✅ Stack을 써서 X 버튼을 자유롭게 배치
                children: [
                  Column(
                    children: [
                      // 1. 중앙 헤더 (핸들러 + 타이틀)
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'DAO 라이브 톡',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. 빨간색 안내 문구
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.gpp_maybe_outlined, color: Colors.redAccent, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '상대방의 메시지를 꾹 누르면 차단을 할 수 있습니다.',
                                style: TextStyle(
                                  color: Colors.redAccent.withOpacity(0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Colors.white10, height: 1),

                      // 3. 채팅 영역
                      const Expanded(
                        child: ChatScreen(),
                      ),
                    ],
                  ),

                  // 🎯 X 버튼 위치: 우측 상단에 완전 고정
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}