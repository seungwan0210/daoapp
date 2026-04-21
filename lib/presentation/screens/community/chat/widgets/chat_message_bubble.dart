import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/data/models/chat_message_model.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/presentation/providers/training/ranking/total_ranking_provider.dart';
import 'package:daoapp/presentation/widgets/user_profile_dialog.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/core/constants/badge_constants.dart'; // ✅ 배지 경로 참조용 추가
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ 대회 상세 페이지 임포트
import 'package:daoapp/presentation/screens/arena/tournament/tournament_detail_screen.dart';

class ChatMessageBubble extends ConsumerWidget {
  final ChatMessage message;
  final bool isMe;

  const ChatMessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 1. 시스템 메시지 처리 (공지사항 등)
    if (message.type == 'SYSTEM') {
      return _buildSystemMessage(context);
    }

    // 실시간 순위 데이터 구독 (유저 프로필 옆 배지 표시용)
    final totalRanking = ref.watch(totalRankingProvider);
    final rankIndex = totalRanking.indexWhere((item) => item['userId'] == message.uid);
    final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildAvatar(context, currentRank),
            const SizedBox(width: 10),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.userName,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isMe) _buildTime(message.timestamp),

                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPress: () {
                        if (!isMe) _showChatActionMenu(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.6
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.teal.withOpacity(0.9)
                              : Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 2),
                            bottomRight: Radius.circular(isMe ? 2 : 16),
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          message.message,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.4,
                              letterSpacing: -0.2
                          ),
                        ),
                      ),
                    ),

                    if (!isMe) _buildTime(message.timestamp),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTime(DateTime ts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        "${ts.hour}:${ts.minute.toString().padLeft(2, '0')}",
        style: const TextStyle(color: Colors.white24, fontSize: 9),
      ),
    );
  }

  // ✅ 시스템 메시지 빌더 (최종 수정본)
  Widget _buildSystemMessage(BuildContext context) {
    IconData iconData = Icons.notifications_none;
    Color themeColor = Colors.amberAccent;
    String? badgePath; // ✅ 배지 에셋 경로 변수

    // 카테고리에 따른 아이콘 및 테마 설정
    switch (message.category) {
      case 'TOURNAMENT':
        iconData = Icons.emoji_events_outlined;
        themeColor = Colors.lightBlueAccent;
        break;
      case 'RANKING':
        iconData = Icons.trending_up_rounded;
        themeColor = Colors.orangeAccent;
        // 🔥 [핵심] targetId에 담긴 배지 키를 이용해 에셋 경로를 찾습니다.
        if (message.targetId.isNotEmpty) {
          badgePath = BadgeConstants.getImagePath(message.targetId);
        }
        break;
      case 'WELCOME':
        iconData = Icons.celebration_outlined;
        themeColor = Colors.pinkAccent;
        break;
    }

    return GestureDetector(
      onTap: () {
        // ✅ 🚀 TOURNAMENT 공지 클릭 시 상세 페이지로 이동
        if (message.category == 'TOURNAMENT' && message.targetId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TournamentDetailScreen(
                tournamentId: message.targetId,
              ),
            ),
          );
        }
      },
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeColor.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🔥 [추가] 배지 에셋이 있으면 이미지를, 없으면 기본 아이콘을 보여줌
              if (badgePath != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Image.asset(badgePath, width: 22, height: 22),
                )
              else
                Icon(iconData, color: themeColor, size: 14),

              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: themeColor.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, int? rank) {
    return GestureDetector(
      onTap: () => _showProfile(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: Colors.white10,
            backgroundImage: message.userProfile != null && message.userProfile!.isNotEmpty
                ? NetworkImage(message.userProfile!)
                : null,
            child: message.userProfile == null || message.userProfile!.isEmpty
                ? const Icon(Icons.person, size: 20, color: Colors.white38)
                : null,
          ),
          if (rank != null)
            Positioned(
              left: -4,
              top: -4,
              child: BadgeWidget(rank: rank, size: 18),
            ),
        ],
      ),
    );
  }

  void _showProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => UserProfileDialog(
        koreanName: message.userName,
        photoUrl: message.userProfile,
        isMe: isMe,
        userId: message.uid,
      ),
    );
  }

  // ... (신고/차단 관련 _showChatActionMenu 및 _confirmBlock 코드는 이전과 동일)
  void _showChatActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                "\"${message.message}\"",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred_rounded, color: Colors.orangeAccent),
              title: const Text('신고하기', style: TextStyle(color: Colors.white)),
              subtitle: const Text('부적절한 메시지로 신고합니다.', style: TextStyle(color: Colors.white38, fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, RouteConstants.report, arguments: {
                  'targetId': message.uid,
                  'targetName': message.userName,
                  'content': message.message,
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: Colors.redAccent),
              title: Text('${message.userName} 님 차단하기', style: const TextStyle(color: Colors.white)),
              subtitle: const Text('이 사용자의 메시지를 더 이상 보지 않습니다.', style: TextStyle(color: Colors.white38, fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmBlock(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmBlock(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('사용자 차단', style: TextStyle(color: Colors.white)),
        content: Text('${message.userName} 님을 차단하시겠습니까?\n차단 후에는 이 사용자의 대화가 보이지 않습니다.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final myUid = FirebaseAuth.instance.currentUser?.uid;
              if (myUid == null) return;

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(myUid)
                    .collection('blockedUsers')
                    .doc(message.uid)
                    .set({
                  'uid': message.uid,
                  'name': message.userName,
                  'blockedAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${message.userName} 님이 차단되었습니다.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('차단 중 오류가 발생했습니다.')),
                  );
                }
              }
            },
            child: const Text('차단', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}