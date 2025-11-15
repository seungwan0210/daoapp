// lib/presentation/screens/community/checkout/calculator/checkout_calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoapp/presentation/providers/checkout_provider.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class CheckoutCalculatorScreen extends StatefulWidget {
  const CheckoutCalculatorScreen({super.key});

  @override
  State<CheckoutCalculatorScreen> createState() =>
      _CheckoutCalculatorScreenState();
}

class _CheckoutCalculatorScreenState extends State<CheckoutCalculatorScreen> {
  final TextEditingController _initialController = TextEditingController();
  final List<int> _currentInput = [];
  int? _initialScore;

  @override
  void dispose() {
    _initialController.dispose();
    super.dispose();
  }

  /// 시작 점수 설정
  void _startWithScore(BuildContext context) {
    final score = int.tryParse(_initialController.text);
    if (score == null || score < 2 || score > 170) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("2~170 사이의 점수를 입력하세요")),
      );
      return;
    }
    setState(() => _initialScore = score);
    context.read<CheckoutProvider>().setInitialScore(score);
  }

  /// 키패드 입력 처리
  void _onKeyPressed(BuildContext context, String key) {
    setState(() {
      if (key == 'backspace') {
        if (_currentInput.isNotEmpty) _currentInput.removeLast();
      } else if (key == 'confirm') {
        if (_currentInput.isNotEmpty) {
          final score = int.parse(_currentInput.join());
          final provider = context.read<CheckoutProvider>();

          if (score <= provider.remainingScore) {
            provider.subtractScore(score);
            _currentInput.clear();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("남은 점수보다 클 수 없어요")),
            );
          }
        }
      } else {
        // 숫자 0~9
        if (_currentInput.length < 3) {
          _currentInput.add(int.parse(key));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckoutProvider(),
      child: Builder(
        builder: (innerContext) {
          final theme = Theme.of(innerContext);

          return Scaffold(
            appBar: const CommonAppBar(title: "체크아웃 계산기"),
            body: SafeArea(
              child: Consumer<CheckoutProvider>(
                builder: (ctx, provider, _) {
                  final currentInputStr =
                  _currentInput.isEmpty ? '' : _currentInput.join();
                  final bottomInset = MediaQuery.of(ctx).padding.bottom;

                  // ===================================================
                  // 1. 시작 점수 입력 화면 (위쪽 정렬)
                  // ===================================================
                  if (_initialScore == null) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: AppCard(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "시작 점수를 입력하세요",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _initialController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "남은 숫자 2~170",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  onSubmitted: (_) =>
                                      _startWithScore(innerContext),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _startWithScore(innerContext),
                                    child: const Text("시작하기"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // ===================================================
                  // 2. 계산기 화면
                  //    위: 남은 점수 + 루트 (위쪽에 붙여서)
                  //    아래: 키패드(AppCard, 전체가 보이게)
                  // ===================================================
                  return Column(
                    children: [
                      // 상단 영역: 남은 점수 + 추천 루트
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppCard(
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Text(
                                        "남은 점수",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "${provider.remainingScore}",
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: provider.remainingScore <= 50
                                              ? Colors.red[700]
                                              : theme.colorScheme.primary,
                                        ),
                                      ),
                                      if (currentInputStr.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          "이번 턴: $currentInputStr",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange[700],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (provider.routes.isNotEmpty)
                                AppCard(
                                  margin: const EdgeInsets.only(
                                      left: 0, right: 0, bottom: 0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.lightbulb,
                                          color: Colors.amber,
                                          size: 26,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            provider.routes.first.primary
                                                .join(" → "),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // 하단 키패드: AppCard + 높이 자동(버튼 4줄이 전부 보이게)
                      Padding(
                        padding: EdgeInsets.only(
                          left: 8,
                          right: 8,
                          top: 4,
                          bottom: bottomInset > 0 ? bottomInset : 4,
                        ),
                        child: AppCard(
                          margin: EdgeInsets.zero,
                          padding: const EdgeInsets.all(12),
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            childAspectRatio: 1.6,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            children: [
                              _buildKey(ctx, '7'),
                              _buildKey(ctx, '8'),
                              _buildKey(ctx, '9'),
                              _buildKey(ctx, '4'),
                              _buildKey(ctx, '5'),
                              _buildKey(ctx, '6'),
                              _buildKey(ctx, '1'),
                              _buildKey(ctx, '2'),
                              _buildKey(ctx, '3'),
                              _buildKey(ctx, 'backspace', isBackspace: true),
                              _buildKey(ctx, '0'),
                              _buildKey(ctx, 'confirm', isConfirm: true),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKey(
      BuildContext context,
      String label, {
        bool isBackspace = false,
        bool isConfirm = false,
      }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _onKeyPressed(context, label),
      child: Container(
        decoration: BoxDecoration(
          color: isBackspace
              ? Colors.red[50]
              : isConfirm
              ? (_currentInput.isEmpty
              ? Colors.grey[300]
              : theme.colorScheme.primary)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: isBackspace
              ? const Icon(Icons.backspace_outlined, color: Colors.red)
              : isConfirm
              ? Icon(
            Icons.check,
            color: _currentInput.isNotEmpty
                ? Colors.white
                : Colors.grey[700],
          )
              : Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isConfirm && _currentInput.isNotEmpty
                  ? Colors.white
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
