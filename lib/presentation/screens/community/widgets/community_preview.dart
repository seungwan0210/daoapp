// lib/presentation/screens/community/widgets/community_preview.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ 추가
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/presentation/providers/app_providers.dart'; // ✅ 중앙 차단 프로바이더 추가

class CommunityPreview extends ConsumerStatefulWidget { // 👈 ConsumerStatefulWidget으로 변경
  final VoidCallback onSeeAllPressed;
  const CommunityPreview({super.key, required this.onSeeAllPressed});

  @override
  ConsumerState<CommunityPreview> createState() => _CommunityPreviewState();
}

class _CommunityPreviewState extends ConsumerState<CommunityPreview> {
  int _tab = 0;
  static const String _defaultThumbAsset = 'assets/images/circle_main.png';

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  // ✅ [삭제] 이제 개별 스트림 함수(_blockedIdsStream)는 필요 없습니다.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ [핵심 수정] 중앙 집중식 차단 목록 구독
    final blockedIds = ref.watch(blockedUserIdsProvider).value ?? {};

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 상단 토글 + 전체보기
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _TabChip(
                label: '최근',
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              const SizedBox(width: 8),
              _TabChip(
                label: '인기',
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onSeeAllPressed,
                child: const Text('전체 보기'),
              ),
            ],
          ),
        ),

        // 썸네일 영역 (중앙 blockedIds 전달)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 108,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: _tab == 0
                ? _buildRecentList(context, blockedIds)
                : _buildPopularList(context, blockedIds),
          ),
        ),

        const SizedBox(height: 10),

        // 오늘 커뮤니티 요약 (중앙 blockedIds 전달)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _TodayCommunitySummaryCard(blockedIds: blockedIds),
        ),

        const SizedBox(height: 10),

        // 지금 올라온 글 (중앙 blockedIds 전달)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _LiveTextPreviewList(
            blockedIds: blockedIds,
            onTapPost: (postId) {
              if (!context.mounted) return;
              Navigator.pushNamed(context, RouteConstants.circle, arguments: postId);
            },
            limit: 5,
          ),
        ),

        const SizedBox(height: 6),
      ],
    );
  }

  // 최근/인기 리스트 빌더 (기존 로직 유지하되 blockedIds는 중앙에서 온 것 사용)
  Widget _buildRecentList(BuildContext context, Set<String> blockedIds) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;

        final filtered = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final postUserId = (data['userId'] as String?)?.trim();
          return postUserId == null || !blockedIds.contains(postUserId);
        }).toList();

        if (filtered.isEmpty) return const SizedBox();
        final shown = filtered.take(10).toList();

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: shown.length,
          itemBuilder: (context, i) {
            final data = shown[i].data() as Map<String, dynamic>;
            final postId = shown[i].id;
            return _buildPreviewItem(context, data, postId, showComments: true);
          },
        );
      },
    );
  }

  Widget _buildPopularList(BuildContext context, Set<String> blockedIds) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community')
          .orderBy('likes', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;

        final filtered = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final postUserId = (data['userId'] as String?)?.trim();
          return postUserId == null || !blockedIds.contains(postUserId);
        }).toList();

        if (filtered.isEmpty) return const SizedBox();
        final shown = filtered.take(10).toList();

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: shown.length,
          itemBuilder: (context, i) {
            final data = shown[i].data() as Map<String, dynamic>;
            final postId = shown[i].id;
            return _buildPreviewItem(context, data, postId, showComments: false);
          },
        );
      },
    );
  }

  String? _extractThumbnailUrl(Map<String, dynamic> data) {
    final direct = data['photoUrl'] as String?;
    if (direct != null && direct.trim().isNotEmpty) return direct.trim();

    final dynamic images = data['imageUrls'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();
    }
    return null;
  }

  Widget _buildPreviewItem(
      BuildContext context,
      Map<String, dynamic> data,
      String postId, {
        required bool showComments,
      }) {
    final theme = Theme.of(context);

    final photoUrl = _extractThumbnailUrl(data);
    final likes = data['likes'] as int? ?? 0;
    final comments = data['comments'] as int? ?? 0;

    final bool hasNetworkThumb = photoUrl != null;

    return GestureDetector(
      onTap: () {
        if (!context.mounted) return;
        Navigator.pushNamed(context, RouteConstants.circle, arguments: postId);
      },
      child: SizedBox(
        width: 92,
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.grey[100],
                  child: hasNetworkThumb
                      ? Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    width: 92,
                    height: 92,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Image.asset(
                        _defaultThumbAsset,
                        fit: BoxFit.cover,
                        width: 92,
                        height: 92,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        _defaultThumbAsset,
                        fit: BoxFit.cover,
                        width: 92,
                        height: 92,
                      );
                    },
                  )
                      : Image.asset(
                    _defaultThumbAsset,
                    fit: BoxFit.cover,
                    width: 92,
                    height: 92,
                  ),
                ),
              ),

              if (!hasNetworkThumb)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notes_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          '글',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, color: Colors.white, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        '$likes',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      if (showComments) ...[
                        const SizedBox(width: 7),
                        const Icon(Icons.comment, color: Colors.white, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '$comments',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary.withOpacity(0.12) : Colors.grey[200],
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? theme.colorScheme.primary : Colors.black87,
          ),
        ),
      ),
    );
  }
}

/// ✅ (3) 오늘 커뮤니티 요약 카드 (차단 유저 글 제외)
class _TodayCommunitySummaryCard extends StatelessWidget {
  final Set<String> blockedIds;
  const _TodayCommunitySummaryCard({required this.blockedIds});

  DateTime _todayStartLocal() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isBlockedPost(Map<String, dynamic> data) {
    final uid = (data['userId'] as String?)?.trim();
    if (uid == null || uid.isEmpty) return false;
    return blockedIds.contains(uid);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = _todayStartLocal();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .snapshots(),
      builder: (context, snapshot) {
        int posts = 0;
        int likes = 0;
        int comments = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;

          final filtered = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return !_isBlockedPost(data);
          }).toList();

          posts = filtered.length;

          for (final d in filtered) {
            final data = d.data() as Map<String, dynamic>;
            likes += (data['likes'] as int?) ?? 0;
            comments += (data['comments'] as int?) ?? 0;
          }
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.insights, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('오늘 커뮤니티', style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              _MiniStat(label: '게시글', value: posts),
              const SizedBox(width: 10),
              _MiniStat(label: '댓글', value: comments),
              const SizedBox(width: 10),
              _MiniStat(label: '좋아요', value: likes),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
      ],
    );
  }
}

/// ✅ (2) 지금 올라온 글 - 텍스트 미리보기 (차단 유저 글 제외)
class _LiveTextPreviewList extends StatelessWidget {
  final void Function(String postId) onTapPost;
  final int limit;
  final Set<String> blockedIds;

  const _LiveTextPreviewList({
    required this.onTapPost,
    this.limit = 5,
    required this.blockedIds,
  });

  String _safeTitle(Map<String, dynamic> data) {
    final t1 = (data['title'] as String?)?.trim();
    if (t1 != null && t1.isNotEmpty) return t1;

    final c = (data['content'] as String?)?.trim();
    if (c != null && c.isNotEmpty) {
      final firstLine = c.split('\n').first.trim();
      return firstLine.isNotEmpty ? firstLine : '새 게시글';
    }
    return '새 게시글';
  }

  bool _isBlockedPost(Map<String, dynamic> data) {
    final uid = (data['userId'] as String?)?.trim();
    if (uid == null || uid.isEmpty) return false;
    return blockedIds.contains(uid);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community')
          .orderBy('timestamp', descending: true)
          .limit(30) // ✅ 필터링 대비
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const SizedBox.shrink();

        final filtered = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return !_isBlockedPost(data);
        }).take(limit).toList();

        if (filtered.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, color: theme.colorScheme.primary, size: 18),
                  const SizedBox(width: 6),
                  const Text('지금 올라온 글', style: TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 8),
              ...filtered.map((d) {
                final data = d.data() as Map<String, dynamic>;
                final postId = d.id;
                final title = _safeTitle(data);
                final likes = data['likes'] as int? ?? 0;
                final comments = data['comments'] as int? ?? 0;

                return InkWell(
                  onTap: () => onTapPost(postId),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '• $title',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('❤️ $likes', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                        const SizedBox(width: 8),
                        Text('💬 $comments', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
