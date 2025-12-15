// lib/presentation/screens/training/finish_route/finish_route_home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';

// ✅ finish_route 폴더 기준 (같은 폴더 아래 widgets)
import 'widgets/finish_route_ranking_mini.dart';
import 'widgets/my_recent_record_mini.dart';

class FinishRouteHomeScreen extends StatefulWidget {
  const FinishRouteHomeScreen({super.key});

  @override
  State<FinishRouteHomeScreen> createState() => _FinishRouteHomeScreenState();
}

class _FinishRouteHomeScreenState extends State<FinishRouteHomeScreen>
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

  Future<void> _openPracticeIfLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;

    if (isLoggedIn) {
      if (!mounted) return;
      Navigator.pushNamed(context, RouteConstants.finishRoutePractice);
      return;
    }

    if (!mounted) return;

    final goLogin = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("로그인이 필요합니다"),
        content: const Text(
          "피니시 루트 연습 기록은 계정에 저장됩니다.\n"
              "로그인 후 연습을 시작해 주세요.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "로그인 하기",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (goLogin == true && mounted) {
      Navigator.pushNamed(context, RouteConstants.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;

    return Scaffold(
      appBar: const CommonAppBar(title: "피니시 루트 연습"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ 연습 시작 카드 (✅ 로그인 필수로 변경)
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "랜덤 10문제 피니시 루트 연습",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "다트보드를 터치해서 남은 점수를 0으로 만들어보세요.\n"
                          "더블/불로 마무리하면 ‘확인’ 버튼으로 다음 문제로 넘어갑니다.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // ✅ 여기만 로그인 체크
                        onPressed: _openPracticeIfLoggedIn,
                        child: Text(isLoggedIn ? "연습 시작하기" : "로그인 후 연습 시작"),
                      ),
                    ),
                    if (!isLoggedIn) ...[
                      const SizedBox(height: 10),
                      Text(
                        "※ 로그인하면 내 기록 저장 / 랭킹 참가가 가능해요",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ 랭킹/내 기록 카드
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
                    height: 220,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // =========================
                        // 랭킹 탭
                        // =========================
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Expanded(
                                child: isLoggedIn
                                    ? const FinishRouteRankingMini(limit: 5)
                                    : const _LoginRequiredMini(
                                  message: "로그인 후 랭킹을 확인/참여할 수 있어요.",
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: isLoggedIn
                                      ? () => Navigator.pushNamed(
                                    context,
                                    RouteConstants.finishRouteRanking,
                                  )
                                      : null,
                                  child: const Text("전체 랭킹 보기"),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // =========================
                        // 내 기록 탭
                        // =========================
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Expanded(
                                child: isLoggedIn
                                    ? const MyRecentRecordMini()
                                    : const _LoginRequiredMini(
                                  message: "로그인 후 내 기록을 저장하고 볼 수 있어요.",
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: isLoggedIn
                                      ? () => Navigator.pushNamed(
                                    context,
                                    RouteConstants.finishRouteMyHistory,
                                  )
                                      : null,
                                  child: const Text("전체 기록 보기"),
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

            const SizedBox(height: 12),

            // ✅ 계산기 바로가기 (원하면)
            AppCard(
              child: ListTile(
                title: const Text(
                  "체크아웃 계산기",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("남은 점수 입력 → 추천 루트 확인"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(
                  context,
                  RouteConstants.checkoutCalculator,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginRequiredMini extends StatelessWidget {
  final String message;
  const _LoginRequiredMini({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
    );
  }
}
