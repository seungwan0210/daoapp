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
      return const SizedBox(height: 80);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('online_users')
          .orderBy('lastSeen', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
        }

        final docs = snapshot.data!.docs;

        // 나를 제외한 다른 유저들
        final otherDocs = docs.where((doc) {
          final uid = doc.get('uid') as String?;
          return uid != currentUid;
        }).toList();

        // 나의 문서 찾기 (없으면 null)
        QueryDocumentSnapshot? myDoc;
        try {
          myDoc = docs.firstWhere((doc) => doc.get('uid') == currentUid);
        } catch (_) {
          myDoc = null;
        }

        // 정렬된 리스트: 나 → 다른 유저들
        final List<QueryDocumentSnapshot> sortedDocs = [];
        if (myDoc != null) {
          sortedDocs.add(myDoc);
        }
        sortedDocs.addAll(otherDocs);

        if (sortedDocs.isEmpty) {
          return const SizedBox(height: 80, child: Center(child: Text('온라인 유저 없음')));
        }

        return SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedDocs.length,
            itemBuilder: (context, i) {
              final doc = sortedDocs[i];
              final data = doc.data()! as Map<String, dynamic>;
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
                      if (koreanName?.isNotEmpty == true) {
                        displayName = koreanName!;
                      }
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
                            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null || photoUrl.isEmpty
                                ? const Icon(Icons.person, size: 32, color: Colors.grey)
                                : null,
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
    // 기존 다이얼로그 유지 (생략 가능)
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isMe ? '내 프로필' : '유저 프로필'),
        content: Text('UID: $userId'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
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
