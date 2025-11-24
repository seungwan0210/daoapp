// lib/presentation/screens/user/my_log/widgets/my_log_card.dart
import 'package:flutter/material.dart';
import 'package:daoapp/data/models/my_log_model.dart';
import 'package:intl/intl.dart';

class MyLogCard extends StatelessWidget {
  final MyLogModel log;
  final bool showDate;

  const MyLogCard({
    super.key,
    required this.log,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
    DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(log.date);

    final hasPhoto = log.photoUrls.isNotEmpty;
    final photoUrl = hasPhoto ? log.photoUrls.first : null;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== 날짜 + 공유 뱃지 =====
            if (showDate) ...[
              Row(
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (log.isSharedToCircle == true)
                    _buildSharedBadge(context),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // ===== 사진 영역 =====
            if (photoUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  photoUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) {
                    return Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 60,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '사진을 불러올 수 없어요',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ===== 내용 =====
            if (log.content?.isNotEmpty == true)
              Text(
                log.content!,
                style: const TextStyle(
                  fontSize: 16.5,
                  height: 1.75,
                  letterSpacing: -0.2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 공유됨 뱃지 위젯
  Widget _buildSharedBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primary
            .withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.share,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '서클 공유됨',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
