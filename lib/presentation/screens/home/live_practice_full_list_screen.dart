import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/practice_session_model.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/l10n/app_localizations.dart';

class LivePracticeFullListScreen extends ConsumerWidget {
  const LivePracticeFullListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);

    final now = DateTime.now();
    final threshold = DateTime(now.year, now.month, now.day, 4, 0, 0);
    final finalThreshold = now.isBefore(threshold)
        ? threshold.subtract(const Duration(days: 1))
        : threshold;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CommonAppBar(
        title: s.live_list_title,
        showBackButton: true,
      ),
      body: authState.when(
        data: (user) {
          return StreamBuilder<DocumentSnapshot?>(
            stream: user != null
                ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
                : Stream.value(null),
            builder: (context, userSnapshot) {
              final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
              final hasProfile = userData?['hasProfile'] == true;
              final isLoggedIn = user != null;

              return StreamBuilder<QuerySnapshot>(
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
                      child: Text(s.live_list_empty, style: const TextStyle(color: Colors.grey)),
                    );
                  }

                  final allSessions = snapshot.data!.docs
                      .map((doc) => PracticeSessionModel.fromFirestore(doc))
                      .toList();

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
                        isBlur: !isLoggedIn || !hasProfile,
                        isLoggedIn: isLoggedIn,
                        hasProfile: hasProfile,
                      );
                    },
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(s.common_error_msg)),
      ),
    );
  }
}

class _FullListTile extends ConsumerWidget {
  final PracticeSessionModel session;
  final bool isBlur;
  final bool isLoggedIn;
  final bool hasProfile;

  const _FullListTile({
    required this.session,
    required this.isBlur,
    required this.isLoggedIn,
    required this.hasProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bool isLive = session.isActive && !session.isPaused;
    final totalDuration = session.getTodayTotalDuration();

    final totalRanking = ref.watch(totalRankingProvider);
    final rankIndex = totalRanking.indexWhere((item) => item['userId'] == session.uid);
    final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;

    return InkWell(
      onTap: () {
        if (!isLoggedIn) {
          _showPromptDialog(context, theme, s.community_home_login_prompt, Icons.people_alt_outlined, RouteConstants.login, s);
        } else if (!hasProfile) {
          _showPromptDialog(context, theme, s.community_home_verify_prompt, Icons.verified_user_outlined, RouteConstants.profileRegister, s);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLive ? Colors.white : Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: isLive ? Border.all(color: Colors.cyanAccent.withOpacity(0.3)) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // 💡 프로필 이미지 에러 핸들링을 위해 CircleAvatar 구조 수정
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: session.profileUrl != null && session.profileUrl!.isNotEmpty
                        ? Image.network(
                      session.profileUrl!,
                      fit: BoxFit.cover,
                      // 💡 404 에러 등이 발생했을 때 처리
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, color: Colors.grey);
                      },
                    )
                        : const Icon(Icons.person, color: Colors.grey),
                  ),
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
                        ? s.live_blur_text
                        : '${session.machineType} · ${session.shopName ?? s.live_no_shop}',
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
                  isLive ? s.live_status_live : s.live_status_finished,
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
      ),
    );
  }

  void _showPromptDialog(BuildContext context, ThemeData theme, String title, IconData icon, String route, AppLocalizations s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, route);
                },
                child: Text(s.live_btn_move),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}";
  }
}