import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class BlockListScreen extends StatelessWidget {
  const BlockListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // 앱 공통 다크 배경색
      appBar: CommonAppBar(title: '차단 관리', showBackButton: true),
      body: currentUser == null
          ? const Center(child: Text('로그인이 필요합니다.', style: TextStyle(color: Colors.white)))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('blockedUsers')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text('데이터를 불러오지 못했습니다.',
                    style: TextStyle(color: Colors.white54)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined,
                      size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('차단한 유저가 없습니다.',
                      style: TextStyle(color: Colors.white54, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) =>
            const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              final blockData = docs[index].data() as Map<String, dynamic>;
              final blockedUid = docs[index].id;
              final blockedName = blockData['name'] ?? '알 수 없는 유저';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF1A1A1A),
                  child: Icon(Icons.person, color: Colors.white54),
                ),
                title: Text(
                  blockedName,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('차단됨',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                trailing: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    backgroundColor: Colors.white.withOpacity(0.05),
                  ),
                  onPressed: () => _showUnblockDialog(
                      context, currentUser.uid, blockedUid, blockedName),
                  child: const Text('차단 해제'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ✅ 차단 해제 확인 다이얼로그 (수정 완료)
  void _showUnblockDialog(
      BuildContext context, String myUid, String targetUid, String targetName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('차단 해제', style: TextStyle(color: Colors.white)),
        content: Text('$targetName님의 차단을 해제하시겠습니까?\n이제 상대방의 게시글과 채팅이 보입니다.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              // 1. 다이얼로그 창을 즉시 닫습니다.
              Navigator.pop(ctx);

              try {
                // 2. 내 blockedUsers 컬렉션에서 해당 유저 문서 삭제
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(myUid)
                    .collection('blockedUsers')
                    .doc(targetUid)
                    .delete();

                // 3. 성공 스낵바 표시
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$targetName님의 차단이 해제되었습니다.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('해제 중 오류가 발생했습니다.')),
                  );
                }
              }
            },
            child: const Text('해제하기', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }
}