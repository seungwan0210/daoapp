// lib/presentation/screens/arena/steel_league/selection_players_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/presentation/widgets/common_appbar.dart';

/// ===============================
/// Firestore 예상 구조 (admin용 가이드)
/// ===============================
/// 컬렉션: steel_league_selection
/// 문서 예시 필드:
/// - koreanName   : String   (필수)  ex) '최민석'
/// - englishName  : String   (선택)  ex) 'CHOI Minsuk'
/// - gender       : String   ('male' / 'female')
/// - season       : String   ('season1' / 'season2' / 'season3' / 'total')
/// - shopName     : String   (선택)  ex) 'PDK Stadium'
/// - photoUrl     : String   (선택)  ex) 'https://...'
/// - bio          : String   (선택)  간단 소개 문구
/// - order        : int      (선택)  정렬용, 기본 0
///
/// 총 8명:
///   season1 male/female
///   season2 male/female
///   season3 male/female
///   total   male/female
///

class SelectionPlayersScreen extends ConsumerWidget {
  const SelectionPlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CommonAppBar(
        title: '선발 선수',
        showBackButton: true,
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('steel_league_selection')
              .orderBy('season')
              .orderBy('order', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '선발 선수 정보를 불러오는 중 오류가 발생했습니다.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            final players = docs.map((d) => _SelectionPlayer.fromDoc(d)).toList();

            // 시즌별 + 성별로 나누기
            final seasons = ['season1', 'season2', 'season3', 'total'];

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 안내 텍스트
                  _buildHeader(theme),
                  const SizedBox(height: 20),
                  ...seasons.map((season) {
                    final male = players.firstWhere(
                          (p) => p.season == season && p.gender == 'male',
                      orElse: () => _SelectionPlayer.empty(season: season, gender: 'male'),
                    );
                    final female = players.firstWhere(
                          (p) => p.season == season && p.gender == 'female',
                      orElse: () => _SelectionPlayer.empty(season: season, gender: 'female'),
                    );

                    final hasMale = male.isFilled;
                    final hasFemale = female.isFilled;
                    final hasAny = hasMale || hasFemale;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _SeasonSection(
                        season: season,
                        male: hasMale ? male : null,
                        female: hasFemale ? female : null,
                        hasAny: hasAny,
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.12),
            theme.colorScheme.secondary.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 34,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KDF 스틸리그 선발 선수',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '시즌 1–3, 통합 포인트를 기준으로\n'
                      '남녀 각 1명씩 총 8명의 선수가 선발됩니다.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 시즌 섹션 위젯
class _SeasonSection extends StatelessWidget {
  final String season;
  final _SelectionPlayer? male;
  final _SelectionPlayer? female;
  final bool hasAny;

  const _SeasonSection({
    required this.season,
    required this.male,
    required this.female,
    required this.hasAny,
  });

  String get _seasonLabel {
    switch (season) {
      case 'season1':
        return '시즌 1 대표';
      case 'season2':
        return '시즌 2 대표';
      case 'season3':
        return '시즌 3 대표';
      case 'total':
        return '통합 대표';
      default:
        return season;
    }
  }

  String get _seasonSubLabel {
    switch (season) {
      case 'season1':
        return 'Steel League Season 1';
      case 'season2':
        return 'Steel League Season 2';
      case 'season3':
        return 'Steel League Season 3';
      case 'total':
        return '전체 시즌 통합';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 타이틀
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                _seasonLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _seasonSubLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 남/여 카드 2개를 한 줄에
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: hasAny
                ? Row(
              children: [
                Expanded(
                  child: _PlayerCard(
                    label: '남자',
                    color: Colors.blue,
                    player: male,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PlayerCard(
                    label: '여자',
                    color: Colors.pink,
                    player: female,
                  ),
                ),
              ],
            )
                : SizedBox(
              height: 72,
              child: Center(
                child: Text(
                  '아직 선발된 선수가 없습니다.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 실제 선수 카드 (한 명)
class _PlayerCard extends StatelessWidget {
  final String label; // '남자' / '여자'
  final Color color;
  final _SelectionPlayer? player;

  const _PlayerCard({
    required this.label,
    required this.color,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (player == null || !player!.isFilled) {
      // 빈 자리 (미정)
      return Container(
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey[50],
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GenderChip(label: label, color: color),
            const SizedBox(height: 8),
            const Text(
              '선발 예정',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final p = player!;

    return Container(
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.10),
            color.withOpacity(0.03),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.40),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          // 프로필 사진
          _PlayerAvatar(photoUrl: p.photoUrl, color: color),
          const SizedBox(width: 10),
          // 이름 / 샵 / 한줄소개
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단: 이름 + 성별
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.koreanName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _GenderChip(label: label, color: color),
                    ],
                  ),
                  if (p.englishName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      p.englishName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  // 샵명
                  if (p.shopName.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            p.shopName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const Spacer(),
                  // 한 줄 소개
                  if (p.bio.isNotEmpty)
                    Text(
                      p.bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: Colors.grey[800],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// 성별 칩
class _GenderChip extends StatelessWidget {
  final String label;
  final Color color;

  const _GenderChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == '남자' ? Icons.male : Icons.female,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// 프로필 아바타
class _PlayerAvatar extends StatelessWidget {
  final String photoUrl;
  final Color color;

  const _PlayerAvatar({
    required this.photoUrl,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: color.withOpacity(0.15),
        child: Icon(
          Icons.person,
          size: 28,
          color: color,
        ),
      );
    }

    return CircleAvatar(
      radius: 26,
      backgroundColor: color.withOpacity(0.10),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Icon(
            Icons.person,
            size: 28,
            color: color,
          ),
        ),
      ),
    );
  }
}

// 내부용 모델
class _SelectionPlayer {
  final String id;
  final String koreanName;
  final String englishName;
  final String gender; // 'male' / 'female'
  final String season; // 'season1' / 'season2' / 'season3' / 'total'
  final String shopName;
  final String photoUrl;
  final String bio;
  final int order;

  const _SelectionPlayer({
    required this.id,
    required this.koreanName,
    required this.englishName,
    required this.gender,
    required this.season,
    required this.shopName,
    required this.photoUrl,
    required this.bio,
    required this.order,
  });

  bool get isFilled => koreanName.isNotEmpty;

  factory _SelectionPlayer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return _SelectionPlayer(
      id: doc.id,
      koreanName: (data['koreanName'] ?? '') as String,
      englishName: (data['englishName'] ?? '') as String,
      gender: (data['gender'] ?? '') as String,
      season: (data['season'] ?? '') as String,
      shopName: (data['shopName'] ?? '') as String,
      photoUrl: (data['photoUrl'] ?? '') as String,
      bio: (data['bio'] ?? '') as String,
      order: (data['order'] ?? 0) as int,
    );
  }

  factory _SelectionPlayer.empty({
    required String season,
    required String gender,
  }) {
    return _SelectionPlayer(
      id: '',
      koreanName: '',
      englishName: '',
      gender: gender,
      season: season,
      shopName: '',
      photoUrl: '',
      bio: '',
      order: 0,
    );
  }
}
