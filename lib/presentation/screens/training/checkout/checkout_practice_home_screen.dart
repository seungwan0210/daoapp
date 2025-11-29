// lib/presentation/screens/training/checkout/checkout_practice_home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';

// 이 줄 추가!!!
import 'package:daoapp/presentation/providers/checkout_provider.dart';

// 트레이닝 전용 위젯들
import 'package:daoapp/presentation/screens/training/widgets/checkout_ranking_mini.dart';
import 'package:daoapp/presentation/screens/training/widgets/my_recent_record_mini.dart';

class CheckoutPracticeHomeScreen extends ConsumerStatefulWidget {
  const CheckoutPracticeHomeScreen({super.key});

  @override
  ConsumerState<CheckoutPracticeHomeScreen> createState() =>
      _CheckoutPracticeHomeScreenState();
}

class _CheckoutPracticeHomeScreenState
    extends ConsumerState<CheckoutPracticeHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // 로그인 안 됐으면 로그인 유도
    if (user == null) {
      return Scaffold(
        appBar: const CommonAppBar(title: "체크아웃 연습 모드"),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text("로그인이 필요합니다", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteConstants.login,
                      (route) => false,
                ),
                child: const Text("로그인 하러 가기"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const CommonAppBar(title: "체크아웃 연습"),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 연습 시작 카드
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        "랜덤 10문제 체크아웃 연습",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "실제 다트보드를 터치해서 10개의 문제를 풀어보세요!\n기록은 자동 저장됩니다.",
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // 이제 checkoutProvider 완벽하게 동작!
                            ref.read(checkoutProvider.notifier).startPractice();
                            Navigator.pushNamed(
                              context,
                              RouteConstants.checkoutPracticePlay,
                            );
                          },
                          icon: const Icon(Icons.play_arrow, size: 28),
                          label: const Text("연습 시작하기", style: TextStyle(fontSize: 18)),
                          style: ElevatedButton.styleFrom(
                            elevation: 4,
                            shadowColor: Colors.green.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 통합 탭 카드: 실시간 랭킹 + 내 기록
              AppCard(
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: "실시간 랭킹 TOP 5"),
                        Tab(text: "내 최근 기록"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 260,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // 실시간 랭킹
                          Column(
                            children: [
                              const Expanded(
                                child: CheckoutRankingMiniWidget(limit: 5),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: TextButton.icon(
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    RouteConstants.checkoutRanking,
                                  ),
                                  icon: const Icon(Icons.bar_chart),
                                  label: const Text("전체 랭킹 보기"),
                                ),
                              ),
                            ],
                          ),

                          // 내 최근 기록
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              children: [
                                const Expanded(child: MyRecentRecordMini()),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    RouteConstants.checkoutMyHistory,
                                  ),
                                  icon: const Icon(Icons.history),
                                  label: const Text("전체 기록 보기"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}