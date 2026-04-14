// lib/presentation/screens/community/circle/widgets/circle_list_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:daoapp/presentation/screens/community/circle/widgets/post_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/core/utils/badge_utils.dart';

class CircleListView extends StatefulWidget {
  /// ✅ 여기로 들어오는 docs는 "이미 CircleScreen에서 차단/필터 적용된 리스트"라고 가정
  final List<QueryDocumentSnapshot> docs;

  /// ✅ PostCard 내부 기능(신고/차단/수정/삭제 등) 때문에 유지
  final String? currentUserId;

  /// ✅ Grid에서 탭한 postId로 스크롤
  final String? initialPostId;

  const CircleListView({
    super.key,
    required this.docs,
    this.currentUserId,
    this.initialPostId,
  });

  @override
  State<CircleListView> createState() => _CircleListViewState();
}

class _CircleListViewState extends State<CircleListView> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
  ItemPositionsListener.create();

  String? _lastScrolledPostId;

  // ✅ 유저 스트림 캐시 (타입 안전)
  final Map<String, Stream<DocumentSnapshot<Map<String, dynamic>>>>
  _userDocStreamCache = {};

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream(String userId) {
    return _userDocStreamCache.putIfAbsent(
      userId,
          () => FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
    );
  }

  @override
  void didUpdateWidget(covariant CircleListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ 초기 진입 postId가 바뀌었거나, docs가 바뀌면(필터/새글/삭제 등) 스크롤 재시도
    if (oldWidget.initialPostId != widget.initialPostId ||
        oldWidget.docs.length != widget.docs.length) {
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

        // ✅ 살짝 위에 여백 두고 맞추면 "한 장 밀린 느낌"이 확 줄어듦(체감)
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
    Navigator.pushNamed(
      context,
      RouteConstants.postWrite,
      arguments: {'postId': postId},
    );
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 게시물을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('community')
          .doc(postId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleDocs = widget.docs;

    if (visibleDocs.isEmpty) {
      return const Center(child: Text('표시할 게시물이 없습니다'));
    }

    // ✅ 빌드마다 한번씩 “현재 initialPostId 기준” 스크롤 시도
    _tryScrollToInitial(visibleDocs);

    return _buildList(context, visibleDocs);
  }

  Widget _buildList(BuildContext context, List<QueryDocumentSnapshot> visibleDocs) {
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

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          builder: (context, value, child) =>
              Opacity(opacity: value, child: child),
          child: _PostCardWrapper(
            postId: postId,
            doc: doc,
            userId: userId,
            currentUserId: widget.currentUserId,
            onEdit: () => _editPost(context, postId),
            onDelete: () => _deletePost(postId),
            userDocStreamOf: _userDocStream,
          ),
        );
      },
    );
  }
}

/// ===============================
/// PostCard + 유저 데이터 래퍼 (에러/권한 문제에도 "포스트는 표시")
/// ===============================
class _PostCardWrapper extends StatelessWidget {
  final String postId;
  final QueryDocumentSnapshot doc;
  final String? userId;
  final String? currentUserId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  final Stream<DocumentSnapshot<Map<String, dynamic>>> Function(String userId)
  userDocStreamOf;

  const _PostCardWrapper({
    required this.postId,
    required this.doc,
    required this.userId,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
    required this.userDocStreamOf,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ userId 없으면 그냥 PostCard만 (Unknown 처리)
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
        // ✅ 핵심: 에러나도 로딩 무한X → PostCard를 보여준다
        if (snapshot.hasError || !snapshot.hasData) {
          return PostCard(
            key: ValueKey(postId),
            doc: doc,
            currentUserId: currentUserId,
            onEdit: onEdit,
            onDelete: onDelete,
          );
        }

        Map<String, String?>? barrelData;
        String? monthlyBadge;
        String? adminBadge;

        if (snapshot.data!.exists) {
          final userData = snapshot.data!.data() ?? <String, dynamic>{};

          // 배럴 정보
          final barrelName = userData['barrelName']?.toString().trim() ?? '';
          final shaft = userData['shaft']?.toString().trim() ?? '';
          final flight = userData['flight']?.toString().trim() ?? '';
          final tip = userData['tip']?.toString().trim() ?? '';
          final barrelImageUrl = userData['barrelImageUrl'] as String?;

          final hasBarrelInfo = barrelName.isNotEmpty ||
              shaft.isNotEmpty ||
              flight.isNotEmpty ||
              tip.isNotEmpty ||
              (barrelImageUrl?.isNotEmpty == true);

          if (hasBarrelInfo) {
            barrelData = {
              'barrelImageUrl': barrelImageUrl,
              'barrelName': barrelName,
              'shaft': shaft,
              'flight': flight,
              'tip': tip,
            };
          }

          // 배지
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
        );
      },
    );
  }
}
