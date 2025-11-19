// lib/presentation/screens/arena/tournament_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:daoapp/core/utils/arena_utils.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/presentation/screens/community/arena/tournament_entry_form_screen.dart';

class TournamentDetailScreen extends StatelessWidget {
  final TournamentModel tournament;
  final bool isOrganizer; // 주최자인지 여부 (간단히 createdByUid로 판단)

  const TournamentDetailScreen({
    Key? key,
    required this.tournament,
    required this.isOrganizer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = ArenaUtils.getEntryStatus(
      eventDate: tournament.eventDate,
      entryStartDate: tournament.entryStartDate,
      entryEndDate: tournament.entryEndDate,
    );

    final canEntry = status == EntryStatus.open;

    return Scaffold(
      appBar: AppBar(title: const Text('대회 상세')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tournament.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(tournament.imageUrl!, height: 220, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 20),

            // 상태 뱃지 크게
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ArenaUtils.getStatusColor(status, context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(ArenaUtils.getStatusText(status), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),

            Text(tournament.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(tournament.description, style: const TextStyle(fontSize: 16)),

            const Divider(height: 40),

            // 정보 테이블
            _InfoRow(label: '대회일', value: '${tournament.eventDate.toDate().year}.${tournament.eventDate.toDate().month}.${tournament.eventDate.toDate().day}'),
            _InfoRow(label: '엔트리 기간', value: '${tournament.entryStartDate.toDate().month}/${tournament.entryStartDate.toDate().day} ~ ${tournament.entryEndDate.toDate().month}/${tournament.entryEndDate.toDate().day}'),
            _InfoRow(label: '참가비', value: tournament.entryFee == 0 ? '무료' : '${tournament.entryFee}원'),
            _InfoRow(label: '현재 참가자', value: '${tournament.entryCount}명'),

            const SizedBox(height: 30),

            // 버튼 영역
            if (isOrganizer)
              ElevatedButton(
                onPressed: () {
                  // TODO: 참가자 리스트 화면으로 이동
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentParticipantListScreen(tournamentId: tournament.id!)));
                },
                child: const Text('참가자 명단 보기'),
              )
            else if (canEntry)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TournamentEntryFormScreen(tournamentId: tournament.id!),
                      ),
                    );
                  },
                  child: const Text('참가하기', style: TextStyle(fontSize: 18)),
                ),
              )
            else
              Center(child: Text(ArenaUtils.getStatusText(status), style: TextStyle(fontSize: 18, color: ArenaUtils.getStatusColor(status, context)))),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}