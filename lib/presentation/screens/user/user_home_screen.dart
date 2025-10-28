// lib/presentation/screens/user/user_home_screen.dart

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/providers/user_home_provider.dart';
import 'package:daoapp/presentation/screens/user/calendar_screen.dart';
import 'package:daoapp/presentation/screens/user/ranking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스틸리그 포인트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNoticeSection(),
            const SizedBox(height: 24),
            _buildNextEventCard(context),
            const SizedBox(height: 24),
            _buildTop3Ranking(context),
            const SizedBox(height: 24),
            _buildNewsPosterSlider(),
            const SizedBox(height: 24),
            _buildSponsorBanner(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /* ────────────────────────── 공지사항 ────────────────────────── */
  Widget _buildNoticeSection() {
    return Consumer(
      builder: (context, ref, child) {
        final asyncNotices = ref.watch(noticeBannerProvider);
        return asyncNotices.when(
          data: (snapshot) {
            if (snapshot.docs.isEmpty) {
              return _buildEmptyBanner('공지 없음');
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '공지사항',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: 50,
                      autoPlay: true,
                      viewportFraction: 1.0,
                      autoPlayInterval: const Duration(seconds: 4),
                      enableInfiniteScroll: snapshot.docs.length > 1,
                    ),
                    items: snapshot.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title = data['title'] as String? ?? '';

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _handleNoticeTap(context, data),
                          child: Container(
                            width: double.infinity,
                            padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color:
                              const Color(0xFF00D4FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
          loading: () => _buildShimmerBanner(),
          error: (_, __) => const Text('공지 로드 오류'),
        );
      },
    );
  }

  /* ────────────────────────── 뉴스 포스터 슬라이더 ────────────────────────── */
  Widget _buildNewsPosterSlider() {
    return Consumer(
      builder: (context, ref, child) {
        final asyncNews = ref.watch(newsProvider);
        return asyncNews.when(
          data: (snapshot) {
            if (snapshot.docs.isEmpty) {
              return const Text(
                '뉴스 없음',
                style: TextStyle(color: Colors.grey),
              );
            }

            final items = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'imageUrl': data['imageUrl'] as String?,
                'title': data['title'] as String? ?? '',
                'actionType': data['actionType'] ?? 'none',
                'actionUrl': data['actionUrl'] as String?,
                'actionRoute': data['actionRoute'] as String?,
              };
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '최신 뉴스',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                CarouselSlider(
                  options: CarouselOptions(
                    height: 300,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    viewportFraction: 0.85,
                    enableInfiniteScroll: items.length > 1,
                  ),
                  items: items.map((item) {
                    return GestureDetector(
                      onTap: () => _handleNewsTap(context, item),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (item['imageUrl'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                item['imageUrl']!,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress
                                          .expectedTotalBytes !=
                                          null
                                          ? loadingProgress
                                          .cumulativeBytesLoaded /
                                          loadingProgress
                                              .expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            )
                          else
                            Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 60),
                            ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black54, Colors.transparent],
                                ),
                                borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(16)),
                              ),
                              child: Text(
                                item['title']!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
          loading: () => _buildShimmerBanner(height: 300),
          error: (_, __) => const Text('뉴스 로드 오류'),
        );
      },
    );
  }

  /* ────────────────────────── 다음 경기 카드 ────────────────────────── */
  Widget _buildNextEventCard(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final asyncEvent = ref.watch(nextEventProvider);
        return asyncEvent.when(
          data: (snapshot) {
            if (snapshot.docs.isEmpty) {
              return _buildEmptyCard('예정된 경기 없음');
            }
            final data = snapshot.docs.first.data() as Map<String, dynamic>;
            final shop = data['shopName'] ?? '미정';
            final timestamp = data['date'] as Timestamp;
            final date = timestamp.toDate();
            final formatted =
                '${date.month}/${date.day}(${_getWeekday(date.weekday)}) ${date.hour}:00';
            return _buildEventCard(shop, formatted, context);
          },
          loading: () => _buildShimmerCard(),
          error: (_, __) => _buildErrorCard(),
        );
      },
    );
  }

  /* ────────────────────────── TOP3 랭킹 ────────────────────────── */
  Widget _buildTop3Ranking(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '현재 TOP 3',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RankingScreen())),
                  child: const Text('전체 보기'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, child) {
                final asyncTop3 = ref.watch(top3Provider);
                return asyncTop3.when(
                  data: (snapshot) {
                    if (snapshot.docs.isEmpty) {
                      return const Text('랭킹 데이터 없음');
                    }
                    return Column(
                      children: snapshot.docs.asMap().entries.map((e) {
                        final rank = e.key + 1;
                        final data =
                        e.value.data() as Map<String, dynamic>;
                        final name = data['korName'] ??
                            data['engName'] ??
                            'Unknown';
                        final points =
                            data['totalPoints']?.toString() ?? '0';
                        final delta = data['rankDelta']?.toString() ?? '–';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text('$rank.',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              Expanded(child: Text(name)),
                              Text('$points pt'),
                              const SizedBox(width: 8),
                              _buildDelta(delta),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('랭킹 로드 오류'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSponsorBanner() {
    return Consumer(
      builder: (context, ref, child) {
        final asyncSponsors = ref.watch(sponsorBannerProvider);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '스폰서',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            asyncSponsors.when(
              data: (snapshot) {
                final urls = snapshot.docs
                    .map((doc) => doc['imageUrl'] as String)
                    .where((url) => url.isNotEmpty)
                    .toList();

                if (urls.isEmpty) {
                  return const Text('스폰서 없음', style: TextStyle(color: Colors.grey));
                }

                return SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: CarouselSlider(
                    options: CarouselOptions(
                      autoPlay: true,
                      viewportFraction: 1.0,
                      enlargeCenterPage: false,
                      padEnds: false, // 끝 여백 제거
                      autoPlayInterval: const Duration(seconds: 4),
                    ),
                    items: urls.map((url) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox.expand(
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Center(child: Icon(Icons.broken_image, size: 40)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => _buildShimmerBanner(height: 150),
              error: (_, __) => const Text('오류'),
            ),
          ],
        );
      },
    );
  }

  /* ────────────────────────── 클릭 핸들러 ────────────────────────── */
  void _handleNoticeTap(BuildContext context, Map<String, dynamic> data) {
    final type = data['actionType'] as String?;
    if (type == 'link' && data['actionUrl'] != null) {
      launchUrl(Uri.parse(data['actionUrl'] as String),
          mode: LaunchMode.externalApplication);
    } else if (type == 'internal' && data['actionRoute'] != null) {
      Navigator.pushNamed(context, data['actionRoute'] as String);
    }
  }

  void _handleNewsTap(BuildContext context, Map<String, dynamic> item) {
    final type = item['actionType'] as String?;
    if (type == 'link' && item['actionUrl'] != null) {
      launchUrl(Uri.parse(item['actionUrl'] as String),
          mode: LaunchMode.externalApplication);
    } else if (type == 'internal' && item['actionRoute'] != null) {
      Navigator.pushNamed(context, item['actionRoute'] as String);
    }
  }

  /* ────────────────────────── 보조 메서드 ────────────────────────── */
  String _getWeekday(int weekday) =>
      ['일', '월', '화', '수', '목', '금', '토'][weekday - 1];

  Widget _buildEmptyCard(String msg) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(msg, style: const TextStyle(color: Colors.grey)),
    ),
  );

  Widget _buildEventCard(String shop, String date, BuildContext context) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('다음 경기 일정',
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text(shop),
                  const Spacer(),
                  Text(date),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CalendarScreen())),
                child: const Text('일정 보기'),
              ),
            ],
          ),
        ),
      );

  Widget _buildImageCarousel(List<String> urls) => CarouselSlider(
    options: CarouselOptions(
      height: 100,
      autoPlay: true,
      enlargeCenterPage: true,
      enableInfiniteScroll: urls.length > 1,
    ),
    items: urls.map((url) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image),
          ),
        ),
      );
    }).toList(),
  );

  Widget _buildDelta(String delta) {
    if (delta == '–') return const Text('–', style: TextStyle(color: Colors.grey));
    final isUp = delta.startsWith('+');
    return Text(
      delta,
      style: TextStyle(
          color: isUp ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold),
    );
  }

  Widget _buildErrorCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: const Text('오류', style: TextStyle(color: Colors.red)),
    ),
  );

  Widget _buildShimmerCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Container(height: 60, color: Colors.grey[200]),
    ),
  );

  Widget _buildShimmerBanner({double height = 150}) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // ← 여기로 이동 (클래스 내부 메서드)
  Widget _buildEmptyBanner(String msg) => Container(
    height: 50,
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Center(
      child: Text(msg, style: const TextStyle(color: Colors.grey)),
    ),
  );
}