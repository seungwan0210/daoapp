// lib/presentation/screens/arena/tournament/my_tournaments_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';

import 'package:daoapp/presentation/screens/arena/tournament/tournament_create_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournament_detail_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/widgets/tournament_card.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class MyTournamentsScreen extends StatelessWidget {
  const MyTournamentsScreen({super.key});

  FirebaseAuth get _auth => sl<FirebaseAuth>();
  ArenaRepository get _repo => sl<ArenaRepository>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(s.my_tournaments_title), // 🔹 다국어 적용
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          foregroundColor: theme.colorScheme.onBackground,
          surfaceTintColor: Colors.transparent,
        ),
        body: Center(child: Text(s.login_required)), // 🔹 공통 키 활용
      );
    }

    final userUid = user.uid;
    final userEmail = (user.email ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.my_tournaments_title), // 🔹 다국어 적용
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onBackground,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: s.my_tournaments_btn_create, // 🔹 다국어 적용
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
                  '${s.my_tournaments_error}\n${snapshot.error}', // 🔹 다국어 적용
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
                    Text(
                      s.my_tournaments_no_data, // 🔹 다국어 적용
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.my_tournaments_no_data_guide, // 🔹 다국어 적용
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
                        label: Text(s.my_tournaments_btn_create), // 🔹 다국어 적용
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

          // list
          return RefreshIndicator(
            onRefresh: () async {
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