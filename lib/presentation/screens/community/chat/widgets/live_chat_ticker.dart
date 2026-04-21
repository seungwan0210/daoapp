import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/providers/chat/chat_provider.dart';
import 'package:daoapp/presentation/screens/community/chat/widgets/chat_overlay_sheet.dart';
import 'package:daoapp/data/models/chat_message_model.dart';

class LiveChatTicker extends ConsumerWidget {
  const LiveChatTicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 차단된 유저를 제외한 실시간 채팅 스트림 구독
    final chatAsync = ref.watch(filteredChatProvider);

    return chatAsync.when(
      data: (messages) {
        if (messages.isEmpty) return const SizedBox.shrink();

        // 1️⃣ 가장 최신 메시지 가져오기 (유저 채팅 + 시스템 공지 통합)
        final lastMsg = messages.first;
        final bool isSystem = lastMsg.type == 'SYSTEM';

        // 🎨 메시지 카테고리별 맞춤 스타일 설정
        IconData leadingIcon = Icons.chat_bubble_outline;
        Color displayColor = Colors.white;
        String prefixText = lastMsg.userName;

        if (isSystem) {
          switch (lastMsg.category) {
            case 'RANKING':
              leadingIcon = Icons.trending_up_rounded; // 랭킹 상승 아이콘
              displayColor = Colors.orangeAccent;      // 주황색 (활기/경쟁)
              prefixText = '[랭킹]';
              break;
            case 'TOURNAMENT':
              leadingIcon = Icons.emoji_events_outlined; // 트로피 아이콘
              displayColor = Colors.lightBlueAccent;    // 파란색 (신뢰/대회)
              prefixText = '[대회]';
              break;
            case 'WELCOME':
              leadingIcon = Icons.celebration_outlined;  // 파티 아이콘
              displayColor = Colors.pinkAccent;          // 분홍색 (환영)
              prefixText = '[환영]';
              break;
            default:
              leadingIcon = Icons.campaign;              // 확성기 아이콘
              displayColor = Colors.amberAccent;         // 노란색 (일반공지)
              prefixText = '[공지]';
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () {
              // 티커 클릭 시 채팅 오버레이 창 띄우기
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
                  // 2️⃣ 상단: 고정 시스템 공지 (Firestore settings/chat_config 연동)
                  _buildFixedNotice(),

                  // 구분선
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    height: 0.5,
                    color: Colors.white.withOpacity(0.1),
                  ),

                  // 3️⃣ 하단: 실시간 메시지 (카테고리별 맞춤 스타일 적용)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Icon(leadingIcon, color: displayColor, size: 14),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: const TextStyle(fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: '$prefixText ',
                                    style: TextStyle(
                                      color: displayColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (!isSystem)
                                    const TextSpan(text: ': ', style: TextStyle(color: Colors.white54)),
                                  TextSpan(
                                    text: lastMsg.message,
                                    style: TextStyle(
                                      color: isSystem ? displayColor.withOpacity(0.9) : Colors.white,
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

  /// 📢 상단 고정 공지 빌더
  Widget _buildFixedNotice() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('settings').doc('chat_config').snapshots(),
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
    );
  }
}