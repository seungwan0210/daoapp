// lib/presentation/screens/training/calculator/training_calculator_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/checkout_provider.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/checkout_table.dart';

/// 체크아웃 계산기 (트레이닝 탭)
class TrainingCalculatorScreen extends ConsumerStatefulWidget {
  const TrainingCalculatorScreen({super.key});

  @override
  ConsumerState<TrainingCalculatorScreen> createState() => _TrainingCalculatorScreenState();
}

class _TrainingCalculatorScreenState extends ConsumerState<TrainingCalculatorScreen> {
  final TextEditingController _initialController = TextEditingController();
  final List<int> _currentInput = [];
  int? _initialScore;

  @override
  void dispose() {
    _initialController.dispose();
    super.dispose();
  }

  void _startWithScore() {
    final scoreText = _initialController.text.trim();
    final score = int.tryParse(scoreText);
    if (score == null || score < 2 || score > 170) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("2~170 사이의 점수를 입력하세요")),
      );
      return;
    }

    setState(() => _initialScore = score);
    ref.read(checkoutProvider.notifier).setInitialScore(score);
  }

  void _onKeyPressed(String key) {
    setState(() {
      if (key == 'backspace') {
        if (_currentInput.isNotEmpty) _currentInput.removeLast();
      } else if (key == 'confirm') {
        if (_currentInput.isEmpty) return;
        final score = int.parse(_currentInput.join());
        final notifier = ref.read(checkoutProvider.notifier);

        if (score > notifier.state.remainingScore) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("남은 점수보다 클 수 없어요")),
          );
          return;
        }

        notifier.subtractScore(score);
        _currentInput.clear();
      } else {
        if (_currentInput.length < 3) {
          _currentInput.add(int.parse(key));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(checkoutProvider);
    final currentInputStr = _currentInput.isEmpty ? '' : _currentInput.join();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: const CommonAppBar(title: "체크아웃 계산기"),
      body: SafeArea(
        child: _initialScore == null
            ? _buildInitialInput(theme)
            : _buildCalculator(theme, state, currentInputStr, bottomInset),
      ),
    );
  }

  Widget _buildInitialInput(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "시작 점수를 입력하세요",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _initialController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "2 ~ 170",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
                onSubmitted: (_) => _startWithScore(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startWithScore,
                  child: const Text("시작하기", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculator(ThemeData theme, CheckoutState state, String currentInputStr, double bottomInset) {
    final notifier = ref.read(checkoutProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("남은 점수", style: TextStyle(fontSize: 16, color: Colors.grey)),
                            if (state.history.isNotEmpty)
                              TextButton.icon(
                                onPressed: () {
                                  notifier.undoLast();
                                  setState(() => _currentInput.clear());
                                },
                                icon: const Icon(Icons.undo, size: 18),
                                label: const Text("되돌리기"),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${state.remainingScore}",
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: state.remainingScore <= 60 ? Colors.red[700] : theme.colorScheme.primary,
                          ),
                        ),
                        if (currentInputStr.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text("이번 턴: $currentInputStr", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.orange[700])),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (state.routes.isNotEmpty)
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lightbulb, color: Colors.amber),
                              SizedBox(width: 8),
                              Text("추천 체크아웃 루트", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(state.routes.first.primary.join(" → "), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          if (state.routes.first.alts.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Text("대안 루트", style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            ...state.routes.first.alts.map((alt) => Padding(
                              padding: const EdgeInsets.only(left: 12, top: 4),
                              child: Text("• ${alt.join(" → ")}", style: const TextStyle(fontSize: 15)),
                            )),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 키패드
        Padding(
          padding: EdgeInsets.only(bottom: bottomInset > 20 ? bottomInset - 10 : 10, left: 8, right: 8),
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.6,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _key('7'), _key('8'), _key('9'),
                _key('4'), _key('5'), _key('6'),
                _key('1'), _key('2'), _key('3'),
                _key('backspace', icon: Icons.backspace_outlined, color: Colors.red[100]),
                _key('0'),
                _key('confirm', icon: Icons.check, color: _currentInput.isEmpty ? Colors.grey[300] : theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _key(String label, {IconData? icon, Color? color}) {
    final theme = Theme.of(context);
    final isConfirm = label == 'confirm';
    final isBackspace = label == 'backspace';

    return GestureDetector(
      onTap: () => _onKeyPressed(label),
      child: Container(
        decoration: BoxDecoration(
          color: color ?? Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: isBackspace ? Colors.red : (isConfirm && _currentInput.isNotEmpty ? Colors.white : Colors.grey[700]))
              : Text(
            label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isConfirm && _currentInput.isNotEmpty ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }
}