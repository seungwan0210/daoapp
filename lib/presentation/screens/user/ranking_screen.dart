// lib/presentation/screens/user/ranking_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider; // 별칭
import '../../providers/ranking_provider.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 변수 이름 변경: provider → rankingProvider
    final rankingProvider = provider.Provider.of<RankingProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('랭킹')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: rankingProvider.selectedYear,
                    items: ['2026', '2027', '2028'].map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                    onChanged: (v) => rankingProvider.updateFilters(v!, rankingProvider.selectedPhase, rankingProvider.selectedGender),
                  ),
                ),
                Expanded(
                  child: DropdownButton<String>(
                    value: rankingProvider.selectedPhase,
                    items: [
                      DropdownMenuItem(value: 'season1', child: Text('시즌1')),
                      DropdownMenuItem(value: 'season2', child: Text('시즌2')),
                      DropdownMenuItem(value: 'season3', child: Text('시즌3')),
                      DropdownMenuItem(value: 'total', child: Text('통합')),
                    ],
                    onChanged: (v) => rankingProvider.updateFilters(rankingProvider.selectedYear, v!, rankingProvider.selectedGender),
                  ),
                ),
                Expanded(
                  child: DropdownButton<String>(
                    value: rankingProvider.selectedGender,
                    items: [
                      DropdownMenuItem(value: 'male', child: Text('남자')),
                      DropdownMenuItem(value: 'female', child: Text('여자')),
                    ],
                    onChanged: (v) => rankingProvider.updateFilters(rankingProvider.selectedYear, rankingProvider.selectedPhase, v!),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: rankingProvider.loading
                ? const Center(child: CircularProgressIndicator())
                : rankingProvider.rankings.isEmpty
                ? const Center(child: Text('데이터 없음'))
                : ListView.builder(
              itemCount: rankingProvider.rankings.length,
              itemBuilder: (_, i) {
                final user = rankingProvider.rankings[i];
                return ListTile(
                  leading: CircleAvatar(child: Text('${user.rank}')),
                  title: Text('${user.koreanName} (${user.englishName})'),
                  subtitle: Text('${user.shopName}'),
                  trailing: Text('${user.totalPoints} pt', style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}