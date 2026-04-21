import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/presentation/widgets/user_profile_dialog.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/utils/badge_utils.dart';
import 'package:daoapp/presentation/providers/training/ranking/total_ranking_provider.dart';
import 'package:daoapp/presentation/providers/app_providers.dart'; // ✅ 중앙 차단 프로바이더 임포트

class CommunityAvatarSlider extends ConsumerWidget {
  const CommunityAvatarSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return const SizedBox(height: 90);

    // ✅ [핵심] 중앙 집중식 실시간 차단 목록 구독
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

          // 🔥 [필터링] 내가 차단한 유저라면 목록에 추가하지 않고 건너뜁니다.
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
          return const SizedBox(
            height: 90,
            child: Center(child: Text('온라인 유저 없음')),
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
                onTap: () => _showUserProfileDialog(context, uid, isMe),
              );
            },
          ),
        );
      },
    );
  }

  void _showUserProfileDialog(BuildContext context, String userId, bool isMe) {
    showDialog(
      context: context,
      builder: (_) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final koreanName = data['koreanName']?.toString().trim() ?? '이름 없음';
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

            final name = (userData['koreanName']?.toString().trim() ?? '이름 없음');
            final photoUrl = (userData['profileImageUrl'] as String?)?.trim();

            // 배지 위젯 리스트 생성
            final badgeWidgets = <Widget>[];

            // 1. 실시간 순위 배지 (rank 전달)
            if (currentRank != null) {
              badgeWidgets.add(BadgeWidget(rank: currentRank, size: 20));
            }

            // 2. 관리자 배지 (badgeKey 전달)
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

        // 배지 표시
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
              child: widget, // 이미 BadgeWidget이므로 그대로 사용
            ),
          );
        }).toList(),
      ],
    );
  }
}