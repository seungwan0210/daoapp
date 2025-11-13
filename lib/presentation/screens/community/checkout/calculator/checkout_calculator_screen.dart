// lib/presentation/screens/community/checkout/calculator/checkout_calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoapp/core/constants/checkout_table.dart';
import 'package:daoapp/presentation/providers/checkout_provider.dart';
import 'package:daoapp/presentation/screens/community/checkout/calculator/widgets/route_card.dart';

class CheckoutCalculatorScreen extends StatefulWidget {
  @override
  _CheckoutCalculatorScreenState createState() => _CheckoutCalculatorScreenState();
}

class _CheckoutCalculatorScreenState extends State<CheckoutCalculatorScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckoutProvider(),
      child: Scaffold(
        appBar: AppBar(title: Text("체크아웃 계산기")),
        body: Consumer<CheckoutProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // 입력 필드
                  Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.go,
                        decoration: InputDecoration(
                          labelText: "남은 점수 (2~170)",
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: _calculate,
                          ),
                        ),
                        onSubmitted: (_) => _calculate(),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // 결과
                  Expanded(
                    child: provider.routes.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            "점수를 입력하면\n최적의 마무리 경로를 알려드려요!",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      itemCount: provider.routes.length,
                      itemBuilder: (context, index) {
                        final route = provider.routes[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: RouteCard(
                            route: route,
                            isPrimary: index == 0,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _calculate() {
    final score = int.tryParse(_controller.text);
    if (score == null || score < 2 || score > 170) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("2~170 사이의 점수를 입력해주세요")),
      );
      return;
    }
    context.read<CheckoutProvider>().calculateRoutes(score);
  }
}