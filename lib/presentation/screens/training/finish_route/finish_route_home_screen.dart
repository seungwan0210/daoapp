// lib/presentation/screens/training/finish_route/finish_route_home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';

// 피니쉬 루트 전용 미니 위젯들
import 'widgets/finish_route_ranking_mini.dart';
import 'widgets/my_recent_record_mini.dart';

class FinishRouteHomeScreen extends StatefulWidget {
  const FinishRouteHomeScreen({super.key});

  @override
  State<FinishRouteHomeScreen> createState() => _FinishRouteHomeScreenState();
}

class _FinishRouteHomeScreenState extends State<FinishRouteHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

    if (user == null) {
      return Scaffold(
        appBar: const CommonAppBar(title: "피니쉬 루트 연습"),
        body: const Center(
          child: Text("로그인이 필요합니다."),
        ),
      );
    }

    return Scaffold(
      appBar: const CommonAppBar(title: "피니쉬 루트 연습"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 연습 시작 카드
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "랜덤 10문제 피니쉬 루트 연습",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "실제 다트보드를 떠올리면서 10개의 피니쉬 루트 문제를 풀어보세요.",
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            RouteConstants.finishRoutePractice, // ✅ 피니쉬 루트 연습 플레이
                          );
                        },
                        child: const Text("연습 시작하기"),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 통합 카드: 랭킹 + 내 기록
            AppCard(
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: "실시간 랭킹"),
                      Tab(text: "내 기록"),
                    ],
                  ),
                  SizedBox(
                    height: 200,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // === 실시간 랭킹 탭 ===
                        Column(
                          children: [
                            const Expanded(
                              child: FinishRouteRankingMini(
                                limit: 5,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  RouteConstants.finishRouteRanking, // ✅ 피니쉬 루트 전체 랭킹
                                );
                              },
                              child: const Text("전체 랭킹 보기"),
                            ),
                          ],
                        ),

                        // === 내 기록 탭 ===
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const MyRecentRecordMini(),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    RouteConstants.finishRouteMyHistory, // ✅ 피니쉬 루트 내 기록
                                  );
                                },
                                child: const Text("전체 기록 보기"),
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
          ],
        ),
      ),
    );
  }
}
