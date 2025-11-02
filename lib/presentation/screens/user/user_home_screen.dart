// lib/presentation/screens/user/user_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:daoapp/presentation/screens/user/ranking_screen.dart';
import 'package:daoapp/presentation/screens/user/calendar_screen.dart';
import 'package:daoapp/presentation/providers/user_home_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/providers/ranking_provider.dart';
import 'package:daoapp/presentation/widgets/app_card.dart'; // 추가!
import 'package:daoapp/core/constants/route_constants.dart'; // 추가!

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  late final RankingProvider _rankingProvider;

  @override
  void initState() {
    super.initState();
    _rankingProvider = sl<RankingProvider>();
    _rankingProvider.addListener(_updateUI);
    _rankingProvider.updateFilters('2026', 'total', 'male');
  }

  void _updateUI() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _rankingProvider.removeListener(_updateUI);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HOME'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 공지사항
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('공지사항', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: _buildNoticeSlider(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 다음 경기
            AppCard(
              child: _buildNextEventCard(),
            ),
            const SizedBox(height: 16),

            // TOP 3 랭킹
            AppCard(
              child: _buildTop3Ranking(),
            ),
            const SizedBox(height: 16),

            // 뉴스
            AppCard(
              child: _buildNewsSection(),
            ),
            const SizedBox(height: 16),

            // 스폰서
            AppCard(
              child: _buildSponsorSection(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 공지 슬라이더
  Widget _buildNoticeSlider() {
    return Consumer(builder: (context, ref, child) {
      final notices = ref.watch(noticeBannerProvider);
      return notices.when(
        data: (snapshot) {
          if (snapshot.docs.isEmpty) return _buildEmptyBanner('공지 없음');
          return CarouselSlider(
            options: CarouselOptions(
              height: 50,
              autoPlay: true,
              viewportFraction: 1.0,
              autoPlayInterval: const Duration(seconds: 4),
            ),
            items: snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] as String? ?? '';
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleNoticeTap(context, data),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
        loading: () => _buildShimmerBanner(),
        error: (_, __) => const Text('오류'),
      );
    });
  }

  // 다음 경기
  Widget _buildNextEventCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('date', isGreaterThan: Timestamp.now())
          .orderBy('date')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyCard('예정된 경기 없음');
        }
        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final date = (data['date'] as Timestamp).toDate();
        final formatted = '${date.month}/${date.day}(${_getWeekday(date.weekday)}) ${data['time']}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('다음 경기 일정', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 4),
                Text(data['shopName'], style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                Text(formatted, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.calendar),
                icon: const Icon(Icons.calendar_today),
                label: const Text('일정 보기'),
              ),
            ),
          ],
        );
      },
    );
  }

  // TOP 3 랭킹
  Widget _buildTop3Ranking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('현재 TOP 3 (통합)', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.ranking),
              child: const Text('전체 보기'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_rankingProvider.loading)
          const Center(child: CircularProgressIndicator())
        else if (_rankingProvider.rankings.isEmpty)
          const Text('랭킹 데이터 없음')
        else
          Column(
            children: _rankingProvider.rankings.take(3).toList().asMap().entries.map((e) {
              final rank = e.key + 1;
              final user = e.value;
              final genderText = user.gender == 'male' ? '남자' : '여자';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getRankColor(rank),
                      radius: 14,
                      child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${user.koreanName} (${user.englishName})')),
                    Text('${user.displayPoints} pt', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text(genderText, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // 뉴스
  Widget _buildNewsSection() {
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
              Text('최신 뉴스', style: Theme.of(context).textTheme.titleLarge),
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
                        if (item['imageUrl'] != null && item['imageUrl']!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              item['imageUrl']!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 60),
                              ),
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

  // 스폰서
  Widget _buildSponsorSection() {
    return Consumer(builder: (context, ref, child) {
      final sponsors = ref.watch(sponsorBannerProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('스폰서', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          sponsors.when(
            data: (snapshot) {
              final urls = <String>[];
              for (final doc in snapshot.docs) {
                final url = doc.get('imageUrl') as String?;
                if (url != null && url.isNotEmpty) urls.add(url);
              }
              return urls.isEmpty
                  ? const Text('스폰서 없음', style: TextStyle(color: Colors.grey))
                  : _buildImageCarousel(urls);
            },
            loading: () => _buildShimmerBanner(height: 180),
            error: (_, __) => const Text('오류', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    });
  }

  // 공통 메서드
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

  String _getWeekday(int weekday) => ['일', '월', '화', '수', '목', '금', '토'][weekday - 1];

  Widget _buildEmptyCard(String msg) {
    return AppCard(
      child: Text(msg, style: const TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildImageCarousel(List<String> urls) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 180,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        viewportFraction: 0.92,
        enlargeCenterPage: false,
      ),
      items: urls.map((url) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildShimmerBanner({double height = 50}) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildEmptyBanner(String msg) {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(msg, style: const TextStyle(color: Colors.grey))),
    );
  }

  Color _getRankColor(int rank) {
    return switch (rank) {
      1 => Colors.amber,
      2 => Colors.grey,
      3 => Colors.brown,
      _ => Theme.of(context).colorScheme.primary,
    };
  }
}