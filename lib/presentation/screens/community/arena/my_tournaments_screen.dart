// lib/presentation/screens/community/arena/my_tournaments_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/presentation/providers/arena_provider.dart';
import 'package:daoapp/presentation/screens/community/arena/widgets/tournament_card.dart';
import 'package:daoapp/presentation/screens/community/arena/tournament_detail_screen.dart';

class MyTournamentsScreen extends ConsumerWidget {
  const MyTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다')));
    }

    // 내가 주최했거나 공동주최자인 모든 대회 (종료된 것도 포함!)
    final myTournaments = ref.watch(arenaProvider).tournaments.where((t) {
      return t.createdByUid == user.uid ||
          t.organizerEmails.contains(user.email);
    }).toList();

    // 날짜 내림차순 정렬 (최신순)
    myTournaments.sort((a, b) => b.eventDate.compareTo(a.eventDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('내가 주최한 대회'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      body: myTournaments.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              '아직 주최한 대회가 없어요',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Text('지금 바로 첫 대회를 만들어보세요!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: myTournaments.length,
        itemBuilder: (context, index) {
          final tournament = myTournaments[index];
          return TournamentCard(
            tournament: tournament,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TournamentDetailScreen(tournamentId: tournament.id!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}