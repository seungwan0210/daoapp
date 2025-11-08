// lib/presentation/screens/community/circle/circle_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/widgets/circle_avatar_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/data/models/user_model.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class CircleScreen extends ConsumerStatefulWidget {
  const CircleScreen({super.key});

  @override
  ConsumerState<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends ConsumerState<CircleScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // 좋아요 토글
  Future<void> _toggleLike(String postId, String userId, bool isLiked) async {
    final postRef = FirebaseFirestore.instance.collection('community').doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);

    if (isLiked) {
      await likeRef.delete();
      await postRef.update({'likes': FieldValue.increment(-1)});
    } else {
      await likeRef.set({'timestamp': FieldValue.serverTimestamp()});
      await postRef.update({'likes': FieldValue.increment(1)});
    }
  }

  // 댓글 작성
  Future<void> _addComment(String postId) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = AppUser.fromMap(user.uid, userDoc.data()!);

    final ref = FirebaseFirestore.instance
        .collection('community')
        .doc(postId)
        .collection('comments')
        .doc();

    await ref.set({
      'userId': user.uid,
      'displayName': userData.koreanName ?? 'Unknown',
      'userPhotoUrl': userData.profileImageUrl,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('community')
        .doc(postId)
        .update({'comments': FieldValue.increment(1)});

    _commentController.clear();
  }

  // 내 글 삭제
  Future<void> _deletePost(String postId) async {
    await FirebaseFirestore.instance.collection('community').doc(postId).delete();
  }

  // 내 글 수정
  void _editPost(String postId, String currentContent) {
    final editController = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("게시물 수정"),
        content: TextField(
          controller: editController,
          maxLines: 5,
          decoration: const InputDecoration(hintText: "내용을 수정하세요"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
          ElevatedButton(
            onPressed: () async {
              final newContent = editController.text.trim();
              if (newContent.isEmpty) return;
              await FirebaseFirestore.instance
                  .collection('community')
                  .doc(postId)
                  .update({'content': newContent});
              Navigator.pop(ctx);
            },
            child: const Text("수정"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: '피드',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, RouteConstants.postWrite),
            tooltip: '게시물 작성',
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

                final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final hasProfile = userData['hasProfile'] as bool? ?? false;

                if (!hasProfile) {
                  return const Center(child: Text("프로필 등록 후 이용 가능합니다"));
                }

                return Column(
                  children: [
                    const ProfileAvatarSlider(),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('community')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final docs = snapshot.data!.docs;
                          return GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                              childAspectRatio: 1,
                            ),
                            itemCount: docs.length,
                            itemBuilder: (_, i) {
                              final doc = docs[i];
                              final data = doc.data() as Map<String, dynamic>;
                              final postId = doc.id;
                              final postUserId = data['userId'] as String;
                              final isMyPost = postUserId == user.uid;
                              return _buildPostGridItem(context, data, postId, user.uid, isMyPost);
                            },
                          );
                        },
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

  // 3장씩 그리드 아이템
  Widget _buildPostGridItem(BuildContext context, Map<String, dynamic> data, String postId, String currentUserId, bool isMyPost) {
    final photoUrl = data['photoUrl'] as String?;
    final likes = data['likes'] as int? ?? 0;
    final comments = data['comments'] as int? ?? 0;

    if (photoUrl == null || photoUrl.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showPostDialog(context, postId, currentUserId, isMyPost),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              photoUrl,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 14),
                  const SizedBox(width: 2),
                  Text('$likes', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.comment, color: Colors.white, size: 14),
                  const SizedBox(width: 2),
                  Text('$comments', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 실시간 다이얼로그
  void _showPostDialog(BuildContext context, String postId, String currentUserId, bool isMyPost) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('community').doc(postId).snapshots(),
            builder: (context, postSnapshot) {
              if (!postSnapshot.hasData) return const Center(child: CircularProgressIndicator());

              final data = postSnapshot.data!.data() as Map<String, dynamic>;
              final photoUrl = data['photoUrl'] as String?;
              final name = data['displayName'] ?? 'Unknown';
              final content = data['content'] ?? '';
              final timeAgo = _formatTimeAgo((data['timestamp'] as Timestamp).toDate());
              final likes = data['likes'] as int? ?? 0;
              final comments = data['comments'] as int? ?? 0;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: data['userPhotoUrl'] != null ? NetworkImage(data['userPhotoUrl']) : null,
                          child: data['userPhotoUrl'] == null ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(timeAgo, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                        if (isMyPost)
                          PopupMenuButton(
                            onSelected: (value) {
                              if (value == 'edit') _editPost(postId, content);
                              if (value == 'delete') {
                                _deletePost(postId);
                                Navigator.pop(ctx);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Text("수정")),
                              const PopupMenuItem(value: 'delete', child: Text("삭제")),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // 사진
                  if (photoUrl != null)
                    Flexible(
                      flex: 3,
                      child: Image.network(photoUrl, fit: BoxFit.contain, width: double.infinity),
                    ),

                  // 내용
                  if (content.isNotEmpty)
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Text(content),
                      ),
                    ),

                  // 좋아요 + 댓글 수 (실시간)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('community')
                              .doc(postId)
                              .collection('likes')
                              .doc(currentUserId)
                              .snapshots(),
                          builder: (context, likeSnapshot) {
                            final isLiked = likeSnapshot.hasData && likeSnapshot.data!.exists;
                            return Row(
                              children: [
                                IconButton(
                                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : null),
                                  onPressed: () => _toggleLike(postId, currentUserId, isLiked),
                                ),
                                Text('$likes'),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Text('$comments 댓글'),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // 댓글 목록 (실시간)
                  Flexible(
                    flex: 2,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('community')
                          .doc(postId)
                          .collection('comments')
                          .orderBy('timestamp')
                          .snapshots(),
                      builder: (context, commentSnapshot) {
                        if (!commentSnapshot.hasData) return const SizedBox();
                        final comments = commentSnapshot.data!.docs;
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: comments.length,
                          itemBuilder: (_, i) {
                            final c = comments[i].data() as Map<String, dynamic>;
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundImage: c['userPhotoUrl'] != null ? NetworkImage(c['userPhotoUrl']) : null,
                                child: c['userPhotoUrl'] == null ? const Icon(Icons.person, size: 16) : null,
                              ),
                              title: Text(c['displayName'] ?? 'Unknown', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              subtitle: Text(c['content'] ?? '', style: const TextStyle(fontSize: 13)),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // 댓글 입력
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: "댓글을 입력하세요...",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _addComment(postId);
                            _commentController.clear();
                          },
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(12),
                          ),
                          child: const Icon(Icons.send, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}