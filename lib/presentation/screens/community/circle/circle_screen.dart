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

                final hasProfile = snapshot.data?.get('hasProfile') ?? false;
                if (!hasProfile) {
                  return const Center(child: Text('프로필 등록 후 이용 가능합니다'));
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

                          // ✅ List는 postId별로 key를 달리해서 전환 시 “상태 꼬임/튕김” 방지
                          final listKey =
                          ValueKey('list_${_initialPostId ?? 'top'}');

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
                              // ✅ Grid 스크롤 컨트롤러 연결(선택)
                              scrollController: _gridScrollController,
                            )
                                : CircleListView(
                              key: listKey,
                              docs: docs,
                              currentUserId: currentUserId,
                              initialPostId: _initialPostId,
                            ),
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
}
