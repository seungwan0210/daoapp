// lib/presentation/screens/arena/my_hosted_tournaments_screen.dart
import 'package:flutter/material.dart';
import 'package:daoapp/presentation/screens/community/arena/widgets/tournament_card.dart';  // ← 경로 수정!!
import 'package:daoapp/presentation/providers/arena_provider.dart';
import 'package:provider/provider.dart';

class MyHostedTournamentsScreen extends StatelessWidget {
  const MyHostedTournamentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내가 주최한 대회')),
      body: Consumer<ArenaProvider>(
        builder: (context, provider, child) {
          // 필터 자동 적용
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.changeFilter('my_hosted');
          });

          if (provider.isLoading && provider.tournaments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return provider.tournaments.isEmpty
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('주최한 대회가 없어요', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('지금 바로 첫 대회를 만들어보세요!'),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: () => provider.loadMore(reset: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.tournaments.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TournamentCard(tournament: provider.tournaments[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}