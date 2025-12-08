// lib/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/presentation/providers/home_provider.dart';
import 'package:daoapp/presentation/providers/ranking_provider.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/data/models/ranking_user.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';
import 'package:daoapp/core/constants/route_constants.dart';

// 아레나 스틸리그 상세 화면들
import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_ranking_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_schedule_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 홈 진입 시 기본 랭킹 필터 세팅
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rankingProvider.notifier).updateFilters('2026', 'total', 'all');
    });

    return const HomeScreenBody();
  }
}

class HomeScreenBody extends ConsumerWidget {
  const HomeScreenBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingState = ref.watch(rankingProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === 최신 뉴스 ===
          AppCard(child: _buildNewsSection(context, ref)),
          const SizedBox(height: 4),

          // === 다음 경기 ===
          AppCard(child: _buildNextEventCard(context)),
          const SizedBox(height: 4),

          // === 스틸리그 포인트 TOP3 ===
          AppCard(child: _buildTop3Ranking(rankingState, context)),
          const SizedBox(height: 4),

          // === 대회 사진 섹션 ===
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('대회 사진', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                SizedBox(height: 220, child: _buildCompetitionPhotos(context)),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // === 스폰서 ===
          AppCard(child: _buildSponsorSection(context, ref)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =========================
  // 대회 사진 캐러셀
  // =========================
  static Widget _buildCompetitionPhotos(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('competition_photos')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyBanner(context, '대회 사진 없음');
        }

        final items = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'imageUrl': data['imageUrl'] as String?,
            'title': data['title'] as String? ?? '',
            'actionType': data['actionType'] ?? 'none',
            'actionUrl': data['actionUrl'] as String?,
            'actionRoute': data['actionRoute'] as String?,
          };
        }).toList();

        return CarouselSlider(
          options: CarouselOptions(
            height: 200,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.85,
          ),
          items: items.map((item) {
            return GestureDetector(
              onTap: () => _handleCompetitionPhotoTap(context, item),
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
                        borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      child: Text(
                        item['title']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // 대회 사진 클릭 처리
  static void _handleCompetitionPhotoTap(
      BuildContext context, Map<String, dynamic> item) {
    final type = item['actionType'];
    final url = item['actionUrl'] as String?;
    final route = item['actionRoute'] as String?;

    if (type == 'link' && url != null) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else if (type == 'internal' && route != null) {
      _navigateToTab(context, route);
    }
  }

  // =========================
  // 다음 경기 카드
  // =========================
  static Widget _buildNextEventCard(BuildContext context) {
    final now =
    Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 5)));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('eventDateTime', isGreaterThan: now)
          .orderBy('eventDateTime')
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerBanner(height: 120);
        }

        if (snapshot.hasError) {
          return _buildEmptyCard(context, '오류: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyCard(context, '예정된 경기 없음');
        }

        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('다음 경기 일정',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  // 🔹 전체 보기 → 아레나 탭 + 스틸리그 리그 일정 화면
                  onPressed: () => _navigateToTab(
                    context,
                    RouteConstants.steelLeagueSchedule,
                  ),
                  child: const Text('전체 보기'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['eventDateTime'] as Timestamp;
              final date = timestamp.toDate();

              // 날짜만 추출해서 요일 계산
              final normalizedDate = DateTime(date.year, date.month, date.day);

              final timeStr = data['time'] as String? ??
                  '${date.hour.toString().padLeft(2, '0')}:'
                      '${date.minute.toString().padLeft(2, '0')}';

              final formatted =
                  '${normalizedDate.month}/${normalizedDate.day}(${_getWeekday(normalizedDate.weekday)}) $timeStr';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.location_on,
                        color: Theme.of(context).colorScheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data['shopName'] ?? '장소 없음',
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formatted,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  // =========================
  // 스틸리그 포인트 TOP 3 랭킹
  // =========================
  static Widget _buildTop3Ranking(
      AsyncValue<List<RankingUser>> rankingState, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 🔹 제목 변경
            Text('스틸리그 포인트',
                style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            TextButton(
              // 🔹 전체 보기 → 아레나 탭 + 스틸리그 랭킹 화면
              onPressed: () => _navigateToTab(
                context,
                RouteConstants.steelLeagueRanking,
              ),
              child: const Text('전체 보기'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        rankingState.when(
          data: (rankings) {
            if (rankings.isEmpty) {
              return const Text('랭킹 데이터 없음');
            }
            return Column(
              children: rankings.take(3).toList().asMap().entries.map((e) {
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
                        child: Text(
                          '$rank',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                            '${user.koreanName} (${user.englishName})'),
                      ),
                      Text(
                        '${user.displayPoints} pt',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        genderText,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, __) => const Text('랭킹 로드 오류'),
        ),
      ],
    );
  }

  // =========================
  // 최신 뉴스
  // =========================
  static Widget _buildNewsSection(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsProvider);
    return news.when(
      data: (snapshot) {
        if (snapshot.docs.isEmpty) {
          return const Text('뉴스 없음', style: TextStyle(color: Colors.grey));
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
            Text('최신 뉴스', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            CarouselSlider(
              options: CarouselOptions(
                height: 220,
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
                      if (item['imageUrl'] != null &&
                          item['imageUrl']!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            item['imageUrl']!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child:
                              const Icon(Icons.broken_image, size: 60),
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
                              bottom: Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            item['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
  }

  // =========================
  // 스폰서 섹션
  // =========================
  static Widget _buildSponsorSection(BuildContext context, WidgetRef ref) {
    final sponsors = ref.watch(sponsorBannerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('스폰서', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        sponsors.when(
          data: (snapshot) {
            final items = <Map<String, dynamic>>[];
            for (final doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final url = data['imageUrl'] as String?;
              if (url != null && url.isNotEmpty) {
                items.add({
                  'imageUrl': url,
                  'actionType': data['actionType'] ?? 'none',
                  'actionUrl': data['actionUrl'] as String?,
                  'actionRoute': data['actionRoute'] as String?,
                });
              }
            }
            return items.isEmpty
                ? const Text('스폰서 없음',
                style: TextStyle(color: Colors.grey))
                : _buildSponsorCarousel(context, items);
          },
          loading: () => _buildShimmerBanner(height: 180),
          error: (_, __) =>
          const Text('오류', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  static Widget _buildSponsorCarousel(
      BuildContext context, List<Map<String, dynamic>> items) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 180,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        viewportFraction: 0.92,
        enlargeCenterPage: false,
      ),
      items: items.map((item) {
        return GestureDetector(
          onTap: () => _handleSponsorTap(context, item),
          child: Container(
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
                item['imageUrl'],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // =========================
  // 뉴스/스폰서 클릭 공통
  // =========================
  static void _handleNewsTap(
      BuildContext context, Map<String, dynamic> item) {
    final type = item['actionType'];
    final url = item['actionUrl'] as String?;
    final route = item['actionRoute'] as String?;

    if (type == 'link' && url != null) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else if (type == 'internal' && route != null) {
      _navigateToTab(context, route);
    }
  }

  static void _handleSponsorTap(
      BuildContext context, Map<String, dynamic> item) {
    final type = item['actionType'];
    final url = item['actionUrl'] as String?;
    final route = item['actionRoute'] as String?;

    if (type == 'link' && url != null) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else if (type == 'internal' && route != null) {
      _navigateToTab(context, route);
    }
  }

  // =========================
  // 탭 전환 + 아레나 상세 화면 진입
  // =========================
  static void _navigateToTab(BuildContext context, String route) {
    // 1) 문자열이 RouteConstants 값인 경우도 지원
    switch (route) {
    // 홈
      case RouteConstants.home:
      case '/home':
        MainScreen.changeTab(context, 0);
        break;

    // 트레이닝
      case RouteConstants.trainingHome:
      case '/training':
      case '/checkout':
        MainScreen.changeTab(context, 1);
        break;

    // 아레나 홈
      case RouteConstants.arenaHome:
      case '/arena':
      case '/arena/home':
      case '/ranking': // 과거 값 호환
      case '/calendar':
      case '/point-calendar':
        MainScreen.changeTab(context, 2);
        break;

    // 🔹 스틸리그 리그 일정
      case RouteConstants.steelLeagueSchedule:
      case '/arena/steel/schedule':
        MainScreen.changeTab(context, 2);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SteelLeagueScheduleScreen(),
          ),
        );
        break;

    // 🔹 스틸리그 랭킹
      case RouteConstants.steelLeagueRanking:
      case '/arena/steel/ranking':
        MainScreen.changeTab(context, 2);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SteelLeagueRankingScreen(),
          ),
        );
        break;

    // 커뮤니티
      case RouteConstants.community:
      case '/community':
        MainScreen.changeTab(context, 3);
        break;

    // 마이페이지
      case RouteConstants.myPage:
      case '/my-page':
        MainScreen.changeTab(context, 4);
        break;

      default:
      // 알 수 없는 route는 일단 무시
        break;
    }
  }

  // =========================
  // 기타 UI 헬퍼
  // =========================
  static String _getWeekday(int weekday) =>
      ['월', '화', '수', '목', '금', '토', '일'][weekday - 1];

  static Widget _buildEmptyCard(BuildContext context, String msg) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(msg, style: const TextStyle(color: Colors.grey)),
    );
  }

  static Widget _buildShimmerBanner({double height = 50}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  static Widget _buildEmptyBanner(BuildContext context, String msg) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(msg, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }

  static Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return const Color(0xFF1565C0);
    }
  }
}
