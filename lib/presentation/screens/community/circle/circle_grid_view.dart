// lib/presentation/screens/community/circle/circle_grid_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/post_grid_item.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

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

  String? _extractThumbnailUrl(Map<String, dynamic> data) {
    // 1) 새 방식: imageUrls 배열
    final dynamic images = data['imageUrls'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
    }
    // 2) 예전 방식: photoUrl 단일 필드
    final p = (data['photoUrl'] as String?)?.trim();
    if (p != null && p.isNotEmpty) return p;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩

    if (docs.isEmpty) {
      return Center(child: Text(s.circle_no_visible_posts));
    }
    return _buildGrid(context, docs, s);
  }

  Widget _buildGrid(BuildContext context, List<QueryDocumentSnapshot> gridDocs, AppLocalizations s) {
    return GridView.builder(
      key: const ValueKey('grid'),
      controller: scrollController,
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemCount: gridDocs.length,
      itemBuilder: (_, i) {
        final data = gridDocs[i].data() as Map<String, dynamic>;
        final postId = gridDocs[i].id;

        final photoUrl = _extractThumbnailUrl(data);
        final hasNetworkPhoto = photoUrl != null && photoUrl.isNotEmpty;

        // ✅ 사진이 없으면 기본 이미지로 채움
        if (!hasNetworkPhoto) {
          return _DefaultGridTile(
            assetPath: _defaultThumbAsset,
            onTap: () => onItemTap(postId),
            label: s.community_preview_type_text, // 🔹 다국어 라벨 전달
          );
        }

        return PostGridItem(
          photoUrl: photoUrl!,
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
  final String label; // 🔹 추가

  const _DefaultGridTile({
    required this.assetPath,
    required this.onTap,
    required this.label, // 🔹 추가
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
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notes_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      label, // 🔹 다국어 적용
                      style: const TextStyle(
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