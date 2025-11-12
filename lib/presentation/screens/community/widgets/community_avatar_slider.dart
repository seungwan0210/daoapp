import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/constants/route_constants.dart';

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

        // 나를 제외한 다른 유저들
        final otherDocs = docs.where((doc) {
          final uid = doc.get('uid') as String?;
          return uid != currentUid;
        }).toList();

        // 나의 문서 찾기
        QueryDocumentSnapshot? myDoc;
        try {
          myDoc = docs.firstWhere((doc) => doc.get('uid') == currentUid);
        } catch (_) {
          myDoc = null;
        }

        // 정렬: 나 → 다른 유저들
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
                      // 실시간 프로필 사진
                      _buildRealtimeAvatar(uid),
                      const SizedBox(height: 6),
                      // 실시간 이름
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

  // 실시간 프로필 사진
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

  // 실시간 이름
  Widget _buildRealtimeName(String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        String name = '이름 없음';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final koreanName = data['koreanName']?.toString().trim();
          if (koreanName?.isNotEmpty == true) {
            name = koreanName!;
          }
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

  // 프로필 다이얼로그
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
            return _buildFullDialog(ctx, '이름 없음', null, null, null, null, isMe, userId);
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final hasProfile = data['hasProfile'] == true;
          if (!hasProfile) {
            return _buildFullDialog(ctx, '프로필 없음', null, null, null, null, isMe, userId);
          }

          // 필드별 추출
          final koreanName = data['koreanName']?.toString().trim() ?? '이름 없음';
          final englishName = data['englishName']?.toString().trim();
          final photoUrl = data['profileImageUrl'] as String?;
          final shopName = data['shopName']?.toString().trim();

          // 배럴 정보 필드별 추출
          final barrelName = data['barrelName']?.toString().trim() ?? '';
          final shaft = data['shaft']?.toString().trim() ?? '';
          final flight = data['flight']?.toString().trim() ?? '';
          final tip = data['tip']?.toString().trim() ?? '';
          final barrelImageUrl = data['barrelImageUrl'] as String?;

          // 배럴 정보 존재 여부
          final hasBarrelInfo = barrelName.isNotEmpty ||
              shaft.isNotEmpty ||
              flight.isNotEmpty ||
              tip.isNotEmpty ||
              (barrelImageUrl?.isNotEmpty == true);

          return _buildFullDialog(
            ctx,
            koreanName,
            englishName,
            photoUrl,
            shopName,
            hasBarrelInfo
                ? {
              'barrelImageUrl': barrelImageUrl,
              'barrelName': barrelName,
              'shaft': shaft,
              'flight': flight,
              'tip': tip,
            }
                : null,
            isMe,
            userId,
          );
        },
      ),
    );
  }

  // 다이얼로그: 모든 정보
  Widget _buildFullDialog(
      BuildContext context,
      String koreanName,
      String? englishName,
      String? photoUrl,
      String? shopName,
      Map<String, dynamic>? barrelData,
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
            // 프로필 사진 (클릭 → 확대)
            GestureDetector(
              onTap: photoUrl?.isNotEmpty == true
                  ? () => _showFullImage(context, photoUrl!)
                  : null,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
                child: photoUrl?.isNotEmpty != true ? const Icon(Icons.person, size: 60) : null,
              ),
            ),
            const SizedBox(height: 16),

            // 한국 이름
            Text(koreanName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            // 영어 이름
            if (englishName?.isNotEmpty == true)
              Text(englishName!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),

            // 홈샵
            if (shopName?.isNotEmpty == true)
              Text('· $shopName', style: TextStyle(fontSize: 14, color: theme.colorScheme.primary)),
            const SizedBox(height: 16),

            // 배럴 정보
            if (barrelData != null) ...[
              const Divider(height: 24),
              const Text('PLAYERS_DART', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),

              // 배럴 사진 (클릭 → 확대)
              if (barrelData['barrelImageUrl']?.isNotEmpty == true)
                Center(
                  child: GestureDetector(
                    onTap: () => _showFullImage(context, barrelData['barrelImageUrl']),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        barrelData['barrelImageUrl'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),

              // 배럴 정보
              if (barrelData['barrelName']?.isNotEmpty == true) _infoRow('BARREL', barrelData['barrelName']),
              if (barrelData['shaft']?.isNotEmpty == true) _infoRow('SHAFT', barrelData['shaft']),
              if (barrelData['flight']?.isNotEmpty == true) _infoRow('FLIGHT', barrelData['flight']),
              if (barrelData['tip']?.isNotEmpty == true) _infoRow('TIP', barrelData['tip']),
            ],
            const SizedBox(height: 20),

            // 방명록 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.create, size: 18),
                label: Text(isMe ? "내 방명록 가기" : "방명록 쓰러 가기"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, RouteConstants.guestbook, arguments: userId);
                },
              ),
            ),

            const SizedBox(height: 12),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("닫기")),
          ],
        ),
      ),
    );
  }

  // 사진 확대 팝업 (프로필 + 배럴 공용)
  void _showFullImage(BuildContext context, String photoUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                photoUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
              ),
            ),
          ),
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
          Flexible(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}