// lib/presentation/screens/community/checkout/checkout_trainer_preview.dart
import 'package:flutter/material.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';

class CheckoutTrainerPreview extends StatelessWidget {
  const CheckoutTrainerPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("Checkout Trainer", style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: () => MainScreen.changeTab(context, 3),
                      child: const Text("전체 보기"),
                    ),
                  ],
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.calculate, size: 60, color: Colors.blue),
                        SizedBox(height: 16),
                        Text("501 Double Out 계산기", style: TextStyle(fontSize: 16)),
                        Text("연습 모드 준비 중", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}