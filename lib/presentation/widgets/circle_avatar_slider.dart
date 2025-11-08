// lib/presentation/widgets/circle_avatar_slider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:collection/collection.dart';

class ProfileAvatarSlider extends StatelessWidget {
  const ProfileAvatarSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('hasProfile', isEqualTo: true)
          .where('isPhoneVerified', isEqualTo: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        // 에러 처리
        if (snapshot.hasError) {
          return const SizedBox(
            height: 80,
            child: Center(child: Text('로딩 실패', style: TextStyle(color: Colors.red, fontSize: 12))),
          );
        }

        // 로딩 중
        if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const SizedBox(height: 80, child: Center(child: Text('인증된 유저 없음', style: TextStyle(fontSize: 12))));
        }

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final meDoc = docs.firstWhereOrNull((doc) => doc.id == currentUserId);
        final otherDocs = docs.where((doc) => doc.id != currentUserId).toList();
        final orderedDocs = meDoc != null ? [meDoc, ...otherDocs] : otherDocs;

        return SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: orderedDocs.length,
            itemBuilder: (context, i) {
              final doc = orderedDocs[i];
              final data = doc.data() as Map<String, dynamic>;
              final userId = doc.id;
              final name = data['koreanName'] ?? '이름 없음';
              final photoUrl = data['profileImageUrl'] as String?;
              final isMe = userId == currentUserId;

              return GestureDetector(
                onTap: () => _showUserProfileDialog(context, data, userId, isMe),
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null || photoUrl.isEmpty ? const Icon(Icons.person, size: 32) : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMe ? '나' : name,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  // 프로필 팝업 다이얼로그
  void _showUserProfileDialog(BuildContext context, Map<String, dynamic> data, String userId, bool isMe) {
    final name = data['koreanName'] ?? '이름 없음';
    final shopName = data['shopName']?.toString().trim() ?? '';
    final photoUrl = data['profileImageUrl'] as String?;

    // 배럴 세팅 존재 여부
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

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 프로필 사진
              CircleAvatar(
                radius: 50,
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl == null || photoUrl.isEmpty ? const Icon(Icons.person, size: 60) : null,
              ),
              const SizedBox(height: 16),

              // 이름
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // 샵 이름
              if (shopName.isNotEmpty)
                Text('· $shopName', style: TextStyle(fontSize: 14, color: Theme.of(ctx).colorScheme.primary)),

              const SizedBox(height: 16),

              // 배럴 세팅 (있을 때만)
              if (hasBarrelSetting) ...[
                const Divider(height: 24),
                const Text('PLAYERS_DART', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                if (barrelImageUrl != null && barrelImageUrl.isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(barrelImageUrl, width: 60, height: 60, fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 8),
                if (barrelName.isNotEmpty) _infoRow('BARREL', barrelName),
                if (shaft.isNotEmpty) _infoRow('SHAFT', shaft),
                if (flight.isNotEmpty) _infoRow('FLIGHT', flight),
                if (tip.isNotEmpty) _infoRow('TIP', tip),
              ],

              const SizedBox(height: 20),

              // 나일 때만 수정 버튼
              if (isMe)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(ctx, RouteConstants.profileRegister);
                    },
                    child: const Text("프로필 수정"),
                  ),
                ),

              // 닫기 버튼
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("닫기"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 정보 행 위젯
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}