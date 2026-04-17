import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/data/models/ranking_game_model.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/utils/badge_utils.dart';

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
    const String adminUid = "NanHPgCdsbMCFkHEs7MtxS51OSX2";
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final bool isAdmin = currentUid == adminUid;

    // 🔥 [수정된 핵심 로직]
    // 1. 통합(total) 카테고리이면서 10위 밖(rank -1)인 경우에만 '-' 표시
    // 2. 그 외 일반 종목은 전달받은 rank(순위 숫자)를 그대로 표시
    bool showDash = (category == 'total' && rank == -1);

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
                    ? BadgeWidget(rank: rank, size: 26) // 1~10위 공통 배지
                    : Text(
                  showDash ? "-" : "$rank", // 통합 10위 밖만 '-', 나머지는 숫자
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
              backgroundImage: record.profileImageUrl != null
                  ? NetworkImage(record.profileImageUrl!)
                  : null,
              child: record.profileImageUrl == null
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            const SizedBox(width: 14),

            // 3. 닉네임
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      record.nickname,
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
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, bool isAdmin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdmin && !isMe ? "관리자 권한: 기록 삭제" : "기록 초기화"),
        content: Text(isAdmin && !isMe
            ? "'${record.nickname}' 유저의 부정 기록이 의심되나요?\n이 유저의 모든 랭킹 기록을 삭제하시겠습니까?"
            : "정말로 현재 탭의 내 최고 기록을 삭제하시겠습니까?\n삭제 후 순위에서 즉시 제외됩니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(rankingRepositoryProvider).resetMyRecord(
                uid: record.userId,
                ppd: category == 'ppd',
                mpr: category == 'mpr',
                countUp: category == 'countup',
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}