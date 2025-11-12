import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/post_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';

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
  final Map<String, double> _cardHeights = {};
  bool _hasScrolled = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPostId != null && !_hasScrolled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToPost(widget.initialPostId!);
        });
      });
    }
  }

  void _updateCardHeight(String postId, double height) {
    if (_cardHeights[postId] != height && mounted) {
      setState(() {
        _cardHeights[postId] = height;
      });
    }
  }

  void _scrollToPost(String postId) {
    final index = widget.docs.indexWhere((doc) => doc.id == postId);
    if (index == -1 || _hasScrolled) return;

    double offset = 0;
    for (int i = 0; i < index; i++) {
      final id = widget.docs[i].id;
      offset += _cardHeights[id] ?? 520.0;
    }

    final currentHeight = _cardHeights[postId] ?? 520.0;
    offset += currentHeight / 2 - 200;

    widget.scrollController.animateTo(
      offset.clamp(0.0, widget.scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );

    _hasScrolled = true;
  }

  // 수정 버튼 클릭
  void _editPost(BuildContext context, String postId) {
    Navigator.pushNamed(
      context,
      RouteConstants.postWrite,
      arguments: {'postId': postId},
    );
  }

  // 삭제 버튼 클릭
  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 게시물을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
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
          onEdit: () => _editPost(context, postId),
          onDelete: () => _deletePost(postId),
        );
      },
    );
  }
}