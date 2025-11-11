// lib/presentation/screens/community/checkout/checkout_practice_screen.dart
import 'package:flutter/material.dart';

class CheckoutPracticeScreen extends StatelessWidget {
  const CheckoutPracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("체크아웃 연습")),
      body: const Center(child: Text("연습 화면")),
    );
  }
}