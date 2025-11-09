// lib/presentation/providers/community_provider.dart
import 'dart:async'; // 필수 추가!
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 좋아요 상태 (임시 - UI 반영용)
final likeProvider = StateProvider.family<bool, String>((ref, postId) {
  return false; // 초기값
});

/// 댓글 리스트 실시간 반영
final commentProvider = StateNotifierProvider.family<CommentNotifier, List<Map<String, dynamic>>, String>(
      (ref, postId) {
    return CommentNotifier(postId);
  },
);

class CommentNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final String postId;
  late final StreamSubscription<QuerySnapshot> _subscription;

  CommentNotifier(this.postId) : super([]) {
    _subscription = FirebaseFirestore.instance
        .collection('community')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}