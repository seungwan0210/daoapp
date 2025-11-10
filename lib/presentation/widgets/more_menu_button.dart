// lib/presentation/widgets/more_menu_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';

class MoreMenuButton extends ConsumerWidget {
  const MoreMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildMenuButton(isAdmin, context, 0);
    }

    return StreamBuilder<int>(
      stream: _getUnreadNoticeCount(user.uid),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return _buildMenuButton(isAdmin, context, count);
      },
    );
  }

  Widget _buildMenuButton(bool isAdmin, BuildContext context, int count) {
    return Stack(
      children: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.settings),
          tooltip: '설정',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'notice',
              child: Row(
                children: [
                  const Icon(Icons.notifications, size: 20),
                  const SizedBox(width: 12),
                  const Text('공지사항'),
                  if (count > 0) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.bug_report, size: 20),
                  SizedBox(width: 12),
                  Text('버그 신고'),
                ],
              ),
            ),
            if (isAdmin)
              const PopupMenuItem(
                value: 'admin',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 20),
                    SizedBox(width: 12),
                    Text('관리자 모드'),
                  ],
                ),
              ),
          ],
          onSelected: (value) async {
            if (value == 'notice') {
              // 공지 클릭 → 모든 공지 읽음 처리
              await _markAllNoticesAsRead();
              Navigator.pushNamed(context, RouteConstants.noticeList);
            } else if (value == 'report') {
              Navigator.pushNamed(context, RouteConstants.report);
            } else if (value == 'admin') {
              Navigator.pushNamed(context, RouteConstants.adminDashboard);
            }
          },
        ),
        // 설정 아이콘 위 배지 (항상 보임)
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 모든 공지 읽음 처리
  Future<void> _markAllNoticesAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final noticesSnapshot = await FirebaseFirestore.instance
        .collection('notices')
        .where('isActive', isEqualTo: true)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    final readRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('readNotices');

    for (final doc in noticesSnapshot.docs) {
      batch.set(readRef.doc(doc.id), {
        'readAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // 읽지 않은 공지 수
  Stream<int> _getUnreadNoticeCount(String userId) {
    final noticesRef = FirebaseFirestore.instance.collection('notices');
    final readRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('readNotices');

    return noticesRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final noticeIds = snapshot.docs.map((d) => d.id).toList();
      if (noticeIds.isEmpty) return 0;

      final readSnapshot = await readRef.where(FieldPath.documentId, whereIn: noticeIds).get();
      final readIds = readSnapshot.docs.map((d) => d.id).toSet();
      return noticeIds.where((id) => !readIds.contains(id)).length;
    });
  }
}