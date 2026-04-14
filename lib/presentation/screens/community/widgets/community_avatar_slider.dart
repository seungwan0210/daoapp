// lib/presentation/screens/community/widgets/community_avatar_slider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/presentation/widgets/user_profile_dialog.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/utils/badge_utils.dart';

class CommunityAvatarSlider extends ConsumerWidget {
  const CommunityAvatarSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return const SizedBox(height: 90);

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

        // ✅ 내 문서를 맨 앞으로, 나머지는 뒤로
        QueryDocumentSnapshot? myDoc;
        final otherDocs = <QueryDocumentSnapshot>[];

        for (final d in docs) {
          final data = (d.data() as Map<String, dynamic>?);
          final uid = data?['uid']?.toString().trim();
          if (uid == null || uid.isEmpty) continue;

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

              if (uid == null || uid.isEmpty) {
                return const SizedBox(width: 70);
              }

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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists || snapshot.data!.data() == null) {
            return UserProfileDialog(
              koreanName: '프로필 없음',
              isMe: isMe,
              userId: userId,
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final hasProfile = data['hasProfile'] == true;
          if (!hasProfile) {
            return UserProfileDialog(
              koreanName: '프로필 미완료',
              isMe: isMe,
              userId: userId,
            );
          }

          final koreanName = data['koreanName']?.toString().trim() ?? '이름 없음';
          final englishName = data['englishName']?.toString().trim();
          final photoUrl = (data['profileImageUrl'] as String?)?.trim();
          final shopName = data['shopName']?.toString().trim();

          final barrelName = data['barrelName']?.toString().trim() ?? '';
          final shaft = data['shaft']?.toString().trim() ?? '';
          final flight = data['flight']?.toString().trim() ?? '';
          final tip = data['tip']?.toString().trim() ?? '';
          final barrelImageUrl = data['barrelImageUrl'] as String?;

          final hasBarrelInfo = barrelName.isNotEmpty ||
              shaft.isNotEmpty ||
              flight.isNotEmpty ||
              tip.isNotEmpty ||
              (barrelImageUrl?.isNotEmpty == true);

          return UserProfileDialog(
            koreanName: koreanName,
            englishName: englishName,
            photoUrl: photoUrl,
            shopName: shopName,
            barrelData: hasBarrelInfo
                ? {
              'barrelImageUrl': barrelImageUrl,
              'barrelName': barrelName,
              'shaft': shaft,
              'flight': flight,
              'tip': tip,
            }
                : null,
            isMe: isMe,
            userId: userId,
          );
        },
      ),
    );
  }
}

/// ✅ 유저 1명당 users/{uid} 스트림 1개만 사용
class _OnlineUserTile extends StatelessWidget {
  final String uid;
  final bool isMe;
  final VoidCallback onTap;

  const _OnlineUserTile({
    required this.uid,
    required this.isMe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, snapshot) {
            final userData =
            (snapshot.hasData && snapshot.data!.exists) ? (snapshot.data!.data() ?? {}) : <String, dynamic>{};

            final name = (userData['koreanName']?.toString().trim().isNotEmpty == true)
                ? userData['koreanName'].toString().trim()
                : '이름 없음';

            final photoUrl = (userData['profileImageUrl'] as String?)?.trim();

            // 배지 추출
            final badgesMap = BadgeUtils.extractBadges(userData);
            final monthlyBadge = BadgeUtils.getLatestMonthlyBadge(badgesMap);
            final adminBadge = BadgeUtils.getLatestAdminBadge(badgesMap);

            final badgesToShow = <String>[];
            if (monthlyBadge != null) badgesToShow.add(monthlyBadge);
            if (adminBadge != null) badgesToShow.add(adminBadge);

            return Column(
              children: [
                _AvatarWithBadges(
                  photoUrl: photoUrl,
                  badgesToShow: badgesToShow,
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
  final List<String> badgesToShow;

  const _AvatarWithBadges({
    required this.photoUrl,
    required this.badgesToShow,
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
          backgroundColor: hasPhoto ? null : Colors.grey[200],
          child: !hasPhoto
              ? const Icon(Icons.person, size: 32, color: Colors.grey)
              : null,
        ),

        // 배지 (최대 2개)
        ...badgesToShow.take(2).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final key = entry.value;

          return Positioned(
            left: -8 - (index * 18),
            top: -8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  )
                ],
              ),
              child: Tooltip(
                message: BadgeUtils.getBadgeTooltip(key),
                child: BadgeWidget(badgeKey: key, size: 20),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
