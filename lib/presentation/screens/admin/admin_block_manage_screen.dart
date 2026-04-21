import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class AdminBlockManageScreen extends StatelessWidget {
  const AdminBlockManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // 다크 테마
      appBar: CommonAppBar(title: '블랙리스트 통합 관리', showBackButton: true),
      body: StreamBuilder<QuerySnapshot>(
        // 🔥 모든 유저 하위의 blockedUsers를 한꺼번에 쿼리 (빌런 탐지)
        stream: FirebaseFirestore.instance.collectionGroup('blockedUsers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 1. 데이터 카운팅 (누가 몇 번 차단됐는가)
          final Map<String, int> blockCounts = {};
          for (var doc in snapshot.data!.docs) {
            final blockedId = doc.id;
            blockCounts[blockedId] = (blockCounts[blockedId] ?? 0) + 1;
          }

          // 2. 많이 차단당한 순서대로 정렬
          final sortedList = blockCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          if (sortedList.isEmpty) {
            return const Center(
              child: Text('차단 내역이 없습니다.', style: TextStyle(color: Colors.white54)),
            );
          }

          return ListView.builder(
            itemCount: sortedList.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemBuilder: (context, index) {
              final userId = sortedList[index].key;
              final count = sortedList[index].value;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnap) {
                  final userData = userSnap.data?.data() as Map<String, dynamic>?;
                  final userName = userData?['koreanName'] ?? userData?['name'] ?? userId;
                  final userEmail = userData?['email'] ?? '이메일 정보 없음';
                  final bool isBanned = userData?['isBanned'] ?? false;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    leading: CircleAvatar(
                      backgroundColor: isBanned ? Colors.red : (count >= 3 ? Colors.orange : Colors.grey),
                      child: isBanned
                          ? const Icon(Icons.block, color: Colors.white, size: 18)
                          : Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    // ⬇️ ✅ [수정된 부분: 64번 줄 근처]
                    title: Row(
                      mainAxisSize: MainAxisSize.min, // 필요한 만큼만 차지
                      children: [
                        // 이름을 Expanded로 감싸서 공간을 확보하고 말줄임표 처리
                        Expanded(
                          child: Text(
                            userName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis, // 👈 이름 길면 ... 처리
                            maxLines: 1,
                          ),
                        ),
                        if (isBanned) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                            child: const Text('정지됨', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '$userEmail\n누적 차단: $count회',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                      overflow: TextOverflow.ellipsis, // 👈 이메일도 길면 ... 처리
                      maxLines: 2,
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBanned ? Colors.blue.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        elevation: 0,
                        minimumSize: const Size(60, 32), // 버튼 크기 고정
                      ),
                      onPressed: () => _showUserManageDialog(context, userId, userName),
                      child: Text(
                        isBanned ? '해제' : '조치',
                        style: TextStyle(color: isBanned ? Colors.blueAccent : Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // 통합 관리 팝업 (동일)
  void _showUserManageDialog(BuildContext context, String uid, String name) {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, snap) {
          final isBanned = (snap.data?.data() as Map<String, dynamic>?)?['isBanned'] ?? false;

          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text('$name 유저 관리', style: const TextStyle(color: Colors.white)),
            content: Text(
              isBanned
                  ? '현재 정지된 유저입니다. 정지를 해제하시겠습니까?'
                  : '해당 유저를 영구 정지하시겠습니까? 로그인 및 활동이 즉시 차단됩니다.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                    'isBanned': !isBanned,
                    'bannedAt': !isBanned ? FieldValue.serverTimestamp() : null,
                  });

                  if (!context.mounted) return;
                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isBanned ? '$name 유저의 정지가 해제되었습니다.' : '$name 유저가 영구 정지되었습니다.')),
                  );
                },
                child: Text(
                  isBanned ? '정지 해제' : '영구 정지',
                  style: TextStyle(color: isBanned ? Colors.blueAccent : Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}