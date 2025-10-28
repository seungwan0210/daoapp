// lib/presentation/screens/user/user_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:daoapp/presentation/screens/user/ranking_screen.dart';
import 'package:daoapp/presentation/screens/user/calendar_screen.dart';
import 'package:daoapp/presentation/providers/user_home_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스틸리그 포인트'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
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

  Widget _buildNoticeSection() {
    return Consumer(builder: (context, ref, child) {
      final notices = ref.watch(noticeBannerProvider);
      return notices.when(
        data: (snapshot) {
          if (snapshot.docs.isEmpty) return _buildEmptyBanner('공지 없음');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('공지사항', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 50,
                    autoPlay: true,
                    viewportFraction: 1.0,
                    autoPlayInterval: const Duration(seconds: 4),
                  ),
                  items: snapshot.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] as String? ?? '';

                    return Material( // Material 추가!
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleNoticeTap(context, data),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        error: (_, __) => const Text('오류'),
      );
    });
  }

  // 뉴스 포스터 슬라이드 + 클릭 이동
  Widget _buildNewsPosterSlider() {
    return Consumer(builder: (context, ref, child) {
      final news = ref.watch(newsProvider);
      return news.when(
        data: (snapshot) {
          if (snapshot.docs.isEmpty) return const Text('뉴스 없음', style: TextStyle(color: Colors.grey));
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
              const Text('최신 뉴스', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              CarouselSlider(
                options: CarouselOptions(
                  height: 300,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.85,
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
                              errorBuilder: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                            ),
                          )
                        else
                          Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 60)),
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
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                            ),
                            child: Text(
                              item['title']!,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
        error: (_, __) => const Text('오류'),
      );
    });
  }

  // 다음 경기
  Widget _buildNextEventCard(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final event = ref.watch(nextEventProvider);
      return event.when(
        data: (snapshot) {
          if (snapshot.docs.isEmpty) return _buildEmptyCard('예정된 경기 없음');
          final data = snapshot.docs.first.data() as Map<String, dynamic>;
          final shop = data['shopName'] ?? '미정';
          final timestamp = data['date'] as Timestamp;
          final date = timestamp.toDate();
          final formatted = '${date.month}/${date.day}(${_getWeekday(date.weekday)}) ${date.hour}:00';
          return _buildEventCard(shop, formatted, context);
        },
        loading: () => _buildShimmerCard(),
        error: (_, __) => _buildErrorCard(),
      );
    });
  }

  // TOP3 랭킹
  Widget _buildTop3Ranking(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final top3 = ref.watch(top3Provider);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('현재 TOP 3', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RankingScreen())),
                    child: const Text('전체 보기'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              top3.when(
                data: (snapshot) {
                  if (snapshot.docs.isEmpty) return const Text('랭킹 데이터 없음');
                  return Column(
                    children: snapshot.docs.asMap().entries.map((e) {
                      final rank = e.key + 1;
                      final data = e.value.data() as Map<String, dynamic>;
                      final name = data['korName'] ?? data['engName'] ?? 'Unknown';
                      final points = data['totalPoints']?.toString() ?? '0';
                      final delta = data['rankDelta']?.toString() ?? '–';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text('$rank.', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                error: (_, __) => const Text('오류'),
              ),
            ],
          ),
        ),
      );
    });
  }

  // 스폰서 배너
  Widget _buildSponsorBanner() {
    return Consumer(builder: (context, ref, child) {
      final sponsors = ref.watch(sponsorBannerProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('스폰서', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          sponsors.when(
            data: (snapshot) {
              final urls = snapshot.docs
                  .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['imageUrl'] as String? ?? '';
              })
                  .where((url) => url.isNotEmpty)
                  .toList();

              if (urls.isEmpty) return const Text('스폰서 없음');
              return _buildImageCarousel(urls);
            },
            loading: () => _buildShimmerBanner(),
            error: (_, __) => const Text('오류'),
          ),
        ],
      );
    });
  }

  // 클릭 핸들러
  void _handleNoticeTap(BuildContext context, Map<String, dynamic> data) {
    final type = data['actionType'];
    if (type == 'link' && data['actionUrl'] != null) {
      launchUrl(Uri.parse(data['actionUrl']), mode: LaunchMode.externalApplication);
    } else if (type == 'internal' && data['actionRoute'] != null) {
      Navigator.pushNamed(context, data['actionRoute']);
    }
  }

  void _handleNewsTap(BuildContext context, Map<String, dynamic> item) {
    final type = item['actionType'];
    if (type == 'link' && item['actionUrl'] != null) {
      launchUrl(Uri.parse(item['actionUrl']), mode: LaunchMode.externalApplication);
    } else if (type == 'internal' && item['actionRoute'] != null) {
      Navigator.pushNamed(context, item['actionRoute']);
    }
  }

  // 보조 메서드들
  String _getWeekday(int weekday) => ['일', '월', '화', '수', '목', '금', '토'][weekday - 1];

  Widget _buildEmptyCard(String msg) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(msg, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildEventCard(String shop, String date, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('다음 경기 일정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
              child: const Text('일정 보기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> urls) {
    return CarouselSlider(
      options: CarouselOptions(height: 100, autoPlay: true, enlargeCenterPage: true),
      items: urls.map((url) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
        ),
      )).toList(),
    );
  }

  Widget _buildDelta(String delta) {
    if (delta == '–') return const Text('–', style: TextStyle(color: Colors.grey));
    final isUp = delta.startsWith('+');
    return Text(
      delta,
      style: TextStyle(color: isUp ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: const Text('오류', style: TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(height: 60, color: Colors.grey[200]),
      ),
    );
  }

  Widget _buildShimmerBanner({double height = 50}) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
    );
  }
}
Widget _buildEmptyBanner(String msg) {
  return Container(
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