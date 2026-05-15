import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/providers/chat/chat_provider.dart';
import 'package:daoapp/presentation/screens/community/chat/widgets/chat_overlay_sheet.dart';
import 'package:daoapp/data/models/chat_message_model.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class LiveChatTicker extends ConsumerWidget {
  const LiveChatTicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스

    // 차단된 유저를 제외한 실시간 채팅 스트림 구독
    final chatAsync = ref.watch(filteredChatProvider);

    return chatAsync.when(
      data: (messages) {
        if (messages.isEmpty) return const SizedBox.shrink();

        // 1️⃣ 가장 최신 메시지 가져오기
        final lastMsg = messages.first;
        final bool isSystem = lastMsg.type == 'SYSTEM';

        // 🎨 메시지 카테고리별 맞춤 스타일 설정
        IconData leadingIcon = Icons.chat_bubble_outline;
        Color displayColor = Colors.white;
        String prefixText = lastMsg.userName;

        if (isSystem) {
          switch (lastMsg.category) {
            case 'RANKING':
              leadingIcon = Icons.trending_up_rounded;
              displayColor = Colors.orangeAccent;
              prefixText = s.chat_ticker_prefix_ranking; // 🔹 다국어 적용
              break;
            case 'TOURNAMENT':
              leadingIcon = Icons.emoji_events_outlined;
              displayColor = Colors.lightBlueAccent;
              prefixText = s.chat_ticker_prefix_tournament; // 🔹 다국어 적용
              break;
            case 'WELCOME':
              leadingIcon = Icons.celebration_outlined;
              displayColor = Colors.pinkAccent;
              prefixText = s.chat_ticker_prefix_welcome; // 🔹 다국어 적용
              break;
            default:
              leadingIcon = Icons.campaign;
              displayColor = Colors.amberAccent;
              prefixText = s.chat_ticker_prefix_notice; // 🔹 다국어 적용
          }
        }

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
                  // 2️⃣ 상단: 고정 시스템 공지
                  _buildFixedNotice(s), // 🔹 s 전달

                  // 구분선
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    height: 0.5,
                    color: Colors.white.withOpacity(0.1),
                  ),

                  // 3️⃣ 하단: 실시간 메시지
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
  Widget _buildFixedNotice(AppLocalizations s) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('settings').doc('chat_config').snapshots(),
          builder: (context, snapshot) {
            String noticeText = s.chat_ticker_default_notice; // 🔹 다국어 기본값

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