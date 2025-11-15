// lib/presentation/screens/community/checkout/checkout_home_screen.dart
import 'package:flutter/material.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class CheckoutHomeScreen extends StatelessWidget {
  const CheckoutHomeScreen({super.key}); // ← const 추가!

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: "체크아웃"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildModeCard(
              context,
              title: "계산기 모드",
              subtitle: "남은 점수 입력 → 추천 마무리 경로",
              icon: Icons.calculate,
              color: Colors.blue,
              route: RouteConstants.checkoutCalculator,
            ),
            const SizedBox(height: 16),
            _buildModeCard(
              context,
              title: "연습 모드",
              subtitle: "실제 게임처럼 연습 → 성공률 통계",
              icon: Icons.sports_score,
              color: Colors.green,
              route: RouteConstants.checkoutPractice,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required String route,
      }) {
    return AppCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, size: 34, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[500], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}