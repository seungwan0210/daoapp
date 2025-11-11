// lib/presentation/screens/community/circle/circle_list_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/post_card.dart';

class CircleListView extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  final String? currentUserId;
  final ScrollController scrollController;
  final String? initialPostId;

  const CircleListView({
    super.key,
    required this.docs,
    this.currentUserId,
    required this.scrollController,
    this.initialPostId,
  });

  @override
  State<CircleListView> createState() => _CircleListViewState();
}

class _CircleListViewState extends State<CircleListView> {
  final Map<String, double> _cardHeights = {}; // postId → 높이

  @override
  void initState() {
    super.initState();
    if (widget.initialPostId != null) {
      // 2프레임 대기 → 모든 카드 렌더링 후 스크롤
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToPost(widget.initialPostId!);
        });
      });
    }
  }

  void _updateCardHeight(String postId, double height) {
    if (_cardHeights[postId] != height) {
      setState(() {
        _cardHeights[postId] = height;
      });
    }
  }

  void _scrollToPost(String postId) {
    final index = widget.docs.indexWhere((doc) => doc.id == postId);
    if (index == -1) return;

    // 이전 카드들의 높이 합산
    double offset = 0;
    for (int i = 0; i < index; i++) {
      final id = widget.docs[i].id;
      offset += _cardHeights[id] ?? 520.0; // 기본값 520
    }

    // 현재 카드 중앙 정렬
    final currentHeight = _cardHeights[postId] ?? 520.0;
    offset += currentHeight / 2 - 200; // 화면 중앙 (-200 조정 가능)

    // 스크롤 애니메이션
    widget.scrollController.animateTo(
      offset.clamp(0.0, widget.scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const ValueKey('list'),
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.docs.length,
      itemBuilder: (context, index) {
        final doc = widget.docs[index];
        final postId = doc.id;

        return PostCard(
          key: ValueKey(postId),
          doc: doc,
          currentUserId: widget.currentUserId,
          onHeightCalculated: (height) => _updateCardHeight(postId, height),
        );
      },
    );
  }
}