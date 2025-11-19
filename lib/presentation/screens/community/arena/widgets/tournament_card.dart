// lib/presentation/screens/community/arena/widgets/tournament_card.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod 추가 (필요 없어도 안전)
import 'package:daoapp/core/utils/arena_utils.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class TournamentCard extends StatelessWidget {
  final TournamentModel tournament;

  const TournamentCard({
    super.key,
    required this.tournament,
  });

  @override
  Widget build(BuildContext context) {
    final status = ArenaUtils.getEntryStatus(
      eventDate: tournament.eventDate,
      entryStartDate: tournament.entryStartDate,
      entryEndDate: tournament.entryEndDate,
    );

    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isOrganizer = currentUser != null &&
        (tournament.createdByUid == currentUser.uid ||
            (currentUser.email != null && tournament.organizerEmails.contains(currentUser.email)));

    return Card(
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.15),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 포스터 이미지 (있을 때만)
            if (tournament.imageUrl?.isNotEmpty == true)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  tournament.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 160,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상태 뱃지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ArenaUtils.getStatusColor(status, context),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: ArenaUtils.getStatusColor(status, context).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ArenaUtils.getStatusText(status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (status == EntryStatus.open) ...[
                          const SizedBox(width: 6),
                          Text(
                            ArenaUtils.getEntryDday(tournament.entryEndDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 제목
                  Text(
                    tournament.title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // 설명
                  Text(
                    tournament.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // 하단 정보
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 왼쪽: 대회일 + D-Day
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '대회일: ${tournament.eventDate.toDate().month.toString().padLeft(2, '0')}/${tournament.eventDate.toDate().day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ArenaUtils.getEventDday(tournament.eventDate),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.deepOrange[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // 오른쪽: 참가자 수 + 주최자 표시
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${tournament.entryCount}명 참가',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          if (isOrganizer)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '주최 중',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}