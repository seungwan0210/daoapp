// lib/presentation/screens/checkout/checkout_calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/core/constants/checkout_table.dart';
import 'package:daoapp/data/models/checkout_route_model.dart';
import 'package:daoapp/presentation/screens/community/checkout/widgets/route_card.dart';

/// 상태 관리
final remainingScoreProvider = StateProvider<int>((ref) => 501);
final previousScoreProvider = StateProvider<int>((ref) => 501); // 버스트 롤백용

class CheckoutCalculatorScreen extends ConsumerWidget {
  const CheckoutCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(remainingScoreProvider);
    final route = _getRecommendedRoute(remaining);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout Calculator"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '초기화',
            onPressed: () {
              ref.read(remainingScoreProvider.notifier).state = 501;
              ref.read(previousScoreProvider.notifier).state = 501;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 남은 점수 표시
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  "$remaining",
                  style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (remaining == 0)
                  const Text("체크아웃 성공!", style: TextStyle(color: Colors.blue, fontSize: 20))
                else if (remaining == 1)
                  const Text("1점 남음 → 버스트!", style: TextStyle(color: Colors.red))
                else if (remaining <= 170 && remaining >= 2)
                    const Text("체크아웃 가능!", style: TextStyle(color: Colors.green))
                  else if (remaining > 170)
                      const Text("3다트로 불가능", style: TextStyle(color: Colors.orange)),
              ],
            ),
          ),

          // 추천 루트
          if (route != null && remaining > 1 && remaining <= 170)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: RouteCard(route: route),
            ),

          const Spacer(),

          // 키패드
          Expanded(
            flex: 2,
            child: _buildKeypad(context, ref),
          ),
        ],
      ),
    );
  }

  // 전체 키패드 (6열)
  Widget _buildKeypad(BuildContext context, WidgetRef ref) {
    final segments = [
      'Miss', 'S1', 'S2', 'S3', 'S4', 'S5',
      'S6', 'S7', 'S8', 'S9', 'S10', 'S11',
      'S12', 'S13', 'S14', 'S15', 'S16', 'S17',
      'S18', 'S19', 'S20', 'D1', 'D2', 'D3',
      'D4', 'D5', 'D6', 'D7', 'D8', 'D9',
      'D10', 'D11', 'D12', 'D13', 'D14', 'D15',
      'D16', 'D17', 'D18', 'D19', 'D20', 'T1',
      'T2', 'T3', 'T4', 'T5', 'T6', 'T7',
      'T8', 'T9', 'T10', 'T11', 'T12', 'T13',
      'T14', 'T15', 'T16', 'T17', 'T18', 'T19',
      'T20', 'SBull', 'Bull',
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.4,
        ),
        itemCount: segments.length,
        itemBuilder: (context, index) => _keyButton(segments[index], ref, context),
      ),
    );
  }

  // 개별 버튼
  Widget _keyButton(String label, WidgetRef ref, BuildContext context) {
    final isMiss = label == 'Miss';
    final isBull = label == 'Bull';
    final isSBull = label == 'SBull';

    return ElevatedButton(
      onPressed: () => _onSegmentPressed(label, ref, context),
      style: ElevatedButton.styleFrom(
        backgroundColor: isMiss
            ? Colors.red[100]
            : isBull
            ? Colors.green[600]
            : isSBull
            ? Colors.green[400]
            : Theme.of(context).colorScheme.surfaceVariant,
        foregroundColor: isMiss
            ? Colors.red[900]
            : isBull || isSBull
            ? Colors.white
            : null,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: FittedBox(
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  // 입력 처리
  void _onSegmentPressed(String seg, WidgetRef ref, BuildContext context) {
    final current = ref.read(remainingScoreProvider);
    final score = _segmentToScore(seg);
    final newScore = current - score;

    // 버스트
    if (newScore < 0 || newScore == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("버스트! 점수 유지: $current"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    // 정확한 체크아웃
    if (newScore == 0 && seg.startsWith('D')) {
      ref.read(remainingScoreProvider.notifier).state = 0;
      ref.read(previousScoreProvider.notifier).state = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("체크아웃 성공!"),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    // 정상 입력
    ref.read(previousScoreProvider.notifier).state = current;
    ref.read(remainingScoreProvider.notifier).state = newScore;
  }

  // 점수 변환
  int _segmentToScore(String seg) {
    if (seg == 'Miss') return 0;
    if (seg == 'Bull') return 50;
    if (seg == 'SBull') return 25;
    final type = seg[0];
    final num = int.parse(seg.substring(1));
    return switch (type) {
      'S' => num,
      'D' => num * 2,
      'T' => num * 3,
      _ => 0,
    };
  }

  // 추천 루트
  CheckoutRoute? _getRecommendedRoute(int remaining) {
    if (remaining > 170 || remaining < 2) return null;

    // 정확한 체크아웃
    final exact = checkoutTable[remaining.toString()];
    if (exact != null) return exact;

    // 불가능 점수 → 다음 턴 더블 남기기
    final setup = _findSetupRoute(remaining);
    if (setup != null) {
      return CheckoutRoute(
        primary: setup,
        alts: [],
      );
    }

    return null;
  }

  // 다음 턴 더블 남기기 (안전한 루프)
  List<String> _findSetupRoute(int remaining) {
    for (int i = 2; i <= 60; i++) {
      final target = remaining - i;
      if (target >= 2 && target <= 40 && target % 2 == 0) {
        final segment = target <= 20 ? 'S$target' : 'D${target ~/ 2}';
        return [segment, '다음 턴 더블'];
      }
    }
    return ['S${remaining.clamp(1, 20)}', '다음 턴 더블'];
  }
}