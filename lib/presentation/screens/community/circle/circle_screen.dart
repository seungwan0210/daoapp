// lib/presentation/screens/community/circle/circle_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/providers/circle_feed_provider.dart';
import 'package:daoapp/presentation/screens/community/circle/circle_grid_view.dart';
import 'package:daoapp/presentation/screens/community/circle/circle_list_view.dart';
import 'package:daoapp/presentation/screens/community/widgets/community_avatar_slider.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

enum FeedMode { grid, list }

class CircleScreen extends ConsumerStatefulWidget {
  final String? initialPostId;

  const CircleScreen({
    super.key,
    this.initialPostId,
  });

  @override
  ConsumerState<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends ConsumerState<CircleScreen> {
  FeedMode _mode = FeedMode.grid;
  String? _initialPostId;

  // ✅ Grid 스크롤(추후 복원용) - List(ScrollablePositionedList)에는 사용하지 않음
  final ScrollController _gridScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 🔹 외부에서 특정 게시물로 진입한 경우 (알림, 썸네일 클릭 등)
    if (widget.initialPostId != null) {
      _mode = FeedMode.list;
      _initialPostId = widget.initialPostId;
    }
  }

  @override
  void dispose() {
    _gridScrollController.dispose();
    super.dispose();
  }

  /// 🔹 Grid → List 전환
  void _switchToListMode(String postId) {
    // ✅ 크래시 방지 (Grid가 실제 attach 되었을 때만)
    if (_gridScrollController.hasClients) {
      _gridScrollController.jumpTo(0);
    }

    setState(() {
      _mode = FeedMode.list;
      _initialPostId = postId;
    });
  }

  /// 🔹 List → Grid 복귀
  void _switchToGridMode() {
    setState(() {
      _mode = FeedMode.grid;
      _initialPostId = null;
    });
  }

  /// ✅ UGC(커뮤니티) 동의 저장
  Future<void> _acceptUgcTerms(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'ugcTermsAccepted': true,
          'ugcTermsAcceptedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('동의 처리 실패: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================
  // ✅ 차단 유저 목록(IDs) 스트림
  // ==========================
  Stream<Set<String>> _blockedIdsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('blockedUsers')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  // ==========================
  // ✅ 차단 필터 적용된 docs 만들기
  // ==========================
  List<QueryDocumentSnapshot> _filterBlockedDocs(
      List<QueryDocumentSnapshot> docs,
      Set<String> blockedIds,
      ) {
    return docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      final postUserId = (data['userId'] as String?)?.trim();
      if (postUserId == null || postUserId.isEmpty) return true;
      return !blockedIds.contains(postUserId);
    }).toList();
  }

  // ==========================
  // ✅ Grid/List 공통 렌더
  // ==========================
  Widget _buildFeed({
    required List<QueryDocumentSnapshot> docs,
    required String? currentUserId,
  }) {
    // ✅ List는 postId별로 key를 달리해서 전환 시 “상태 꼬임/튕김” 방지
    final listKey = ValueKey('list_${_initialPostId ?? 'top'}');

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,

      // ✅ Fade + 살짝 Slide 업
      transitionBuilder: (child, animation) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );

        final slideTween = Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).chain(
          CurveTween(curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },

      child: _mode == FeedMode.grid
          ? CircleGridView(
        key: const ValueKey('grid'),
        docs: docs,
        onItemTap: _switchToListMode,
        // ✅ 이제 GridView 내부에서 차단 필터를 또 하지 않아도 됨
        // currentUserId: currentUserId, // (원하면 CircleGridView에서 제거 가능)
        scrollController: _gridScrollController,
      )
          : CircleListView(
        key: listKey,
        docs: docs,
        currentUserId: currentUserId,
        initialPostId: _initialPostId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: CommonAppBar(
        title: '피드',
        showBackButton: _mode == FeedMode.list,
        onBackPressed: _switchToGridMode,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, RouteConstants.postWrite);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: authState.when(
          data: (user) {
            if (user == null) {
              return const Center(child: Text('로그인 후 이용 가능합니다'));
            }

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

                final hasProfile = data['hasProfile'] == true;
                if (!hasProfile) {
                  return const Center(child: Text('프로필 등록 후 이용 가능합니다'));
                }

                // ✅ CommunityHomeScreen에서 막았어도, CircleScreen에서 한번 더 막기(보험)
                final ugcAccepted = data['ugcTermsAccepted'] == true;
                if (!ugcAccepted) {
                  return _buildUgcTermsGate(
                    context: context,
                    theme: Theme.of(context),
                    uid: user.uid,
                  );
                }

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    const CommunityAvatarSlider(),
                    const SizedBox(height: 12),

                    /// ==========================
                    /// 피드 영역
                    /// ==========================
                    Expanded(
                      child: ref.watch(circleFeedProvider).when(
                        data: (querySnapshot) {
                          final docs = querySnapshot.docs;

                          if (docs.isEmpty) {
                            return const Center(child: Text('아직 게시물이 없습니다'));
                          }

                          // ✅ 여기서 “한 번만” 차단 필터를 걸어서
                          // Grid/List 둘 다 같은 docs를 쓰게 만들면
                          // 스크롤 index가 밀리는 문제가 사라짐.
                          if (currentUserId == null) {
                            return _buildFeed(
                              docs: docs,
                              currentUserId: currentUserId,
                            );
                          }

                          return StreamBuilder<Set<String>>(
                            stream: _blockedIdsStream(currentUserId),
                            builder: (context, blockedSnap) {
                              final blockedIds =
                                  blockedSnap.data ?? <String>{};

                              final visibleDocs =
                              _filterBlockedDocs(docs, blockedIds);

                              if (visibleDocs.isEmpty) {
                                return const Center(
                                  child: Text('표시할 게시물이 없습니다'),
                                );
                              }

                              return _buildFeed(
                                docs: visibleDocs,
                                currentUserId: currentUserId,
                              );
                            },
                          );
                        },
                        loading: () =>
                        const Center(child: CircularProgressIndicator()),
                        error: (_, __) =>
                        const Center(child: Text('피드를 불러오지 못했습니다')),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('로그인 상태 오류')),
        ),
      ),
    );
  }

  // ==========================
  // UGC 동의 게이트 UI
  // ==========================
  Widget _buildUgcTermsGate({
    required BuildContext context,
    required ThemeData theme,
    required String uid,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.policy_outlined, size: 64, color: Colors.grey[500]),
                const SizedBox(height: 18),
                Text(
                  '커뮤니티 이용 동의가 필요해요',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '커뮤니티에는 사용자가 작성한 글/사진(UGC)이 노출됩니다.\n'
                      '안전한 이용을 위해 아래 내용에 동의해 주세요.\n\n'
                      '• 타인을 비방/혐오/차별/괴롭힘하는 콘텐츠 금지\n'
                      '• 불법/음란/폭력/사기 등 유해 콘텐츠 금지\n'
                      '• 신고/차단 기능 및 운영 정책에 따라 제재될 수 있음\n'
                      '• 신고된 콘텐츠는 운영자가 검토할 수 있음',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[800],
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('동의 후 커뮤니티 이용이 가능합니다.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text('동의 안함'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _acceptUgcTerms(uid),
                        child: const Text('동의하고 시작'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
