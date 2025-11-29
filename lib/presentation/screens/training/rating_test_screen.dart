import 'package:flutter/material.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class RatingTestScreen extends StatefulWidget {
  const RatingTestScreen({super.key});

  @override
  State<RatingTestScreen> createState() => _RatingTestScreenState();
}

class _RatingTestScreenState extends State<RatingTestScreen> {
  final _controller = TextEditingController();
  double? _rating;

  void _calculate() {
    final score = double.tryParse(_controller.text.trim());
    if (score == null) return;

    // ★ 예시 계산식 (나중에 진짜 MPR/PPD 넣으면 됨)
    setState(() => _rating = score / 10.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: "레이팅 테스트"),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "점수 입력", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text("레이팅 계산하기"),
              ),
            ),
            const SizedBox(height: 24),
            if (_rating != null)
              Text(
                "예상 레이팅: ${_rating!.toStringAsFixed(1)}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
