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
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

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
  final ScrollController _gridScrollController = ScrollController();

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
    _gridScrollController.dispose();
    super.dispose();
  }

  void _switchToListMode(String postId) {
    if (_gridScrollController.hasClients) _gridScrollController.jumpTo(0);
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

  Future<void> _acceptUgcTerms(String uid) async {
    final s = AppLocalizations.of(context)!;
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
          content: Text(s.community_home_ugc_msg_fail(e.toString())),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildFeed({
    required List<QueryDocumentSnapshot> docs,
    required String? currentUserId,
  }) {
    final listKey = ValueKey('list_${_initialPostId ?? 'top'}');

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final slideTween = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: animation.drive(slideTween), child: child),
        );
      },
      child: _mode == FeedMode.grid
          ? CircleGridView(
        key: const ValueKey('grid'),
        docs: docs,
        onItemTap: _switchToListMode,
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
    final s = AppLocalizations.of(context)!; // 🔹 언어팩
    final authState = ref.watch(authStateProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final blockedIds = ref.watch(blockedUserIdsProvider).value ?? {};

    return Scaffold(
      appBar: CommonAppBar(
        title: s.circle_title,
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
            if (user == null) return Center(child: Text(s.login_required));

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final hasProfile = data['hasProfile'] == true;
                if (!hasProfile) return Center(child: Text(s.circle_profile_required));

                final ugcAccepted = data['ugcTermsAccepted'] == true;
                if (!ugcAccepted) return _buildUgcTermsGate(context: context, theme: Theme.of(context), s: s, uid: user.uid);

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    const CommunityAvatarSlider(),
                    const SizedBox(height: 12),

                    Expanded(
                      child: ref.watch(circleFeedProvider).when(
                        data: (querySnapshot) {
                          final allDocs = querySnapshot.docs;
                          if (allDocs.isEmpty) return Center(child: Text(s.circle_no_posts));

                          final visibleDocs = allDocs.where((d) {
                            final postUserId = (d.data() as Map<String, dynamic>)['userId'] as String?;
                            return postUserId == null || !blockedIds.contains(postUserId);
                          }).toList();

                          if (visibleDocs.isEmpty) return Center(child: Text(s.circle_no_visible_posts));

                          return _buildFeed(docs: visibleDocs, currentUserId: currentUserId);
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => Center(child: Text(s.circle_error_feed)),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(s.circle_error_auth)),
        ),
      ),
    );
  }

  Widget _buildUgcTermsGate({
    required BuildContext context,
    required ThemeData theme,
    required AppLocalizations s, // 🔹 추가
    required String uid
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
                Text(s.community_home_ugc_title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(s.community_home_ugc_desc,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[800], height: 1.45)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.community_home_ugc_msg_reject), behavior: SnackBarBehavior.floating)), child: Text(s.community_home_ugc_btn_no))),
                    const SizedBox(width: 10),
                    Expanded(child: FilledButton(onPressed: () => _acceptUgcTerms(uid), child: Text(s.community_home_ugc_btn_yes))),
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