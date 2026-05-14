import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/practice_session_model.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class LivePracticeFullListScreen extends ConsumerWidget {
  const LivePracticeFullListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.value != null;

    // ✅ 새벽 4시 기준점 계산
    final now = DateTime.now();
    final threshold = DateTime(now.year, now.month, now.day, 4, 0, 0);
    final finalThreshold = now.isBefore(threshold)
        ? threshold.subtract(const Duration(days: 1))
        : threshold;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CommonAppBar(
        title: s.live_list_title, // 🔹 다국어화
        showBackButton: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('practice_sessions')
            .where('updatedAt', isGreaterThan: Timestamp.fromDate(finalThreshold))
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(s.live_list_empty, // 🔹 다국어화
                  style: const TextStyle(color: Colors.grey)),
            );
          }

          final allSessions = snapshot.data!.docs
              .map((doc) => PracticeSessionModel.fromFirestore(doc))
              .toList();

          // 정렬 로직 (LIVE 우선 -> 시간순)
          allSessions.sort((a, b) {
            final aLive = a.isActive && !a.isPaused ? 1 : 0;
            final bLive = b.isActive && !b.isPaused ? 1 : 0;
            if (aLive != bLive) return bLive.compareTo(aLive);
            return b.getTodayTotalDuration().compareTo(a.getTodayTotalDuration());
          });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: allSessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _FullListTile(
                session: allSessions[index],
                isBlur: !isLoggedIn,
              );
            },
          );
        },
      ),
    );
  }
}

class _FullListTile extends ConsumerWidget {
  final PracticeSessionModel session;
  final bool isBlur;

  const _FullListTile({required this.session, required this.isBlur});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!;
    final bool isLive = session.isActive && !session.isPaused;
    final totalDuration = session.getTodayTotalDuration();

    final totalRanking = ref.watch(totalRankingProvider);
    final rankIndex = totalRanking.indexWhere((item) => item['userId'] == session.uid);
    final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLive ? Colors.white : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: isLive ? Border.all(color: Colors.cyanAccent.withOpacity(0.3)) : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)
          )
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFF1F5F9),
                backgroundImage: session.profileUrl != null
                    ? NetworkImage(session.profileUrl!)
                    : null,
                child: session.profileUrl == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              if (currentRank != null)
                Positioned(
                  left: -5,
                  top: -5,
                  child: BadgeWidget(rank: currentRank, size: 20),
                ),
              if (isLive)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        session.nickname,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isLive ? const Color(0xFF0F172A) : Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLive) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.bolt, size: 14, color: Colors.orangeAccent),
                    ]
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isBlur
                      ? s.live_blur_text // 🔹 다국어화
                      : '${session.machineType} · ${session.shopName ?? s.live_no_shop}', // 🔹 다국어화
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isLive ? s.live_status_live : s.live_status_finished, // 🔹 다국어화
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isLive ? Colors.cyan[700] : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isBlur ? '**:***' : _formatDuration(totalDuration),
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: isLive ? const Color(0xFF0F172A) : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}";
  }
}