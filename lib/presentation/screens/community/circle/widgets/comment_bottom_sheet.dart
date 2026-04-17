// lib/presentation/screens/community/circle/widgets/comment_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/user_profile_dialog.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/presentation/providers/training/ranking/total_ranking_provider.dart';

class CommentBottomSheet extends ConsumerStatefulWidget {
  final String postId;
  const CommentBottomSheet({super.key, required this.postId});

  static void show(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentBottomSheet(postId: postId),
    );
  }

  @override
  ConsumerState<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends ConsumerState<CommentBottomSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // =========================
  // 차단 목록 Stream (Set)
  // users/{me}/blockedUsers/{blockedUid}
  // =========================
  Stream<Set<String>> _blockedIdsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('blockedUsers')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  // =========================
  // writerId 추출 (호환)
  // =========================
  String? _writerIdFrom(Map<String, dynamic> data) {
    return (data['writerId'] as String?) ?? (data['userId'] as String?);
  }

  bool _isBlockedWriter(Map<String, dynamic> data, Set<String> blockedIds) {
    final w = _writerIdFrom(data);
    if (w == null || w.trim().isEmpty) return false;
    return blockedIds.contains(w.trim());
  }

  // =========================
  // 신고: 댓글
  // reports/{reportId}
  // =========================
  Future<void> _reportComment({
    required String postId,
    required String commentId,
    required String reportedUserId,
    required String reason,
    String? contentPreview,
  }) async {
    final reporterUid = _currentUid;
    if (reporterUid == null) return;

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'type': 'comment',
        'postId': postId,
        'commentId': commentId,
        'reportedUserId': reportedUserId,
        'reporterUserId': reporterUid,
        'reason': reason,
        'contentPreview': (contentPreview ?? '').toString().trim().isEmpty
            ? null
            : contentPreview!.toString().trim().substring(
          0,
          (contentPreview.length > 200) ? 200 : contentPreview.length,
        ),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고가 접수되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('신고 실패: $e')),
        );
      }
    }
  }

  // =========================
  // 신고 다이얼로그
  // =========================
  Future<void> _openReportDialog({
    required String postId,
    required String commentId,
    required String reportedUserId,
    required String contentPreview,
  }) async {
    final reasons = <String>[
      '스팸/도배',
      '욕설/비하',
      '혐오/차별',
      '성적/선정성',
      '개인정보 노출',
      '기타',
    ];

    String selected = reasons.first;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('댓글 신고'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('사유를 선택해 주세요'),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selected,
                    items: reasons
                        .map(
                          (r) => DropdownMenuItem(
                        value: r,
                        child: Text(r),
                      ),
                    )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => selected = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '미리보기: ${contentPreview.length > 80 ? contentPreview.substring(0, 80) + '…' : contentPreview}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('신고', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _reportComment(
        postId: postId,
        commentId: commentId,
        reportedUserId: reportedUserId,
        reason: selected,
        contentPreview: contentPreview,
      );
    }
  }

  // =========================
  // 댓글 작성
  // =========================
  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length > 300) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final commentRef = FirebaseFirestore.instance
        .collection('community')
        .doc(widget.postId)
        .collection('comments')
        .doc();

    await commentRef.set({
      'userId': user.uid, // 표시/호환용으로 유지
      'writerId': user.uid, // ✅ 권한 체크 핵심
      'content': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('community')
        .doc(widget.postId)
        .update({'comments': FieldValue.increment(1)});

    _controller.clear();
    FocusScope.of(context).unfocus();

    if (mounted && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // =========================
  // 댓글 삭제
  // =========================
  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 댓글을 삭제하시겠습니까?'),
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

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('community')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      await FirebaseFirestore.instance
          .collection('community')
          .doc(widget.postId)
          .update({'comments': FieldValue.increment(-1)});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('댓글이 삭제되었습니다'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = _currentUid;

    final isAdmin = ref.watch(isAdminProvider).when(
      data: (v) => v,
      loading: () => false,
      error: (_, __) => false,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // 핸들바
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            '댓글',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const Divider(height: 1),

        // === 댓글 리스트 ===
        Expanded(
          child: (currentUserId == null)
              ? _buildCommentsList(
            theme: theme,
            isAdmin: isAdmin,
            currentUserId: currentUserId,
            blockedIds: const <String>{},
          )
              : StreamBuilder<Set<String>>(
            stream: _blockedIdsStream(currentUserId),
            builder: (context, blockedSnap) {
              final blockedIds = blockedSnap.data ?? <String>{};
              return _buildCommentsList(
                theme: theme,
                isAdmin: isAdmin,
                currentUserId: currentUserId,
                blockedIds: blockedIds,
              );
            },
          ),
        ),

        // === 입력창 ===
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                20,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: '댓글을 입력하세요...',
                    border: InputBorder.none,
                    counterText: '',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
              GestureDetector(
                onTap: _sendComment,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.send, color: theme.colorScheme.primary, size: 24),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildCommentsList({
    required ThemeData theme,
    required bool isAdmin,
    required String? currentUserId,
    required Set<String> blockedIds,
  }) {
    // 🆕 실시간 통합 랭킹 데이터 구독 (ConsumerState 내부라면 ref 사용 가능)
    final totalRanking = ref.watch(totalRankingProvider);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('아직 댓글이 없습니다'));

        final filteredDocs = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return !_isBlockedWriter(data, blockedIds);
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text('표시할 댓글이 없습니다'));
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredDocs.length,
          itemBuilder: (context, i) {
            final doc = filteredDocs[i];
            final data = doc.data() as Map<String, dynamic>;
            final commentId = doc.id;
            final String? writerId = _writerIdFrom(data);
            final String? userId = (data['userId'] as String?) ?? writerId;

            final content = data['content'] as String? ?? '';
            final timestamp = data['timestamp'] as Timestamp?;
            final timeStr = timestamp != null
                ? AppDateUtils.formatRelativeTime(timestamp.toDate())
                : '방금 전';

            final isMyComment = writerId != null && writerId == currentUserId;
            final canDelete = isMyComment || isAdmin;
            final isLong = content.length > 80 || content.contains('\n');
            final canReport = !isMyComment && (writerId != null && writerId.isNotEmpty);

            // 🔥 작성자 실시간 순위 확인 (배지용)
            final rankIndex = totalRanking.indexWhere((item) => item['userId'] == userId);
            final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 아바타 + 실시간 배지 (사진 위 훈장 스타일)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: userId != null ? () => _showProfile(userId) : null,
                        child: _buildAvatar(userId),
                      ),
                      if (currentRank != null)
                        Positioned(
                          left: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 2),
                              ],
                            ),
                            child: BadgeWidget(rank: currentRank, size: 14), // 아바타 크기에 맞춰 14
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. 이름 영역 (중복 배지 제거 및 텍스트만 유지)
                        userId != null
                            ? StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                          builder: (context, userSnap) {
                            String name = '익명';
                            if (userSnap.hasData && userSnap.data!.exists) {
                              final userData = userSnap.data!.data() as Map<String, dynamic>?;
                              name = userData?['koreanName']?.toString().trim() ?? '익명';
                            }
                            return GestureDetector(
                              onTap: () => _showProfile(userId!),
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            );
                          },
                        )
                            : const Text(
                          '익명',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // 3. 댓글 내용 및 더보기
                        GestureDetector(
                          onTap: isLong ? () => _showFullComment('댓글', content) : null,
                          child: Text(
                            content,
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                            maxLines: isLong ? 2 : null,
                            overflow: isLong ? TextOverflow.ellipsis : null,
                          ),
                        ),
                        if (isLong)
                          TextButton(
                            onPressed: () => _showFullComment('댓글', content),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '더보기',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        Text(
                          timeStr,
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  // ✅ 메뉴: 삭제(내 댓글/관리자), 신고(타인 댓글)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, size: 16),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await _deleteComment(commentId);
                        return;
                      }
                      if (value == 'report' && writerId != null) {
                        await _openReportDialog(
                          postId: widget.postId,
                          commentId: commentId,
                          reportedUserId: writerId,
                          contentPreview: content,
                        );
                        return;
                      }
                    },
                    itemBuilder: (_) => [
                      if (canReport)
                        const PopupMenuItem(
                          value: 'report',
                          child: Text('신고', style: TextStyle(color: Colors.red)),
                        ),
                      if (canDelete)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('삭제', style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 아바타 — 안전
  Widget _buildAvatar(String? userId) {
    if (userId == null) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[300],
        child: const Icon(Icons.person, size: 20, color: Colors.grey),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          photoUrl = data?['profileImageUrl'] as String?;
        }

        return CircleAvatar(
          radius: 16,
          backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
          backgroundColor: photoUrl?.isNotEmpty != true ? Colors.grey[300] : null,
          child: photoUrl?.isNotEmpty != true
              ? const Icon(Icons.person, size: 20, color: Colors.white)
              : null,
        );
      },
    );
  }

  // 프로필 다이얼로그 — 안전
  void _showProfile(String userId) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = currentUid == userId;

    showDialog(
      context: context,
      builder: (_) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          if (!snapshot.data!.exists || snapshot.data!.data() == null) {
            return UserProfileDialog(koreanName: '프로필 없음', isMe: isMe, userId: userId);
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final hasProfile = data['hasProfile'] == true;
          if (!hasProfile) {
            return UserProfileDialog(koreanName: '프로필 미완료', isMe: isMe, userId: userId);
          }

          final koreanName = data['koreanName']?.toString().trim() ?? '이름 없음';
          final englishName = data['englishName']?.toString().trim();
          final String? photoUrl = data['profileImageUrl'] as String?;
          final shopName = data['shopName']?.toString().trim();

          final barrelName = data['barrelName']?.toString().trim() ?? '';
          final shaft = data['shaft']?.toString().trim() ?? '';
          final flight = data['flight']?.toString().trim() ?? '';
          final tip = data['tip']?.toString().trim() ?? '';
          final barrelImageUrl = data['barrelImageUrl'] as String?;

          final hasBarrelInfo = barrelName.isNotEmpty ||
              shaft.isNotEmpty ||
              flight.isNotEmpty ||
              tip.isNotEmpty ||
              (barrelImageUrl?.isNotEmpty == true);

          return UserProfileDialog(
            koreanName: koreanName,
            englishName: englishName,
            photoUrl: photoUrl,
            shopName: shopName,
            barrelData: hasBarrelInfo
                ? {
              'barrelImageUrl': barrelImageUrl,
              'barrelName': barrelName,
              'shaft': shaft,
              'flight': flight,
              'tip': tip,
            }
                : null,
            isMe: isMe,
            userId: userId,
          );
        },
      ),
    );
  }

  void _showFullComment(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기')),
        ],
      ),
    );
  }
}
