import 'package:flutter/material.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class TrainingHomeScreen extends StatelessWidget {
  const TrainingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CommonAppBar(title: "트레이닝"),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 오늘의 할 일
          AppCard(
            onTap: () => Navigator.pushNamed(context, RouteConstants.todayTasks),
            child: _TrainingItem(
              icon: Icons.today,
              title: "오늘의 체크아웃 과제",
              subtitle: "연습해야 할 미션이 준비되어 있어요!",
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 12),

          // 체크아웃 연습
          AppCard(
            onTap: () => Navigator.pushNamed(context, RouteConstants.checkoutPracticeHome),
            child: _TrainingItem(
              icon: Icons.sports_score,
              title: "체크아웃 연습",
              subtitle: "랜덤 10문제 / 기록 저장",
              color: Colors.green,
            ),
          ),

          const SizedBox(height: 12),

          // 레이팅 테스트
          AppCard(
            onTap: () => Navigator.pushNamed(context, RouteConstants.ratingTest),
            child: _TrainingItem(
              icon: Icons.stacked_bar_chart,
              title: "레이팅 테스트",
              subtitle: "현재 실력을 빠르게 측정해보세요!",
              color: Colors.orange,
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _TrainingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _TrainingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ],
    );
  }
}
