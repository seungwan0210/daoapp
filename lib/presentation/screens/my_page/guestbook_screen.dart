// lib/presentation/screens/user/guestbook_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'widgets/guestbook_header.dart';
import 'widgets/guestbook_comment_item.dart';
import 'package:daoapp/core/utils/badge_utils.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class GuestbookScreen extends ConsumerStatefulWidget {
  final String userId;
  const GuestbookScreen({super.key, required this.userId});

  @override
  ConsumerState<GuestbookScreen> createState() => _GuestbookScreenState();
}

class _GuestbookScreenState extends ConsumerState<GuestbookScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendComment(AppLocalizations s) async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isLoading) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('guestbook')
          .add({
        'writerId': currentUser.uid,
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': <String>[],
      });
      _commentController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
      _showSnackBar(s.guestbook_success, Colors.green); // 🔹 다국어 적용
    } catch (e) {
      _showSnackBar(s.guestbook_fail(e.toString()), Colors.red); // 🔹 다국어 적용
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildInputBar(ThemeData theme, AppLocalizations s) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: s.guestbook_hint, // 🔹 다국어 적용
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendComment(s),
            ),
          ),
          const SizedBox(width: 8),
          _isLoading
              ? const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2))
              : FloatingActionButton(
            mini: true,
            backgroundColor: theme.colorScheme.primary,
            onPressed: () => _sendComment(s),
            child: const Icon(Icons.send, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMe = currentUser?.uid == widget.userId;

    final totalRanking = ref.watch(totalRankingProvider);

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('guestbook')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CommonAppBar(
        title: isMe ? s.guestbook_title_me : s.guestbook_title_other, // 🔹 다국어 적용
        showBackButton: true,
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(top: false, child: _buildInputBar(theme, s)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final comments = snapshot.data!.docs;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    GuestbookHeader(userId: widget.userId),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              if (comments.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: Center(child: Text(s.guestbook_empty))) // 🔹 다국어 적용
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, i) {
                      final doc = comments[i];
                      final data = doc.data() as Map<String, dynamic>;
                      final writerId = data['writerId'] as String?;
                      if (writerId == null) return const SizedBox.shrink();

                      final rankIndex = totalRanking.indexWhere((item) => item['userId'] == writerId);
                      final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;

                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(writerId).snapshots(),
                        builder: (context, userSnapshot) {
                          String? monthlyBadge;
                          String? adminBadge;

                          if (userSnapshot.hasData && userSnapshot.data!.exists) {
                            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                            final badgesMap = BadgeUtils.extractBadges(userData);
                            monthlyBadge = BadgeUtils.getLatestMonthlyBadge(badgesMap);
                            adminBadge = BadgeUtils.getLatestAdminBadge(badgesMap);
                          }

                          return Column(
                            children: [
                              GuestbookCommentItem(
                                writerId: writerId,
                                message: data['message'] ?? '',
                                timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                                docId: doc.id,
                                guestbookOwnerId: widget.userId,
                                monthlyBadge: monthlyBadge,
                                adminBadge: adminBadge,
                                currentRank: currentRank,
                              ),
                              const Divider(height: 1, indent: 56),
                            ],
                          );
                        },
                      );
                    },
                    childCount: comments.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
          );
        },
      ),
    );
  }
}