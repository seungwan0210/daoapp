import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/data/models/ranking_game_model.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RankingListItem extends ConsumerWidget {
  final int rank;
  final RankingRecord record;
  final String displayValue;
  final bool isMe;
  final String category; // 'ppd', 'mpr', 'countup', 'total' (통합)

  const RankingListItem({
    super.key,
    required this.rank,
    required this.record,
    required this.displayValue,
    required this.isMe,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 관리자 UID 설정
    const String adminUid = "NanHPgCdsbMCFkHEs7MtxS51OSX2";
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final bool isAdmin = currentUid == adminUid;

    bool showDash = (category == 'total' && rank == -1);

    // 🆕 실시간 유저 정보 반영을 위한 StreamBuilder
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(record.userId).snapshots(),
      builder: (context, userSnap) {
        // 실시간 데이터 추출
        final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
        final liveName = userData['koreanName']?.toString().trim() ?? record.nickname;
        final livePhoto = userData['profileImageUrl']?.toString().trim() ?? record.profileImageUrl;

        return InkWell(
          onLongPress: (isMe || isAdmin)
              ? () => _showDeleteDialog(context, ref, isAdmin)
              : null,
          child: Container(
            color: isMe ? Colors.cyan.withOpacity(0.05) : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              children: [
                // 1. 순위/배지 영역
                SizedBox(
                  width: 32,
                  child: Center(
                    child: (rank >= 1 && rank <= 10)
                        ? BadgeWidget(rank: rank, size: 26)
                        : Text(
                      showDash ? "-" : "$rank",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.cyan[800] : Colors.grey[600],
                        fontSize: showDash ? 18 : 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. 프로필 이미지
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: livePhoto != null && livePhoto.isNotEmpty
                      ? NetworkImage(livePhoto)
                      : null,
                  child: (livePhoto == null || livePhoto.isEmpty)
                      ? const Icon(Icons.person, size: 20)
                      : null,
                ),
                const SizedBox(width: 14),

                // 3. 닉네임 (실시간 이름 반영)
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          liveName,
                          style: TextStyle(
                            fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                            color: isMe ? Colors.cyan[900] : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAdmin && record.userId != currentUid)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.shield, size: 12, color: Colors.orange),
                        ),
                    ],
                  ),
                ),

                // 4. 기록 값
                Text(
                  displayValue,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.cyan,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🗑️ 삭제 확인 다이얼로그 (수정 완료)
  void _showDeleteDialog(BuildContext context, WidgetRef ref, bool isAdmin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdmin && !isMe ? "관리자 권한: 기록 삭제" : "기록 초기화"),
        content: Text(isAdmin && !isMe
            ? "'${record.nickname}' 유저의 부정 기록이 의심되나요?\n이 유저의 이번 달 모든 랭킹 기록을 삭제하시겠습니까?"
            : "정말로 이번 달 내 모든 최고 기록을 초기화하시겠습니까?\n삭제 후 순위에서 즉시 제외됩니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () async {
              // ✅ 수정 포인트: RankingRepository의 최신 규격에 맞춰 uid만 전달합니다.
              await ref.read(rankingRepositoryProvider).resetMyRecord(
                uid: record.userId,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("기록이 정상적으로 삭제되었습니다.")),
                );
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}