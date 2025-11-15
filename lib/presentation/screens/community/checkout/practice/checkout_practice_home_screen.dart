// lib/presentation/screens/community/checkout/practice/checkout_practice_home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'widgets/checkout_ranking_mini.dart';
import 'widgets/my_recent_record_mini.dart'; // 새로 추가

class CheckoutPracticeHomeScreen extends StatefulWidget {
  const CheckoutPracticeHomeScreen({super.key});

  @override
  State<CheckoutPracticeHomeScreen> createState() => _CheckoutPracticeHomeScreenState();
}

class _CheckoutPracticeHomeScreenState extends State<CheckoutPracticeHomeScreen>
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
        appBar: const CommonAppBar(title: "체크아웃 연습 모드"),
        body: const Center(child: Text("로그인이 필요합니다.")),
      );
    }

    return Scaffold(
      appBar: const CommonAppBar(title: "체크아웃 연습 모드"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 연습 시작
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text("랜덤 10문제 체크아웃 연습", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("실제 다트보드를 터치해서 10개의 체크아웃 문제를 풀어보세요.", style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, RouteConstants.checkoutPracticePlay),
                        child: const Text("연습 시작하기"),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 통합: 랭킹 + 내 기록
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
                        // 랭킹
                        Column(
                          children: [
                            Expanded(child: CheckoutRankingMiniWidget(limit: 5)),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, RouteConstants.checkoutRanking),
                              child: const Text("전체 랭킹 보기"),
                            ),
                          ],
                        ),
                        // 내 기록 요약
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const MyRecentRecordMini(),
                              const Spacer(),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, RouteConstants.checkoutMyHistory),
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