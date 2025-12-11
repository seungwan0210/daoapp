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
    final theme = Theme.of(context);
    final dateStr =
    DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(log.date);

    final hasPhoto = log.photoUrls.isNotEmpty;
    final photoUrl = hasPhoto ? log.photoUrls.first : null;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // 상단에 살짝 네온 느낌 나는 다트 포인트 라인
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0F172A),
              Color(0xFF020617),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== 상단 헤더: 아이콘 + 날짜 + 공유 뱃지 =====
              if (showDate) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🎯 다트 아이콘 배지
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF22D3EE),
                            Color(0xFF0EA5E9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyan.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        '🎯',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 날짜 + 서브 타이틀
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '오늘의 다트 이야기',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey[100],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (log.isSharedToCircle == true)
                      _buildSharedBadge(theme),
                  ],
                ),
                const SizedBox(height: 16),
                // 헤더와 본문 사이 구분선 (살짝 네온 느낌)
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        Colors.cyanAccent.withOpacity(0.8),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                // 상세 화면에서 showDate=false일 때는 살짝 여백만
                if (log.isSharedToCircle == true) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildSharedBadge(theme),
                  ),
                  const SizedBox(height: 12),
                ],
              ],

              // ===== 사진 영역 =====
              if (photoUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Image.network(
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
                      // 사진 위 오른쪽 아래에 작은 태그
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '오늘의 샷',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // ===== 내용 =====
              if (log.content?.isNotEmpty == true)
                Text(
                  log.content!,
                  style: const TextStyle(
                    fontSize: 16.5,
                    height: 1.75,
                    letterSpacing: -0.2,
                    color: Colors.white,
                  ),
                )
              else
                Text(
                  '아직 내용이 없어요. 다음엔 오늘의 다트 이야기를 더 자세히 남겨볼까요?',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.blueGrey[100],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 공유됨 뱃지 위젯 (다트 스타일)
  Widget _buildSharedBadge(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: primary.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 16,
            color: primary,
          ),
          const SizedBox(width: 6),
          Text(
            '서클에 공유됨',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}
