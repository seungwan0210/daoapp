import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class BlockListScreen extends StatelessWidget {
  const BlockListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: CommonAppBar(title: s.block_title, showBackButton: true), // 🔹 다국어 적용
      body: currentUser == null
          ? Center(child: Text(s.common_login_required, style: const TextStyle(color: Colors.white)))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('blockedUsers')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text(s.block_error_load, // 🔹 다국어 적용
                    style: const TextStyle(color: Colors.white54)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off_outlined,
                      size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(s.block_empty, // 🔹 다국어 적용
                      style: const TextStyle(color: Colors.white54, fontSize: 16)),
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
              final blockedName = blockData['name'] ?? s.common_anonymous;

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
                subtitle: Text(s.block_status, // 🔹 다국어 적용
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                trailing: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    backgroundColor: Colors.white.withOpacity(0.05),
                  ),
                  onPressed: () => _showUnblockDialog(
                      context, currentUser.uid, blockedUid, blockedName, s), // 🔹 s 전달
                  child: Text(s.block_unblock_btn), // 🔹 다국어 적용
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showUnblockDialog(
      BuildContext context, String myUid, String targetUid, String targetName, AppLocalizations s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(s.block_unblock_confirm_title, style: const TextStyle(color: Colors.white)), // 🔹 다국어 적용
        content: Text(s.block_unblock_confirm_body(targetName), // 🔹 다국어 적용 (파라미터 포함)
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.common_cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(myUid)
                    .collection('blockedUsers')
                    .doc(targetUid)
                    .delete();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.block_unblock_success(targetName))), // 🔹 다국어 적용
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.block_unblock_fail)), // 🔹 다국어 적용
                  );
                }
              }
            },
            child: Text(s.block_unblock_btn, style: const TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }
}