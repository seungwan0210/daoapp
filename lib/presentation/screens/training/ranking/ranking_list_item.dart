import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/data/models/ranking_game_model.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class RankingListItem extends ConsumerWidget {
  final int rank;
  final RankingRecord record;
  final String displayValue;
  final bool isMe;
  final String category; // 'ppd', 'mpr', 'countup', 'total'

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

    bool showDash = (category == 'total' && rank == -1);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(record.userId).snapshots(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
        final liveName = userData['koreanName']?.toString().trim() ?? record.nickname;
        final livePhoto = userData['profileImageUrl']?.toString().trim() ?? record.profileImageUrl;

        return InkWell(
          onLongPress: (isMe || isAdmin)
              ? () => _showDeleteDialog(context, ref, isAdmin, liveName)
              : null,
          child: Container(
            color: isMe ? Colors.cyan.withOpacity(0.05) : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              children: [
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

  void _showDeleteDialog(BuildContext context, WidgetRef ref, bool isAdmin, String liveName) {
    final s = AppLocalizations.of(context)!;
    final bool isDeletingOthers = isAdmin && !isMe;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDeletingOthers ? s.rank_reset_admin_title : s.rank_reset_my_title),
        content: Text(isDeletingOthers
            ? s.rank_reset_admin_msg(liveName) // 🔹 유저 이름 전달
            : s.rank_reset_my_msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.common_cancel),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(rankingRepositoryProvider).resetMyRecord(
                uid: record.userId,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.rank_reset_done)),
                );
              }
            },
            child: Text(s.common_delete, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}