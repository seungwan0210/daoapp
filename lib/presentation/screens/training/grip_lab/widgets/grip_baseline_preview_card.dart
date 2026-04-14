// lib/presentation/screens/training/grip_lab/widgets/grip_baseline_preview_card.dart
import 'package:flutter/material.dart';

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
            // ✅ 수정됨: 가로형 박스지만, 내부는 'contain'으로 전체 다 보여주기
            Container(
              height: 220, // 높이를 고정하거나 AspectRatio 조절
              width: double.infinity,
              color: const Color(0xFF1A1A1A), // 배경을 어둡게 처리 (사진 집중도 UP)
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain, // ✅ 잘리지 않고 전체가 다 나옴
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text("이미지를 불러올 수 없어요", style: TextStyle(fontSize: 12)),
                  ),
                ),
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.cyan,
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),

            // 하단 정보 영역 (기존 유지)
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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