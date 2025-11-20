// lib/presentation/screens/community/arena/tournament_participant_list_screen.dart

import 'package:flutter/material.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class TournamentParticipantListScreen extends StatelessWidget {
  final String tournamentId;
  final String tournamentTitle;

  const TournamentParticipantListScreen({
    super.key,
    required this.tournamentId,
    this.tournamentTitle = '참가자 명단',
  });

  @override
  Widget build(BuildContext context) {
    final repo = sl<ArenaRepository>();

    return Scaffold(
      appBar: CommonAppBar(title: tournamentTitle, showBackButton: true),
      body: StreamBuilder(
        stream: repo.getEntries(tournamentId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data!;

          if (entries.isEmpty) {
            return const Center(child: Text('아직 참가자가 없습니다'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final e = entries[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text('${e.nameKo} (${e.nameEn})'),
                  subtitle: Text(e.phone),
                  trailing: e.rating != null ? Text('${e.rating}') : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

