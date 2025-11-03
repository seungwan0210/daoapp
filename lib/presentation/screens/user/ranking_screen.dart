// lib/presentation/screens/user/ranking_screen.dart
import 'package:flutter/material.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/providers/ranking_provider.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';

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
    _rankingProvider.addListener(_updateUI);
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
      appBar: AppBar(
        title: const Text('RANKING'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 필터 (AppCard로 감쌈)
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _buildYearDropdown()),
                const SizedBox(width: 8),
                Expanded(child: _buildPhaseDropdown()),
                const SizedBox(width: 8),
                Expanded(child: _buildGenderDropdown()),
                const SizedBox(width: 8),
                Expanded(child: _buildTop9Dropdown()),
              ],
            ),
          ),

          // 랭킹 리스트
          Expanded(
            child: _rankingProvider.loading
                ? const Center(child: CircularProgressIndicator())
                : _rankingProvider.rankings.isEmpty
                ? Center(
              child: Text(
                '랭킹 데이터가 없습니다.\n포인트를 부여해 보세요!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: _rankingProvider.rankings.length,
              itemBuilder: (_, i) {
                final user = _rankingProvider.rankings[i];
                return AppCard(
                  onTap: () {
                    // 유저 상세 페이지 (나중에 추가)
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: _getRankColor(user.rank),
                      child: Text(
                        '${user.rank}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.koreanName,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '(${user.englishName})',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    subtitle: Text(
                      user.shopName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${user.displayPoints} pt',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (user.top9Points != null && user.top9Points != user.totalPoints)
                          Text(
                            '전체: ${user.totalPoints}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
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

  // 드롭다운 위젯들 (오류 100% 해결!)
  Widget _buildYearDropdown() {
    return DropdownButton<String>(
      isExpanded: true,
      value: _rankingProvider.selectedYear,
      items: ['2026', '2027', '2028']
          .map((y) => DropdownMenuItem(value: y, child: Text(y)))
          .toList(),
      onChanged: (v) => _rankingProvider.updateFilters(v!, _rankingProvider.selectedPhase, _rankingProvider.selectedGender),
      underline: Container(height: 1, color: Colors.grey),
    );
  }

  Widget _buildPhaseDropdown() {
    return DropdownButton<String>(
      isExpanded: true,
      value: _rankingProvider.selectedPhase,
      items: const [
        DropdownMenuItem(value: 'total', child: Text('통합')),
        DropdownMenuItem(value: 'season1', child: Text('시즌1')),
        DropdownMenuItem(value: 'season2', child: Text('시즌2')),
        DropdownMenuItem(value: 'season3', child: Text('시즌3')),
      ].map((item) => DropdownMenuItem(value: item.value, child: item.child))
          .toList(),
      onChanged: (v) => _rankingProvider.updateFilters(_rankingProvider.selectedYear, v!, _rankingProvider.selectedGender),
      underline: Container(height: 1, color: Colors.grey),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButton<String>(
      isExpanded: true,
      value: _rankingProvider.selectedGender,
      items: const [
        DropdownMenuItem(value: 'all', child: Text('전체')), // 추가!
        DropdownMenuItem(value: 'male', child: Text('남자')),
        DropdownMenuItem(value: 'female', child: Text('여자')),
      ].map((item) => DropdownMenuItem(
        value: item.value,
        child: item.child,
      ))
          .toList(),
      onChanged: (v) => _rankingProvider.updateFilters(
        _rankingProvider.selectedYear,
        _rankingProvider.selectedPhase,
        v!, // 전체 / 남자 / 여자
      ),
      underline: Container(height: 1, color: Colors.grey),
    );
  }

  Widget _buildTop9Dropdown() {
    return DropdownButton<bool>(
      isExpanded: true,
      value: _rankingProvider.selectedPhase == 'total' ? false : _rankingProvider.top9Mode,
      items: [
        const DropdownMenuItem(value: false, child: Text('전체 포인트')),
        if (_rankingProvider.selectedPhase != 'total')
          const DropdownMenuItem(value: true, child: Text('상위 9개')),
      ].map((item) => DropdownMenuItem(value: item.value, child: item.child))
          .toList(),
      onChanged: _rankingProvider.selectedPhase == 'total'
          ? null
          : (v) => _rankingProvider.toggleTop9Mode(),
      underline: Container(height: 1, color: Colors.grey),
    );
  }

  // 랭킹 색상
  Color _getRankColor(int rank) {
    return switch (rank) {
      1 => Colors.amber,
      2 => Colors.grey,
      3 => Colors.brown[700]!,
      _ => Theme.of(context).colorScheme.primary,
    };
  }
}