import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/user_profile_dialog.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
// ✅ 수정 코드 (랭킹 프로바이더 하나로 통합)
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';
import 'package:daoapp/presentation/providers/app_providers.dart'; // ✅ 임포트 추가
import 'package:firebase_auth/firebase_auth.dart';
import 'comment_bottom_sheet.dart';

class CommentPreview extends ConsumerWidget {
  final String postId;
  final String? currentUserId;

  const CommentPreview({
    super.key,
    required this.postId,
    this.currentUserId,
  });

  String? _writerIdFrom(Map<String, dynamic> data) =>
      (data['writerId'] as String?) ?? (data['userId'] as String?);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🆕 실시간 통합 랭킹 구독
    final totalRanking = ref.watch(totalRankingProvider);

    // ✅ [핵심] 중앙 집중식 실시간 차단 목록 구독
    final blockedIds = ref.watch(blockedUserIdsProvider).value ?? {};

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community')
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .limit(10) // 차단 유저를 걸러야 하므로 조금 더 넉넉하게 가져옵니다.
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        // 🔥 [필터링] 중앙 차단 목록을 기준으로 즉시 필터링
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final writerId = _writerIdFrom(data);
          return writerId == null || !blockedIds.contains(writerId.trim());
        }).toList();

        if (filteredDocs.isEmpty) return const SizedBox.shrink();

        // 필터링된 결과 중 상위 3개만 미리보기에 표시
        final previewDocs = filteredDocs.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...previewDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String? writerId = _writerIdFrom(data);
              final content = (data['content'] as String?) ?? '';

              // 실시간 순위 확인
              final rankIndex = totalRanking.indexWhere((item) => item['userId'] == writerId);
              final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildAvatar(writerId),
                        if (currentRank != null)
                          Positioned(
                            left: -3, top: -3,
                            child: BadgeWidget(rank: currentRank, size: 12),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                          children: [
                            WidgetSpan(
                              child: _buildWriterName(context, writerId),
                            ),
                            const TextSpan(text: '  '),
                            TextSpan(text: content),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            if (filteredDocs.length >= 3)
              TextButton(
                onPressed: () => CommentBottomSheet.show(context, postId),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '댓글 모두 보기',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // 작성자 이름 실시간 렌더링
  Widget _buildWriterName(BuildContext context, String? writerId) {
    if (writerId == null) return const Text('익명', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(writerId).snapshots(),
      builder: (context, userSnap) {
        final name = (userSnap.hasData && userSnap.data!.exists)
            ? (userSnap.data!.data() as Map<String, dynamic>)['koreanName'] ?? '익명'
            : '익명';

        return GestureDetector(
          onTap: () => _showProfile(context, writerId),
          child: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }

  // 아바타 위젯 (승완님 로직 유지)
  Widget _buildAvatar(String? userId) {
    if (userId == null) return CircleAvatar(radius: 12, backgroundColor: Colors.grey[300], child: const Icon(Icons.person, size: 16));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          photoUrl = (snapshot.data!.data() as Map<String, dynamic>?)?['profileImageUrl'];
        }
        return CircleAvatar(
          radius: 12,
          backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
          backgroundColor: Colors.grey[300],
          child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person, size: 16, color: Colors.white) : null,
        );
      },
    );
  }

  // 프로필 다이얼로그 (승완님 로직 유지)
  void _showProfile(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (_) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          return UserProfileDialog(
            koreanName: data['koreanName'] ?? '이름 없음',
            photoUrl: data['profileImageUrl'],
            userId: userId,
            isMe: FirebaseAuth.instance.currentUser?.uid == userId,
          );
        },
      ),
    );
  }
}