import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class SelectionPlayersScreen extends ConsumerWidget {
  const SelectionPlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스

    return Scaffold(
      appBar: CommonAppBar(
        title: s.selection_title,
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
                  '${s.my_tournaments_error}\n${snapshot.error}', // 공통 에러 메시지 활용 가능
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            final players =
            docs.map((d) => _SelectionPlayer.fromDoc(d)).toList();

            final seasons = ['season1', 'season2', 'season3', 'total'];

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, s),
                  const SizedBox(height: 20),
                  ...seasons.map((season) {
                    final male = players.firstWhere(
                          (p) => p.season == season && p.gender == 'male',
                      orElse: () =>
                          _SelectionPlayer.empty(season: season, gender: 'male'),
                    );
                    final female = players.firstWhere(
                          (p) => p.season == season && p.gender == 'female',
                      orElse: () => _SelectionPlayer.empty(
                          season: season, gender: 'female'),
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

  Widget _buildHeader(ThemeData theme, AppLocalizations s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.08),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.20),
          width: 1,
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
                  s.selection_header_title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.selection_header_desc,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context)!;

    String seasonLabel;
    String seasonSubLabel;

    switch (season) {
      case 'season1':
        seasonLabel = s.selection_label_season1;
        seasonSubLabel = 'Steel League Season 1';
        break;
      case 'season2':
        seasonLabel = s.selection_label_season2;
        seasonSubLabel = 'Steel League Season 2';
        break;
      case 'season3':
        seasonLabel = s.selection_label_season3;
        seasonSubLabel = 'Steel League Season 3';
        break;
      case 'total':
        seasonLabel = s.selection_label_total;
        seasonSubLabel = s.selection_sub_total;
        break;
      default:
        seasonLabel = season;
        seasonSubLabel = '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                seasonLabel,
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
                  seasonSubLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: hasAny
                ? Column(
              children: [
                _PlayerBlock(
                  title: s.selection_label_male,
                  label: s.ranking_filter_gender_male, // 공통 키 활용
                  color: Colors.blue,
                  player: male,
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                _PlayerBlock(
                  title: s.selection_label_female,
                  label: s.ranking_filter_gender_female, // 공통 키 활용
                  color: Colors.pink,
                  player: female,
                ),
              ],
            )
                : SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  s.selection_status_empty,
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

class _PlayerBlock extends StatelessWidget {
  final String title;
  final String label;
  final Color color;
  final _SelectionPlayer? player;

  const _PlayerBlock({
    required this.title,
    required this.label,
    required this.color,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context)!;

    final header = Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        _GenderChip(label: label, color: color),
      ],
    );

    if (player == null || !player!.isFilled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 8),
          Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.grey[50],
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                s.selection_status_upcoming,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final p = player!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 8),
        Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            border: Border.all(
              color: color.withOpacity(0.45),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _PlayerAvatar(photoUrl: p.photoUrl, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.koreanName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (p.englishName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          p.englishName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                      if (p.shopName.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store_mall_directory_outlined,
                              size: 16,
                              color: color.withOpacity(0.9),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                s.selection_shop_prefix(p.shopName),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }
}

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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            (label == '남자' || label == 'Male' || label == '男性') ? Icons.male : Icons.female,
            size: 14,
            color: color.withOpacity(0.9),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

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
        backgroundColor: color.withOpacity(0.12),
        child: Icon(
          Icons.person,
          size: 28,
          color: color.withOpacity(0.9),
        ),
      );
    }

    return CircleAvatar(
      radius: 26,
      backgroundColor: color.withOpacity(0.06),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Icon(
            Icons.person,
            size: 28,
            color: color.withOpacity(0.9),
          ),
        ),
      ),
    );
  }
}

class _SelectionPlayer {
  final String id;
  final String koreanName;
  final String englishName;
  final String gender;
  final String season;
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

  factory _SelectionPlayer.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
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