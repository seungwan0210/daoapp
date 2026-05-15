import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/presentation/widgets/user_profile_dialog.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/utils/badge_utils.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class CommunityAvatarSlider extends ConsumerWidget {
  const CommunityAvatarSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스

    if (currentUid == null) return const SizedBox(height: 90);

    final blockedIds = ref.watch(blockedUserIdsProvider).value ?? {};

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('online_users')
          .orderBy('lastSeen', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 90,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data!.docs;
        QueryDocumentSnapshot? myDoc;
        final otherDocs = <QueryDocumentSnapshot>[];

        for (final d in docs) {
          final data = (d.data() as Map<String, dynamic>?);
          final uid = data?['uid']?.toString().trim();
          if (uid == null || uid.isEmpty) continue;

          if (blockedIds.contains(uid)) continue;

          if (uid == currentUid) {
            myDoc = d;
          } else {
            otherDocs.add(d);
          }
        }

        final sortedDocs = <QueryDocumentSnapshot>[];
        if (myDoc != null) sortedDocs.add(myDoc!);
        sortedDocs.addAll(otherDocs);

        if (sortedDocs.isEmpty) {
          return SizedBox(
            height: 90,
            child: Center(child: Text(s.community_avatar_no_online)), // 🔹 다국어 적용
          );
        }

        return SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedDocs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final doc = sortedDocs[i];
              final data = (doc.data() as Map<String, dynamic>?);
              final uid = data?['uid']?.toString().trim();

              if (uid == null || uid.isEmpty) return const SizedBox(width: 70);

              final isMe = uid == currentUid;

              return _OnlineUserTile(
                uid: uid,
                isMe: isMe,
                onTap: () => _showUserProfileDialog(context, uid, isMe, s),
              );
            },
          ),
        );
      },
    );
  }

  void _showUserProfileDialog(BuildContext context, String userId, bool isMe, AppLocalizations s) {
    showDialog(
      context: context,
      builder: (_) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final koreanName = data['koreanName']?.toString().trim() ?? s.community_avatar_no_name; // 🔹 다국어 적용
          final photoUrl = (data['profileImageUrl'] as String?)?.trim();

          return UserProfileDialog(
            koreanName: koreanName,
            photoUrl: photoUrl,
            isMe: isMe,
            userId: userId,
          );
        },
      ),
    );
  }
}

class _OnlineUserTile extends ConsumerWidget {
  final String uid;
  final bool isMe;
  final VoidCallback onTap;

  const _OnlineUserTile({
    required this.uid,
    required this.isMe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!;
    final totalRanking = ref.watch(totalRankingProvider);
    final rankIndex = totalRanking.indexWhere((item) => item['userId'] == uid);
    final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, snapshot) {
            final userData = (snapshot.hasData && snapshot.data!.exists)
                ? (snapshot.data!.data() ?? {})
                : <String, dynamic>{};

            final name = (userData['koreanName']?.toString().trim() ?? s.community_avatar_no_name); // 🔹 다국어 적용
            final photoUrl = (userData['profileImageUrl'] as String?)?.trim();

            final badgeWidgets = <Widget>[];

            if (currentRank != null) {
              badgeWidgets.add(BadgeWidget(rank: currentRank, size: 20));
            }

            final badgesMap = BadgeUtils.extractBadges(userData);
            final adminBadge = BadgeUtils.getLatestAdminBadge(badgesMap);
            if (adminBadge != null && badgeWidgets.length < 2) {
              badgeWidgets.add(BadgeWidget(badgeKey: adminBadge, size: 20));
            }

            return Column(
              children: [
                _AvatarWithBadges(
                  photoUrl: photoUrl,
                  badgeWidgets: badgeWidgets,
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isMe ? Theme.of(context).colorScheme.primary : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AvatarWithBadges extends StatelessWidget {
  final String? photoUrl;
  final List<Widget> badgeWidgets;

  const _AvatarWithBadges({
    required this.photoUrl,
    required this.badgeWidgets,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
          backgroundColor: Colors.grey[200],
          child: !hasPhoto ? const Icon(Icons.person, size: 32, color: Colors.grey) : null,
        ),

        ...badgeWidgets.asMap().entries.map((entry) {
          final index = entry.key;
          final widget = entry.value;

          return Positioned(
            left: -6 - (index * 16),
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
              ),
              child: widget,
            ),
          );
        }).toList(),
      ],
    );
  }
}