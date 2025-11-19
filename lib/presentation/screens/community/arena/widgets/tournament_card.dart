// lib/presentation/screens/community/arena/widgets/tournament_card.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/core/utils/arena_utils.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class TournamentCard extends StatelessWidget {
  final TournamentModel tournament;

  const TournamentCard({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final status = ArenaUtils.getEntryStatus(
      eventDate: tournament.eventDate,
      entryStartDate: tournament.entryStartDate,
      entryEndDate: tournament.entryEndDate,
    );

    final currentUser = FirebaseAuth.instance.currentUser;
    final isOrganizer = currentUser != null &&
        (tournament.createdByUid == currentUser.uid ||
            (currentUser.email != null && tournament.organizerEmails.contains(currentUser.email)));

    return AppCard(
      onTap: () {
        Navigator.pushNamed(
          context,
          RouteConstants.tournamentDetail,
          arguments: {
            'tournament': tournament,
            'isOrganizer': isOrganizer,
          },
        );
      },
      child: SizedBox(
        height: 380, // ← CarouselSlider에 딱 맞는 고정 높이 (필수!)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 포스터 영역 (고정 180)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: tournament.imageUrl?.isNotEmpty == true
                      ? Image.network(
                    tournament.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) => progress == null
                        ? child
                        : Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: const Icon(Icons.sports_esports, size: 60, color: Colors.grey),
                    ),
                  )
                      : Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events, size: 60, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('포스터 없음', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),

                // 제목 오버레이
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: Text(
                      tournament.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // 상태 뱃지
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ArenaUtils.getStatusColor(status, context),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ArenaUtils.getStatusText(status),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (status == EntryStatus.open) ...[
                          const SizedBox(width: 8),
                          Text(
                            ArenaUtils.getEntryDday(tournament.entryEndDate),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 주최자 뱃지
                if (isOrganizer)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: const Text('주최 중', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
              ],
            ),

            // 하단 정보 영역 → Expanded + Clip으로 overflow 완벽 방지
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 설명 (넘치면 자름)
                    Expanded(
                      child: Text(
                        tournament.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 날짜 + 참가 정보
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${tournament.eventDate.toDate().month}/${tournament.eventDate.toDate().day}(${_getWeekday(tournament.eventDate.toDate().weekday)})',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ArenaUtils.getEventDday(tournament.eventDate),
                              style: TextStyle(fontSize: 14, color: Colors.deepOrange[700], fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${tournament.entryCount}명 참가',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tournament.entryFee == 0 ? '무료' : '${tournament.entryFee}원',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekday(int weekday) => ['월', '화', '수', '목', '금', '토', '일'][weekday - 1];
}