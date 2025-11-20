// lib/presentation/screens/community/widgets/arena_preview.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/core/utils/arena_utils.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class ArenaPreview extends StatelessWidget {
  final VoidCallback onSeeAllPressed;

  const ArenaPreview({super.key, required this.onSeeAllPressed});

  void _goToArenaHome(BuildContext context) {
    if (ModalRoute.of(context)?.settings.name == RouteConstants.arenaHome) return;
    Navigator.pushNamed(context, RouteConstants.arenaHome);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4), // 전체 하단 여백
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(), // 외부 스크롤 따라감
        child: Column(
          children: [
            _buildOpenTournaments(context),
            const SizedBox(height: 12),
            _buildUpcomingTournaments(context),
            const SizedBox(height: 12),
            _buildArenaEntryButton(context), // 항상 보이는 버튼
            const SizedBox(height: 0), // 안전 여백
          ],
        ),
      ),
    );
  }

  // 지금 참가 가능한 대회
  Widget _buildOpenTournaments(BuildContext context) {
    final now = Timestamp.now();
    final threeDaysAgo = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3)));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .where('entryStartDate', isLessThanOrEqualTo: now)
          .where('entryEndDate', isGreaterThanOrEqualTo: now)
          .where('eventDate', isGreaterThanOrEqualTo: threeDaysAgo)
          .orderBy('entryEndDate')
          .limit(8)
          .snapshots(),
      builder: (context, snapshot) {
        final tournaments = snapshot.hasData
            ? snapshot.data!.docs
            .map((doc) => TournamentModel.fromJson(doc.data() as Map<String, dynamic>).copyWith(id: doc.id))
            .toList()
            : <TournamentModel>[];

        return _buildSection(
          context: context,
          title: "지금 참가 가능한 대회",
          tournaments: tournaments,
          showSeeAll: true,
          showDday: true,
          onCardTap: () => _goToArenaHome(context),
        );
      },
    );
  }

  // 예정된 대회
  Widget _buildUpcomingTournaments(BuildContext context) {
    final now = Timestamp.now();
    final threeDaysAgo = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3)));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .where('entryStartDate', isGreaterThan: now)
          .where('eventDate', isGreaterThanOrEqualTo: threeDaysAgo)
          .orderBy('entryStartDate')
          .limit(8)
          .snapshots(),
      builder: (context, snapshot) {
        final tournaments = snapshot.hasData
            ? snapshot.data!.docs
            .map((doc) => TournamentModel.fromJson(doc.data() as Map<String, dynamic>).copyWith(id: doc.id))
            .toList()
            : <TournamentModel>[];

        return _buildSection(
          context: context,
          title: "예정된 대회",
          tournaments: tournaments,
          showSeeAll: false,
          showDday: true,
          onCardTap: () => _goToArenaHome(context),
        );
      },
    );
  }

  // 공통 섹션
  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<TournamentModel> tournaments,
    required bool showSeeAll,
    required bool showDday,
    required VoidCallback onCardTap,
  }) {
    final hasData = tournaments.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (showSeeAll && hasData)
                TextButton(onPressed: onSeeAllPressed, child: const Text('전체 보기')),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: hasData
              ? ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: tournaments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              return GestureDetector(
                onTap: onCardTap,
                child: _buildCard(tournaments[i], showDday: showDday),
              );
            },
          )
              : Center(
            child: Text(
              '아직 $title가 없어요',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // 항상 보이는 "아레나 바로가기" 버튼
  Widget _buildArenaEntryButton(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () => _goToArenaHome(context),
        icon: const Icon(Icons.emoji_events_outlined, size: 16),
        label: const Text(
          '아레나 바로가기',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
          side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  Widget _buildCard(TournamentModel t, {required bool showDday}) {
    final dday = showDday
        ? (t.entryStartDate.toDate().isAfter(DateTime.now())
        ? ArenaUtils.entryDday(t.entryStartDate)
        : ArenaUtils.entryDday(t.entryEndDate))
        : '';

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: t.posterUrl != null && t.posterUrl!.isNotEmpty
                ? Image.network(
              t.posterUrl!,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
                : _placeholder(),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dday.isNotEmpty) ...[
                    Text(
                      dday,
                      style: const TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                  ],
                  const Icon(Icons.people, size: 11, color: Colors.white),
                  const SizedBox(width: 3),
                  Text(
                    '${t.entryCount}/${t.maxParticipants}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[300],
      child: const Icon(Icons.emoji_events, size: 36, color: Colors.white70),
    );
  }
}