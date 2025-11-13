// lib/presentation/screens/community/checkout/checkout_home_screen.dart
import 'package:flutter/material.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class CheckoutHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("체크아웃"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
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
            SizedBox(height: 16),
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, size: 34, color: color),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}