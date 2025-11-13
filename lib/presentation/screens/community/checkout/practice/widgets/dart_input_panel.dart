// lib/presentation/screens/community/checkout/practice/widgets/dart_input_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoapp/presentation/providers/checkout_provider.dart';

class DartInputPanel extends StatelessWidget {
  const DartInputPanel({super.key});

  final List<String> segments = const [
    'T20','T19','T18','T17','T16','T15',
    'D20','D19','D18','D17','D16','D15',
    'S20','S19','S18','Bull'
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutProvider>(
      builder: (context, p, _) => Column(
        children: [
          // 현재 턴
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: i < p.currentTurn.length ? Colors.green[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Text(
                    i < p.currentTurn.length ? p.currentTurn[i] : "",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              )),
            ),
          ),

          // 세그먼트 버튼
          Expanded(
            child: GridView.count(
              crossAxisCount: 6,
              padding: const EdgeInsets.all(16),
              children: segments.map((s) => ElevatedButton(
                onPressed: p.currentTurn.length < 3 ? () => p.inputDart(s) : null,
                child: Text(s, style: const TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(8)),
              )).toList(),
            ),
          ),

          // 턴 종료
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: p.currentTurn.isNotEmpty ? () => p.finishTurn(context) : null,
              child: const Text("턴 종료"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            ),
          ),
        ],
      ),
    );
  }
}