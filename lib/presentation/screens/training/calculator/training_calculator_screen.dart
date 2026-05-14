import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:daoapp/presentation/providers/training/calculator/checkout_calculator_provider.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

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

  void _startWithScore(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final score = int.tryParse(_initialController.text);

    if (score == null || score < 2 || score > 170) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.calc_error_range)),
      );
      return;
    }
    setState(() => _initialScore = score);
    context.read<CheckoutCalculatorProvider>().setInitialScore(score);
  }

  void _onKeyPressed(BuildContext context, String key) {
    final s = AppLocalizations.of(context)!;
    setState(() {
      if (key == 'backspace') {
        if (_currentInput.isNotEmpty) _currentInput.removeLast();
        return;
      }

      if (key == 'confirm') {
        if (_currentInput.isEmpty) return;

        final score = int.parse(_currentInput.join());
        final provider = context.read<CheckoutCalculatorProvider>();

        if (score <= provider.remainingScore) {
          provider.subtractScore(score);
          _currentInput.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.calc_error_exceed)),
          );
        }
        return;
      }

      // 숫자 입력
      if (_currentInput.length < 3) {
        _currentInput.add(int.parse(key));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckoutCalculatorProvider(),
      child: Builder(
        builder: (innerContext) {
          final s = AppLocalizations.of(innerContext)!;
          final theme = Theme.of(innerContext);

          return Scaffold(
            appBar: CommonAppBar(title: s.calc_title),
            body: SafeArea(
              child: Consumer<CheckoutCalculatorProvider>(
                builder: (ctx, provider, _) {
                  final currentInputStr =
                  _currentInput.isEmpty ? '' : _currentInput.join();
                  final bottomInset = MediaQuery.of(ctx).padding.bottom;

                  // ==========================
                  // 1) 시작 점수 입력 화면
                  // ==========================
                  if (_initialScore == null) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                                  s.calc_start_msg,
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
                                    hintText: s.calc_start_hint,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding:
                                    const EdgeInsets.symmetric(vertical: 16),
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
                                    child: Text(s.calc_btn_start),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // ==========================
                  // 2) 계산기 화면
                  // ==========================
                  return Column(
                    children: [
                      // 상단: 남은 점수 + 추천 루트
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 남은 점수 + 되돌리기
                              AppCard(
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            s.calc_remain_score,
                                            style: TextStyle(
                                                color: Colors.grey[600]),
                                          ),
                                          if (provider.canUndo)
                                            TextButton.icon(
                                              onPressed: () {
                                                provider.undoLast();
                                                setState(() =>
                                                    _currentInput.clear());
                                              },
                                              icon: const Icon(Icons.undo,
                                                  size: 18),
                                              label: Text(s.calc_undo),
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets
                                                    .symmetric(horizontal: 8),
                                                tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                              ),
                                            ),
                                        ],
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
                                          s.calc_current_turn(currentInputStr),
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

                              // 추천 루트
                              if (provider.routes.isNotEmpty)
                                AppCard(
                                  margin: EdgeInsets.zero,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.lightbulb,
                                                color: Colors.amber, size: 26),
                                            const SizedBox(width: 10),
                                            Text(
                                              s.calc_recommend_title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // 최적 루트
                                        Text(
                                          provider.routes.first.primary
                                              .join(" → "),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        // 대안 루트
                                        if (provider.routes.first.alts
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            s.calc_alt_route,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          ...provider.routes.first.alts.map(
                                                (alt) => Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 16, top: 4),
                                              child: Text(
                                                "• ${alt.join(" → ")}",
                                                style: const TextStyle(
                                                    fontSize: 15),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // 하단 키패드
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
                              _buildKey(innerContext, '7'),
                              _buildKey(innerContext, '8'),
                              _buildKey(innerContext, '9'),
                              _buildKey(innerContext, '4'),
                              _buildKey(innerContext, '5'),
                              _buildKey(innerContext, '6'),
                              _buildKey(innerContext, '1'),
                              _buildKey(innerContext, '2'),
                              _buildKey(innerContext, '3'),
                              _buildKey(innerContext, 'backspace', isBackspace: true),
                              _buildKey(innerContext, '0'),
                              _buildKey(innerContext, 'confirm', isConfirm: true),
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