// lib/presentation/screens/arena/tournament/my_tournaments_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';

import 'package:daoapp/presentation/screens/arena/tournament/tournament_create_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournament_detail_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/widgets/tournament_card.dart';

class MyTournamentsScreen extends StatelessWidget {
  const MyTournamentsScreen({super.key});

  FirebaseAuth get _auth => sl<FirebaseAuth>();
  ArenaRepository get _repo => sl<ArenaRepository>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('내가 주최한 대회'),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          foregroundColor: theme.colorScheme.onBackground,
          surfaceTintColor: Colors.transparent,
        ),
        body: const Center(child: Text('로그인이 필요합니다')),
      );
    }

    final userUid = user.uid;
    final userEmail = (user.email ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('내가 주최한 대회'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onBackground,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: '대회 개최하기',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TournamentCreateScreen()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),

      // ✅ Stream = 실시간 반영 (주최/공동주최 포함)
      body: StreamBuilder<List<TournamentModel>>(
        stream: _repo.getMyHostedTournaments(
          userUid: userUid,
          userEmail: userEmail,
          limit: 100,
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

          // empty
          if (tournaments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '아직 주최한 대회가 없어요',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '지금 바로 첫 대회를 만들어보세요!',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('대회 개최하기'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TournamentCreateScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // list (✅ 당겨서 새로고침 UX)
          return RefreshIndicator(
            onRefresh: () async {
              // StreamBuilder라 “강제 리프레시”는 따로 필요 없지만,
              // 사용자는 당겨서 새로고침을 기대하니까 UX용으로 200ms만
              await Future.delayed(const Duration(milliseconds: 200));
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: tournaments.length,
              itemBuilder: (context, index) {
                final tournament = tournaments[index];
                final id = (tournament.id ?? '').trim();

                return TournamentCard(
                  tournament: tournament,
                  onTap: () {
                    if (id.isEmpty) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TournamentDetailScreen(tournamentId: id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
