// lib/presentation/screens/community/circle/circle_grid_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/post_grid_item.dart';

class CircleGridView extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final void Function(String) onItemTap;

  /// ✅ (옵션) Grid 스크롤 제어/유지용
  final ScrollController? scrollController;

  const CircleGridView({
    super.key,
    required this.docs,
    required this.onItemTap,
    this.scrollController,
  });

  static const String _defaultThumbAsset = 'assets/images/circle_main.png';

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const ValueKey('grid'),
      controller: scrollController, // ✅ attach 가능하게
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemCount: docs.length,
      itemBuilder: (_, i) {
        final data = docs[i].data() as Map<String, dynamic>;
        final postId = docs[i].id;

        // 1) 새 방식: imageUrls 배열
        final List<dynamic>? images = data['imageUrls'] as List<dynamic>?;
        String? photoUrl;
        if (images != null && images.isNotEmpty) {
          final first = images.first;
          if (first is String && first.trim().isNotEmpty) {
            photoUrl = first.trim();
          }
        }

        // 2) 예전 방식: photoUrl 단일 필드
        photoUrl ??= (data['photoUrl'] as String?)?.trim();

        final hasNetworkPhoto = photoUrl != null && photoUrl!.isNotEmpty;

        // ✅ 사진이 없으면 shrink로 구멍 만들지 말고 "기본 이미지"로 채움
        if (!hasNetworkPhoto) {
          return _DefaultGridTile(
            assetPath: _defaultThumbAsset,
            onTap: () => onItemTap(postId),
          );
        }

        // ✅ 사진이 있으면 네트워크 썸네일 (PostGridItem의 로딩/에러 UX 활용)
        return PostGridItem(
          photoUrl: photoUrl!,
          // heroTag: 'post_$postId', // 필요하면 여기서 켜면 됨
          onTap: () => onItemTap(postId),
        );
      },
    );
  }
}

/// ✅ 글-only 게시물도 보이게: 기본 썸네일 타일
class _DefaultGridTile extends StatelessWidget {
  final String assetPath;
  final VoidCallback onTap;

  const _DefaultGridTile({
    required this.assetPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              assetPath,
              fit: BoxFit.cover,
            ),
            // ✅ "글" 느낌을 아주 약하게 표시(원하면 삭제 가능)
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
          ],
        ),
      ),
    );
  }
}
