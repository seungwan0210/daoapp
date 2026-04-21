import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ✅ 차단 목록 프로바이더와 필터링된 채팅 프로바이더 임포트
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/providers/chat/chat_provider.dart';
import 'package:daoapp/presentation/screens/community/chat/widgets/chat_overlay_sheet.dart';
import 'package:daoapp/data/models/chat_message_model.dart';

class LiveChatTicker extends ConsumerWidget {
  const LiveChatTicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔥 [핵심 수정] 쌩 데이터(chatStreamProvider) 대신
    // 이미 차단 유저가 걸러진 filteredChatProvider를 지켜봅니다.
    final chatAsync = ref.watch(filteredChatProvider);
    final blockedIds = ref.watch(blockedUserIdsProvider).value ?? {};

    return chatAsync.when(
      data: (messages) {
        // 🔥 차단된 유저는 이미 filteredChatProvider에서 걸러졌으므로
        // 여기서는 메시지 타입이 SYSTEM이 아닌 첫 번째 최신글만 가져오면 됩니다.
        final lastUserMsg = messages.firstWhere(
              (m) => m.type != 'SYSTEM',
          orElse: () => ChatMessage(
            id: 'empty',
            uid: '',
            userName: 'DAO',
            message: '라이브 톡에 참여해보세요!',
            timestamp: DateTime.now(),
          ),
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const ChatOverlaySheet(),
              );
            },
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  // 1️⃣ [상단] 시스템 공지 (Firestore 실시간 연동)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('settings')
                            .doc('chat_config')
                            .snapshots(),
                        builder: (context, snapshot) {
                          String noticeText = 'DAO 라이브 톡에 오신 것을 환영합니다!';

                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            noticeText = data['tickerNotice'] ?? noticeText;
                          }

                          return Row(
                            children: [
                              const Icon(Icons.campaign, color: Colors.amberAccent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 13, color: Colors.white),
                                    children: [
                                      const TextSpan(
                                        text: 'DAO ',
                                        style: TextStyle(
                                          color: Colors.amberAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(text: noticeText),
                                    ],
                                  ),
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_up, color: Colors.white24, size: 18),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // 구분선
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    height: 0.5,
                    color: Colors.white.withOpacity(0.1),
                  ),

                  // 2️⃣ [하단] 유저 최신 대화 (차단 필터링 완료된 데이터)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 14),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: const TextStyle(fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: '${lastUserMsg.userName} ',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ': ',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                  TextSpan(
                                    text: lastUserMsg.message,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}