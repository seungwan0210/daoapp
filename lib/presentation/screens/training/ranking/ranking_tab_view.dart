import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';
import 'package:daoapp/presentation/screens/training/ranking/ranking_list_item.dart';
import 'package:daoapp/presentation/screens/training/ranking/game_selection_sheet.dart';
import 'package:daoapp/data/models/ranking_game_model.dart';

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
    // 탭 개수를 4개로 늘렸습니다 (501, Cricket, Count-Up, 통합)
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
    return Column(
      children: [
        // 1. 슬림한 탭바 디자인
        TabBar(
          controller: _tabController,
          labelColor: Colors.cyan[800],
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.cyan,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(height: 36, text: "501"),
            Tab(height: 36, text: "Cricket"),
            Tab(height: 36, text: "Count-Up"),
            Tab(height: 36, text: "통합 🔥"), // 🆕 통합 탭 추가
          ],
        ),
        const SizedBox(height: 12),

        // 2. 랭킹 리스트 영역
        AppCard(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildCurrentRankingList(),
          ),
        ),

        const SizedBox(height: 16),

        // 3. 도전 버튼
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "랭킹 도전하기",
                    style: TextStyle(
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

        // 4. 안내 문구
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            children: [
              const Text(
                "💡 기록 관리 안내",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "내 기록을 길게 꾹 누르면 해당 기록을 삭제할 수 있습니다.",
                style: TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // 🔥 경고 문구: 부정한 방법 기록 삭제 안내
              Text(
                "공정한 랭킹 문화를 위해 부적절한 방법으로 등록된 기록은\n관리자에 의해 예고 없이 삭제될 수 있습니다.",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.redAccent.withOpacity(0.8),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "통합 랭킹은 각 종목 TOP 10 기록을 합산하여 결정됩니다.",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.cyan[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ], // Column children 끝
    ); // return Column 끝
  }

  Widget _buildCurrentRankingList() {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? "";
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
      case 3: // 🆕 통합 랭킹 전용 빌더 호출
        return _buildTotalRankingSection(myUid);
      default:
        return const SizedBox.shrink();
    }
  }

  // -----------------------------------------------------------------
  // 🏆 [통합 랭킹 빌더] - 10위 밖은 순위 없음(-) 처리 로직 포함
  // -----------------------------------------------------------------
  Widget _buildTotalRankingSection(String myUid) {
    final totalRanking = ref.watch(totalRankingProvider);

    if (totalRanking.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text("아직 통합 집계 데이터가 없습니다.", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      );
    }

    final myIndex = totalRanking.indexWhere((item) => item['userId'] == myUid);
    final bool isInTop10 = myIndex != -1 && myIndex < 10;
    final bool hasMyData = myIndex != -1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- [통합 TOP 10] ---
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

        // --- [내 통합 순위 섹션: 10위 밖일 때 '-'로 표시] ---
        if (!isInTop10 && hasMyData) ...[
          const Divider(thickness: 2, color: Colors.cyan),
          RankingListItem(
            rank: -1, // 👈 10위 밖이므로 '-' 표시를 위해 -1 전달
            record: totalRanking[myIndex]['record'],
            displayValue: "${totalRanking[myIndex]['totalPoints']} P",
            isMe: true,
            category: 'total',
          ),
        ],
      ],
    );
  }

  // -----------------------------------------------------------------
  // 🎯 [일반 종목 빌더] - 기존 로직 유지 (순위 모두 표시)
  // -----------------------------------------------------------------
  Widget _buildRankingList({
    required Key key,
    required AsyncValue<List<RankingRecord>> asyncRanking,
    required String Function(RankingRecord) valueFormatter,
    required String myUid,
    required String category,
  }) {
    return Container(
      key: key,
      child: asyncRanking.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text("아직 기록이 없습니다.", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                  rank: myIndex + 1, // 👈 일반 종목은 10위 밖이라도 정확한 숫자를 보여줍니다.
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
        error: (e, _) => const Center(
          child: Padding(padding: EdgeInsets.all(40), child: Text("데이터 로드 실패")),
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