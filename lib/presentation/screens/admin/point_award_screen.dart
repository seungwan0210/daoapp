// lib/presentation/screens/admin/point_award_screen.dart
import 'package:flutter/material.dart';

class PointAwardScreen extends StatelessWidget {
  const PointAwardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('포인트 부여하기')),
      body: const Center(
        child: Text(
          '포인트 부여 화면이에요!\n드롭다운 + 사진 업로드 + 버튼이 들어갈 거예요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}