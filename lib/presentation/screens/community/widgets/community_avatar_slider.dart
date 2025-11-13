// lib/presentation/screens/community/widgets/community_avatar_slider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/user_profile_dialog.dart'; // 정확한 경로!

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
          return const SizedBox(height: 90, child: Center(child: CircularProgressIndicator()));
        }

        final docs = snapshot.data!.docs;
        final otherDocs = docs.where((doc) {
          final uid = doc.get('uid') as String?;
          return uid != currentUid;
        }).toList();

        QueryDocumentSnapshot? myDoc;
        try {
          myDoc = docs.firstWhere((doc) => doc.get('uid') == currentUid);
        } catch (_) {}

        final List<QueryDocumentSnapshot> sortedDocs = [];
        if (myDoc != null) sortedDocs.add(myDoc);
        sortedDocs.addAll(otherDocs);

        if (sortedDocs.isEmpty) {
          return const SizedBox(height: 90, child: Center(child: Text('온라인 유저 없음')));
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
              final data = doc.data()! as Map<String, dynamic>;
              final uid = data['uid'] as String?;
              if (uid == null) return const SizedBox(width: 70);

              final isMe = uid == currentUid;

              return GestureDetector(
                onTap: () => _showUserProfileDialog(context, uid, isMe),
                child: Container(
                  width: 70,
                  child: Column(
                    children: [
                      _buildRealtimeAvatar(uid),
                      const SizedBox(height: 6),
                      _buildRealtimeName(uid),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRealtimeAvatar(String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          photoUrl = data['profileImageUrl'] as String?;
        }

        return CircleAvatar(
          radius: 28,
          backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
          child: photoUrl?.isNotEmpty != true
              ? const Icon(Icons.person, size: 32, color: Colors.grey)
              : null,
        );
      },
    );
  }

  Widget _buildRealtimeName(String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        String name = '이름 없음';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final koreanName = data['koreanName']?.toString().trim();
          if (koreanName?.isNotEmpty == true) name = koreanName!;
        }
        return Text(
          name,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
          if (!snapshot.data!.exists || snapshot.data!.data() == null) {
            return UserProfileDialog(koreanName: '프로필 없음', isMe: isMe, userId: userId);
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final hasProfile = data['hasProfile'] == true;
          if (!hasProfile) {
            return UserProfileDialog(koreanName: '프로필 미완료', isMe: isMe, userId: userId);
          }

          final koreanName = data['koreanName']?.toString().trim() ?? '이름 없음';
          final englishName = data['englishName']?.toString().trim();
          final photoUrl = data['profileImageUrl'] as String?;
          final shopName = data['shopName']?.toString().trim();

          final barrelName = data['barrelName']?.toString().trim() ?? '';
          final shaft = data['shaft']?.toString().trim() ?? '';
          final flight = data['flight']?.toString().trim() ?? '';
          final tip = data['tip']?.toString().trim() ?? '';
          final barrelImageUrl = data['barrelImageUrl'] as String?;

          final hasBarrelInfo = barrelName.isNotEmpty || shaft.isNotEmpty || flight.isNotEmpty || tip.isNotEmpty || (barrelImageUrl?.isNotEmpty == true);

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