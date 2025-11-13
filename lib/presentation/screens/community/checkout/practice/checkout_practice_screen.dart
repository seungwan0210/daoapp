// lib/presentation/screens/community/checkout/practice/checkout_practice_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoapp/presentation/providers/checkout_provider.dart';
import 'widgets/dart_input_panel.dart';
import 'widgets/remaining_score_display.dart';

class CheckoutPracticeScreen extends StatelessWidget {
  const CheckoutPracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckoutProvider()..startPractice(501),
      // const 제거! ChangeNotifierProvider는 const 아님
      child: Scaffold(
        appBar: AppBar(
          title: const Text("체크아웃 연습"),
          centerTitle: true,
        ),
        body: const Column(
          children: [
            RemainingScoreDisplay(), // 이건 const 가능
            Expanded(child: DartInputPanel()), // 이건 const 가능
          ],
        ),
      ),
    );
  }
}