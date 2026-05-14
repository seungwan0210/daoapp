import 'package:flutter/material.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

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
    final s = AppLocalizations.of(context)!; // 🔹 언어팩

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
            Container(
              height: 220,
              width: double.infinity,
              color: const Color(0xFF1A1A1A),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Text(
                      s.grip_preview_load_error, // 🔹 다국어화
                      style: const TextStyle(fontSize: 12),
                    ),
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

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.grip_preview_created_at(createdLabel), // 🔹 {date} 파라미터 전달
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
                      s.grip_preview_frame(frameLabel), // 🔹 {id} 파라미터 전달
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