// lib/presentation/screens/community/checkout/checkout_result_screen.dart
import 'package:flutter/material.dart';

class CheckoutResultScreen extends StatelessWidget {
  const CheckoutResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("체크아웃 결과")),
      body: const Center(child: Text("결과 화면")),
    );
  }
}