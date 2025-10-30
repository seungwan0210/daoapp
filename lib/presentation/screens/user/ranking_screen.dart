// lib/presentation/screens/user/ranking_screen.dart
import 'package:flutter/material.dart';
import 'package:daoapp/di/service_locator.dart';
import '../../providers/ranking_provider.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late final RankingProvider _rankingProvider;

  @override
  void initState() {
    super.initState();
    _rankingProvider = sl<RankingProvider>();
    // ChangeNotifier 변경 감지 → setState
    _rankingProvider.addListener(_updateUI);
    // 초기 로드
    _rankingProvider.loadRanking();
  }

  void _updateUI() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _rankingProvider.removeListener(_updateUI);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('랭킹')),
      body: Column(
        children: [
          // 필터
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _rankingProvider.selectedYear,
                    items: ['2026', '2027', '2028']
                        .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                        .toList(),
                    onChanged: (v) => _rankingProvider.updateFilters(
                      v!,
                      _rankingProvider.selectedPhase,
                      _rankingProvider.selectedGender,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _rankingProvider.selectedPhase,
                    items: const [
                      DropdownMenuItem(value: 'season1', child: Text('시즌1')),
                      DropdownMenuItem(value: 'season2', child: Text('시즌2')),
                      DropdownMenuItem(value: 'season3', child: Text('시즌3')),
                      DropdownMenuItem(value: 'total', child: Text('통합')),
                    ],
                    onChanged: (v) => _rankingProvider.updateFilters(
                      _rankingProvider.selectedYear,
                      v!,
                      _rankingProvider.selectedGender,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _rankingProvider.selectedGender,
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('남자')),
                      DropdownMenuItem(value: 'female', child: Text('여자')),
                    ],
                    onChanged: (v) => _rankingProvider.updateFilters(
                      _rankingProvider.selectedYear,
                      _rankingProvider.selectedPhase,
                      v!,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 랭킹 리스트
          Expanded(
            child: _rankingProvider.loading
                ? const Center(child: CircularProgressIndicator())
                : _rankingProvider.rankings.isEmpty
                ? const Center(
              child: Text(
                '랭킹 데이터가 없습니다.\n포인트를 부여해 보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _rankingProvider.rankings.length,
              itemBuilder: (_, i) {
                final user = _rankingProvider.rankings[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRankColor(user.rank),
                      child: Text(
                        '${user.rank}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      '${user.koreanName} (${user.englishName})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(user.shopName),
                    trailing: Text(
                      '${user.totalPoints} pt',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }
}