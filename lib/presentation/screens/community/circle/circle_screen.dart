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
  const CircleScreen({super.key, this.initialPostId});

  @override
  ConsumerState<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends ConsumerState<CircleScreen> {
  FeedMode _mode = FeedMode.grid;
  String? _initialPostId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPostId != null) {
      _mode = FeedMode.list;
      _initialPostId = widget.initialPostId;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _switchToListMode(String postId) {
    setState(() {
      _mode = FeedMode.list;
      _initialPostId = postId;
    });
  }

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
            onPressed: () => Navigator.pushNamed(context, RouteConstants.postWrite),
          ),
        ],
      ),
      body: SafeArea(
        child: authState.when(
          data: (user) {
            if (user == null) {
              return const Center(child: Text("로그인 후 이용 가능합니다"));
            }

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final hasProfile = snapshot.data?.get('hasProfile') ?? false;
                if (!hasProfile) {
                  return const Center(child: Text("프로필 등록 후 이용 가능합니다"));
                }

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    const CommunityAvatarSlider(),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ref.watch(circleFeedProvider).when(
                        data: (querySnapshot) {
                          final docs = querySnapshot.docs;
                          if (docs.isEmpty) {
                            return const Center(child: Text('아직 게시물이 없습니다'));
                          }

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: _mode == FeedMode.grid
                                ? CircleGridView(
                              key: const ValueKey('grid'),
                              docs: docs,
                              onItemTap: _switchToListMode,
                            )
                                : CircleListView(
                              key: const ValueKey('list'),
                              docs: docs,
                              currentUserId: currentUserId,
                              scrollController: _scrollController,
                              initialPostId: _initialPostId,
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Center(child: Text("오류 발생")),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text("오류 발생")),
        ),
      ),
    );
  }
}