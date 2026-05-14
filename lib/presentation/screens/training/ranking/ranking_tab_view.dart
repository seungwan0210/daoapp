import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';
import 'package:daoapp/presentation/screens/training/ranking/ranking_list_item.dart';
import 'package:daoapp/presentation/screens/training/ranking/game_selection_sheet.dart';
import 'package:daoapp/data/models/ranking_game_model.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class RankingTabView extends ConsumerStatefulWidget {
  const RankingTabView({super.key});

  @override
  ConsumerState<RankingTabView> createState() => _RankingTabViewState();
}

class _RankingTabViewState extends ConsumerState<RankingTabView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 추가

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.cyan[800],
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.cyan,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: [
            const Tab(height: 36, text: "501"),
            const Tab(height: 36, text: "Cricket"),
            const Tab(height: 36, text: "Count-Up"),
            Tab(height: 36, text: s.rank_tab_total), // 🔹 다국어화
          ],
        ),
        const SizedBox(height: 12),

        AppCard(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildCurrentRankingList(),
          ),
        ),

        const SizedBox(height: 16),

        Center(
          child: InkWell(
            onTap: () => _showGameSelectionSheet(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.cyan[700],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    s.rank_btn_challenge, // 🔹 다국어화
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            children: [
              Text(
                s.rank_guide_title, // 🔹 다국어화
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.rank_guide_delete, // 🔹 다국어화
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                s.rank_guide_warning, // 🔹 다국어화
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.redAccent.withOpacity(0.8),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                s.rank_guide_badge, // 🔹 다국어화
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.cyan[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentRankingList() {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final s = AppLocalizations.of(context)!;

    switch (_tabController.index) {
      case 0:
        return _buildRankingList(
          key: const ValueKey('ppd'),
          asyncRanking: ref.watch(ppdRankingProvider),
          valueFormatter: (r) => r.bestPpd.toStringAsFixed(2),
          myUid: myUid,
          category: 'ppd',
        );
      case 1:
        return _buildRankingList(
          key: const ValueKey('mpr'),
          asyncRanking: ref.watch(mprRankingProvider),
          valueFormatter: (r) => r.bestMpr.toStringAsFixed(2),
          myUid: myUid,
          category: 'mpr',
        );
      case 2:
        return _buildRankingList(
          key: const ValueKey('countup'),
          asyncRanking: ref.watch(countUpRankingProvider),
          valueFormatter: (r) => "${r.bestCountUp}",
          myUid: myUid,
          category: 'countup',
        );
      case 3:
        return _buildTotalRankingSection(myUid);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTotalRankingSection(String myUid) {
    final s = AppLocalizations.of(context)!;
    final totalRanking = ref.watch(totalRankingProvider);

    if (totalRanking.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(s.rank_no_total_data, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      );
    }

    final myIndex = totalRanking.indexWhere((item) => item['userId'] == myUid);
    final bool isInTop10 = myIndex != -1 && myIndex < 10;
    final bool hasMyData = myIndex != -1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: totalRanking.length > 10 ? 10 : totalRanking.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = totalRanking[index];
            return RankingListItem(
              rank: index + 1,
              record: item['record'],
              displayValue: "${item['totalPoints']} P",
              isMe: item['userId'] == myUid,
              category: 'total',
            );
          },
        ),
        if (!isInTop10 && hasMyData) ...[
          const Divider(thickness: 2, color: Colors.cyan),
          RankingListItem(
            rank: -1,
            record: totalRanking[myIndex]['record'],
            displayValue: "${totalRanking[myIndex]['totalPoints']} P",
            isMe: true,
            category: 'total',
          ),
        ],
      ],
    );
  }

  Widget _buildRankingList({
    required Key key,
    required AsyncValue<List<RankingRecord>> asyncRanking,
    required String Function(RankingRecord) valueFormatter,
    required String myUid,
    required String category,
  }) {
    final s = AppLocalizations.of(context)!;
    return Container(
      key: key,
      child: asyncRanking.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(s.rank_no_data, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            );
          }

          final myIndex = list.indexWhere((r) => r.userId == myUid);
          final bool isInTop10 = myIndex != -1 && myIndex < 10;
          final bool hasMyData = myIndex != -1;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: list.length > 10 ? 10 : list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) => RankingListItem(
                  rank: index + 1,
                  record: list[index],
                  displayValue: valueFormatter(list[index]),
                  isMe: list[index].userId == myUid,
                  category: category,
                ),
              ),
              if (!isInTop10 && hasMyData) ...[
                const Divider(thickness: 2, color: Colors.cyan),
                RankingListItem(
                  rank: myIndex + 1,
                  record: list[myIndex],
                  displayValue: valueFormatter(list[myIndex]),
                  isMe: true,
                  category: category,
                ),
              ],
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (e, _) => Center(
          child: Padding(padding: const EdgeInsets.all(40), child: Text(s.rank_load_failed)),
        ),
      ),
    );
  }

  void _showGameSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => const GameSelectionSheet(),
    );
  }
}