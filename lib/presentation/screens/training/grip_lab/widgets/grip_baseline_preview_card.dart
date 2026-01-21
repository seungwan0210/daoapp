// lib/presentation/screens/training/grip_lab/widgets/grip_baseline_preview_card.dart
import 'package:flutter/material.dart';

/// 그립 연구소 - 기준 그립 프리뷰 카드
///
/// - 네트워크 이미지(기준 이미지 URL) 미리보기
/// - 저장일/프레임 정보 표시
///
/// 사용 예)
/// GripBaselinePreviewCard(
///   imageUrl: baseline.imageUrl,
///   createdLabel: "2026-01-20 01:12",
///   frameLabel: "1280×720",
/// )
class GripBaselinePreviewCard extends StatelessWidget {
  final String imageUrl;
  final String createdLabel;
  final String frameLabel;

  const GripBaselinePreviewCard({
    super.key,
    required this.imageUrl,
    required this.createdLabel,
    required this.frameLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text("이미지를 불러올 수 없어요"),
                  ),
                ),
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.cyan),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "저장일: $createdLabel",
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.cyan.withOpacity(0.25)),
                    ),
                    child: Text(
                      "Frame $frameLabel",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.cyan[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
