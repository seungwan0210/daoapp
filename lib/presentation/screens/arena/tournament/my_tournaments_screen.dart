// lib/presentation/screens/arena/tournament/my_tournaments_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';

// 🔧 경로 변경: arena/tournament/widgets 로 이동했다고 가정
import 'package:daoapp/presentation/screens/arena/tournament/widgets/tournament_card.dart';
// 🔧 경로 변경: arena/tournament/ 로 이동했다고 가정
import 'package:daoapp/presentation/screens/arena/tournament/tournament_detail_screen.dart';

class MyTournamentsScreen extends ConsumerWidget {
  const MyTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('로그인이 필요합니다'),
        ),
      );
    }

    final repo = sl<ArenaRepository>();
    final userUid = user.uid;
    final userEmail = user.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('내가 주최한 대회'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      body: StreamBuilder<List<TournamentModel>>(
        stream: repo.getMyHostedTournaments(
          userUid: userUid,
          userEmail: userEmail,
          limit: 100, // 나중에 필요하면 무한 스크롤로 확장 가능
        ),
        builder: (context, snapshot) {
          // 에러
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '대회 정보를 불러오는 중 오류가 발생했습니다.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          // 로딩
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tournaments = snapshot.data ?? [];

          // 주최한 대회가 하나도 없을 때
          if (tournaments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '아직 주최한 대회가 없어요',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '지금 바로 첫 대회를 만들어보세요!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // 리스트
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final tournament = tournaments[index];

              return TournamentCard(
                tournament: tournament,
                onTap: () {
                  if (tournament.id == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TournamentDetailScreen(
                        tournamentId: tournament.id!,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
