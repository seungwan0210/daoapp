// lib/presentation/screens/community/circle/widgets/circle_list_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🆕 추가
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:daoapp/presentation/screens/community/circle/widgets/post_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/core/utils/badge_utils.dart';
// 🆕 실시간 통합 랭킹 구독을 위해 추가
import 'package:daoapp/presentation/providers/training/ranking/total_ranking_provider.dart';

class CircleListView extends ConsumerStatefulWidget { // 👈 ConsumerStatefulWidget으로 변경
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
          alignment: 0.08,
        );
      }
    });
  }

  void _editPost(BuildContext context, String postId) {
    Navigator.pushNamed(context, RouteConstants.postWrite, arguments: {'postId': postId});
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 게시물을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('community').doc(postId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleDocs = widget.docs;

    if (visibleDocs.isEmpty) {
      return const Center(child: Text('표시할 게시물이 없습니다'));
    }

    _tryScrollToInitial(visibleDocs);

    // 🆕 실시간 통합 랭킹 데이터 구독
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

        // 🔥 [핵심] 해당 포스트 작성자의 실시간 순위 확인
        final rankIndex = totalRanking.indexWhere((item) => item['userId'] == userId);
        final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(opacity: value, child: child),
          child: _PostCardWrapper(
            postId: postId,
            doc: doc,
            userId: userId,
            currentUserId: widget.currentUserId,
            onEdit: () => _editPost(context, postId),
            onDelete: () => _deletePost(postId),
            userDocStreamOf: _userDocStream,
            currentRank: currentRank, // 🆕 순위 정보 전달
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
  final int? currentRank; // 🆕 추가

  const _PostCardWrapper({
    required this.postId,
    required this.doc,
    required this.userId,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
    required this.userDocStreamOf,
    this.currentRank, // 🆕 생성자 추가
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
            currentRank: currentRank, // 🆕 로딩 중에도 순위는 보낼 수 있음
          );
        }

        Map<String, String?>? barrelData;
        String? monthlyBadge;
        String? adminBadge;

        if (snapshot.data!.exists) {
          final userData = snapshot.data!.data() ?? <String, dynamic>{};

          // 배럴 정보 파싱
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
          currentRank: currentRank, // 🆕 완성된 순위 전달
        );
      },
    );
  }
}