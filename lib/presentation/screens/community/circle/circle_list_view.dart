// lib/presentation/screens/community/circle/widgets/circle_list_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:daoapp/presentation/screens/community/circle/widgets/post_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/core/utils/badge_utils.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class CircleListView extends ConsumerStatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  final String? currentUserId;
  final String? initialPostId;

  const CircleListView({
    super.key,
    required this.docs,
    this.currentUserId,
    this.initialPostId,
  });

  @override
  ConsumerState<CircleListView> createState() => _CircleListViewState();
}

class _CircleListViewState extends ConsumerState<CircleListView> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  String? _lastScrolledPostId;

  final Map<String, Stream<DocumentSnapshot<Map<String, dynamic>>>> _userDocStreamCache = {};

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream(String userId) {
    return _userDocStreamCache.putIfAbsent(
      userId,
          () => FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
    );
  }

  @override
  void didUpdateWidget(covariant CircleListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPostId != widget.initialPostId || oldWidget.docs.length != widget.docs.length) {
      _tryScrollToInitial(widget.docs);
    }
  }

  void _tryScrollToInitial(List<QueryDocumentSnapshot> visibleDocs) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final postId = widget.initialPostId;
      if (postId == null) return;
      if (_lastScrolledPostId == postId) return;

      final index = visibleDocs.indexWhere((doc) => doc.id == postId);
      if (index == -1) return;

      if (_itemScrollController.isAttached) {
        _lastScrolledPostId = postId;
        _itemScrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          alignment: 0.03,
        );
      }
    });
  }

  void _editPost(BuildContext context, String postId) {
    Navigator.pushNamed(context, RouteConstants.postWrite, arguments: {'postId': postId});
  }

  Future<void> _deletePost(String postId) async {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.circle_list_delete_title), // 🔹 다국어
        content: Text(s.circle_list_delete_body), // 🔹 다국어
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.common_cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.common_delete, style: const TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('community').doc(postId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final visibleDocs = widget.docs;

    if (visibleDocs.isEmpty) {
      return Center(child: Text(s.circle_list_no_visible_posts)); // 🔹 다국어
    }

    _tryScrollToInitial(visibleDocs);

    final totalRanking = ref.watch(totalRankingProvider);

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: visibleDocs.length,
      itemBuilder: (context, index) {
        final doc = visibleDocs[index];
        final data = doc.data() as Map<String, dynamic>;
        final postId = doc.id;
        final userId = (data['userId'] as String?)?.trim();

        final rankIndex = totalRanking.indexWhere((item) => item['userId'] == userId);
        final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(opacity: value, child: child),
          child: Column(
            children: [
              _PostCardWrapper(
                postId: postId,
                doc: doc,
                userId: userId,
                currentUserId: widget.currentUserId,
                onEdit: () => _editPost(context, postId),
                onDelete: () => _deletePost(postId),
                userDocStreamOf: _userDocStream,
                currentRank: currentRank,
              ),
              Container(
                height: 10,
                width: double.infinity,
                color: Colors.grey[50],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PostCardWrapper extends StatelessWidget {
  final String postId;
  final QueryDocumentSnapshot doc;
  final String? userId;
  final String? currentUserId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Stream<DocumentSnapshot<Map<String, dynamic>>> Function(String userId) userDocStreamOf;
  final int? currentRank;

  const _PostCardWrapper({
    required this.postId,
    required this.doc,
    required this.userId,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
    required this.userDocStreamOf,
    this.currentRank,
  });

  @override
  Widget build(BuildContext context) {
    if (userId == null || userId!.isEmpty) {
      return PostCard(
        key: ValueKey(postId),
        doc: doc,
        currentUserId: currentUserId,
        onEdit: onEdit,
        onDelete: onDelete,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDocStreamOf(userId!),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return PostCard(
            key: ValueKey(postId),
            doc: doc,
            currentUserId: currentUserId,
            onEdit: onEdit,
            onDelete: onDelete,
            currentRank: currentRank,
          );
        }

        Map<String, String?>? barrelData;
        String? monthlyBadge;
        String? adminBadge;

        if (snapshot.data!.exists) {
          final userData = snapshot.data!.data() ?? <String, dynamic>{};

          final barrelName = userData['barrelName']?.toString().trim() ?? '';
          final shaft = userData['shaft']?.toString().trim() ?? '';
          final flight = userData['flight']?.toString().trim() ?? '';
          final tip = userData['tip']?.toString().trim() ?? '';
          final barrelImageUrl = userData['barrelImageUrl'] as String?;

          final hasBarrelInfo = barrelName.isNotEmpty || shaft.isNotEmpty || flight.isNotEmpty || tip.isNotEmpty || (barrelImageUrl?.isNotEmpty == true);

          if (hasBarrelInfo) {
            barrelData = {
              'barrelImageUrl': barrelImageUrl,
              'barrelName': barrelName,
              'shaft': shaft,
              'flight': flight,
              'tip': tip,
            };
          }

          final badgesMap = BadgeUtils.extractBadges(userData);
          monthlyBadge = BadgeUtils.getLatestMonthlyBadge(badgesMap);
          adminBadge = BadgeUtils.getLatestAdminBadge(badgesMap);
        }

        return PostCard(
          key: ValueKey(postId),
          doc: doc,
          currentUserId: currentUserId,
          onEdit: onEdit,
          onDelete: onDelete,
          barrelData: barrelData,
          monthlyBadge: monthlyBadge,
          adminBadge: adminBadge,
          currentRank: currentRank,
        );
      },
    );
  }
}