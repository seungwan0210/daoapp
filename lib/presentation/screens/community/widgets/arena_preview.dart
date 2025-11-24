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
          ],
        ),
      ),
    );
  }

  // 지금 참가 가능한 대회 (엔트리 진행 중)
  Widget _buildOpenTournaments(BuildContext context) {
    final now = nowKst();
    final nowTs = Timestamp.fromDate(now);
    final threeDaysAgoTs =
    Timestamp.fromDate(now.subtract(const Duration(days: 3)));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .where('entryStartDate', isLessThanOrEqualTo: nowTs)
          .where('entryEndDate', isGreaterThanOrEqualTo: nowTs)
          .where('eventDate', isGreaterThanOrEqualTo: threeDaysAgoTs)
          .orderBy('entryEndDate')
          .limit(8)
          .snapshots(),
      builder: (context, snapshot) {
        final tournaments = snapshot.hasData
            ? snapshot.data!.docs
            .map(
              (doc) => TournamentModel.fromJson(
            doc.data() as Map<String, dynamic>,
          ).copyWith(id: doc.id),
        )
            .toList()
            : <TournamentModel>[];

        return _buildSection(
          context: context,
          title: "지금 참가 가능한 대회",
          tournaments: tournaments,
          showSeeAll: true, // ✅ 여기서 '전체 보기' 항상 노출
          showDday: true,
          onCardTap: () => _goToArenaHome(context),
        );
      },
    );
  }

  // 예정된 대회 (엔트리 시작 전)
  Widget _buildUpcomingTournaments(BuildContext context) {
    final now = nowKst();
    final nowTs = Timestamp.fromDate(now);
    final threeDaysAgoTs =
    Timestamp.fromDate(now.subtract(const Duration(days: 3)));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .where('entryStartDate', isGreaterThan: nowTs)
          .where('eventDate', isGreaterThanOrEqualTo: threeDaysAgoTs)
          .orderBy('entryStartDate')
          .limit(8)
          .snapshots(),
      builder: (context, snapshot) {
        final tournaments = snapshot.hasData
            ? snapshot.data!.docs
            .map(
              (doc) => TournamentModel.fromJson(
            doc.data() as Map<String, dynamic>,
          ).copyWith(id: doc.id),
        )
            .toList()
            : <TournamentModel>[];

        return _buildSection(
          context: context,
          title: "예정된 대회",
          tournaments: tournaments,
          showSeeAll: false, // 여기엔 전체보기 X
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
        // 제목 + 전체 보기
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (showSeeAll)
                TextButton(
                  // ✅ 커뮤니티 프리뷰처럼 콜백으로 처리
                  onPressed: onSeeAllPressed,
                  child: const Text('전체 보기'),
                ),
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

  /// ✅ 여기서 D-Day 로직 정리:
  /// - 엔트리 시작 전  → entryStartDate 기준 D-표시
  /// - 엔트리 진행 중 → entryEndDate 기준 D-표시
  Widget _buildCard(TournamentModel t, {required bool showDday}) {
    String dday = '';

    if (showDday) {
      final now = nowKst();
      final entryStart = t.entryStartDate.toDate();

      final bool isBeforeStart = entryStart.isAfter(now);

      dday = isBeforeStart
          ? ArenaUtils.entryDday(t.entryStartDate) // 엔트리 예정: 시작일 기준
          : ArenaUtils.entryDday(t.entryEndDate); // 엔트리 중: 마감일 기준
    }

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
              // ✅ FittedBox로 Row 전체를 살짝 줄여서 오버플로우 방지
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dday.isNotEmpty) ...[
                      Text(
                        dday,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    const Icon(
                      Icons.people,
                      size: 11,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${t.entryCount}/${t.maxParticipants}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
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
      child: const Icon(
        Icons.emoji_events,
        size: 36,
        color: Colors.white70,
      ),
    );
  }
}
