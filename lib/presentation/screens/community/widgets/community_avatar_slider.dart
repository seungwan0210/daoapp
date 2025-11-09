// lib/presentation/screens/community/widgets/community_avatar_slider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class CommunityAvatarSlider extends StatelessWidget {
  const CommunityAvatarSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return const SizedBox(height: 80, child: Center(child: Text('로그인 필요')));
    }

    final now = Timestamp.now();
    final oneMinuteAgo = Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 1)));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('online_users')
          .where('lastSeen', isGreaterThan: oneMinuteAgo)
          .orderBy('lastSeen', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox(height: 80, child: Center(child: Text('오류', style: TextStyle(color: Colors.red))));
        }

        if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const SizedBox(height: 80, child: Center(child: Text('온라인 유저 없음')));
        }

        // 나를 맨 앞으로 정렬
        docs.sort((a, b) {
          final aUid = a['uid'] as String?;
          final bUid = b['uid'] as String?;
          if (aUid == currentUid) return -1;
          if (bUid == currentUid) return 1;
          return 0;
        });

        return SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final uid = data['uid'] as String?;
              if (uid == null) return const SizedBox(width: 70);

              final isMe = uid == currentUid;

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                builder: (context, profileSnapshot) {
                  String displayName = data['name'] as String? ?? '이름 없음';
                  String? photoUrl;

                  if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
                    final profileData = profileSnapshot.data!.data() as Map<String, dynamic>;
                    if (profileData['hasProfile'] == true) {
                      final koreanName = profileData['koreanName']?.toString().trim();
                      displayName = koreanName?.isNotEmpty == true ? koreanName! : displayName;
                      photoUrl = profileData['profileImageUrl'] as String?;
                    }
                  }

                  return GestureDetector(
                    onTap: () => _showUserProfileDialog(context, uid, isMe),
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null ? const Icon(Icons.person, size: 32, color: Colors.grey) : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isMe ? '나' : displayName,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
      builder: (ctx) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            final googleName = FirebaseAuth.instance.currentUser?.displayName ?? '이름 없음';
            final googlePhoto = FirebaseAuth.instance.currentUser?.photoURL;
            return _buildDialog(ctx, googleName, googlePhoto, null, isMe, userId);
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final hasProfile = data['hasProfile'] == true;

          if (!hasProfile) {
            final googleName = FirebaseAuth.instance.currentUser?.displayName ?? '이름 없음';
            final googlePhoto = FirebaseAuth.instance.currentUser?.photoURL;
            return _buildDialog(ctx, googleName, googlePhoto, null, isMe, userId);
          }

          final name = data['koreanName'] ?? '이름 없음';
          final photoUrl = data['profileImageUrl'] as String?;
          final shopName = data['shopName']?.toString().trim() ?? '';

          final barrelName = data['barrelName']?.toString().trim() ?? '';
          final shaft = data['shaft']?.toString().trim() ?? '';
          final flight = data['flight']?.toString().trim() ?? '';
          final tip = data['tip']?.toString().trim() ?? '';
          final barrelImageUrl = data['barrelImageUrl'] as String?;

          final hasBarrelSetting = barrelName.isNotEmpty ||
              shaft.isNotEmpty ||
              flight.isNotEmpty ||
              tip.isNotEmpty ||
              (barrelImageUrl?.isNotEmpty == true);

          return _buildDialog(
            ctx,
            name,
            photoUrl,
            {
              'shopName': shopName,
              'barrelName': barrelName,
              'shaft': shaft,
              'flight': flight,
              'tip': tip,
              'barrelImageUrl': barrelImageUrl,
              'hasBarrelSetting': hasBarrelSetting,
            },
            isMe,
            userId,
          );
        },
      ),
    );
  }

  Widget _buildDialog(
      BuildContext context,
      String name,
      String? photoUrl,
      Map<String, dynamic>? profileData,
      bool isMe,
      String userId,
      ) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl == null || photoUrl.isEmpty
                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (profileData?['shopName']?.isNotEmpty == true)
              Text(
                '· ${profileData!['shopName']}',
                style: TextStyle(fontSize: 14, color: theme.colorScheme.primary),
              ),
            const SizedBox(height: 16),
            if (profileData?['hasBarrelSetting'] == true) ...[
              const Divider(height: 24),
              const Text('PLAYERS_DART', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              if (profileData!['barrelImageUrl'] != null && profileData['barrelImageUrl'].isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      profileData['barrelImageUrl'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              if (profileData['barrelName'].isNotEmpty) _infoRow('BARREL', profileData['barrelName']),
              if (profileData['shaft'].isNotEmpty) _infoRow('SHAFT', profileData['shaft']),
              if (profileData['flight'].isNotEmpty) _infoRow('FLIGHT', profileData['flight']),
              if (profileData['tip'].isNotEmpty) _infoRow('TIP', profileData['tip']),
            ],
            const SizedBox(height: 20),

            // 나일 때
            if (isMe) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("프로필 수정"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteConstants.profileRegister);
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.book, size: 18),
                  label: const Text("내 방명록 가기"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: theme.colorScheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      RouteConstants.guestbook,
                      arguments: userId,
                    );
                  },
                ),
              ),
            ]
            // 상대방일 때
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.create, size: 18),
                  label: const Text("방명록 쓰러 가기"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    foregroundColor: theme.colorScheme.onSecondaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      RouteConstants.guestbook,
                      arguments: userId,
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("닫기", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Flexible(
            child: Text(value, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}