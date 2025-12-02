// lib/presentation/screens/training/board_level_test_screen.dart
import 'package:flutter/material.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';

class BoardLevelTestScreen extends StatefulWidget {
  const BoardLevelTestScreen({super.key});

  @override
  State<BoardLevelTestScreen> createState() => _BoardLevelTestScreenState();
}

class _BoardLevelTestScreenState extends State<BoardLevelTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dartsController = TextEditingController();

  DaoTrainingTier? _previewTier;

  @override
  void dispose() {
    _dartsController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final text = _dartsController.text.trim();
    if (text.isEmpty) {
      setState(() => _previewTier = null);
      return;
    }

    final darts = int.tryParse(text);
    if (darts != null && darts > 0) {
      setState(() {
        _previewTier = tierFromBoardTest(darts);
      });
    } else {
      setState(() => _previewTier = null);
    }
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final dartsUsed = int.parse(_dartsController.text.trim());
    final profile = calculateDaoTrainingProfile(boardTestDarts: dartsUsed);

    Navigator.pop(context, profile);
  }

  @override
  void initState() {
    super.initState();
    _dartsController.addListener(_updatePreview);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("보드 마킹 레벨 테스트"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            const Text(
              "다트 보드 마킹 정확도 테스트",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "다트 보드를 정면으로 바라보고 1번부터 20번까지 순서대로 맞추는 테스트입니다.\n"
                  "실패하면 그 숫자만 다시 시도하며, 20번까지 완료할 때까지 던진 총 다트 수를 기록하세요.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // 기준표 (7티어)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.cyan.withOpacity(0.1),
                    Colors.orange.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.cyan.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    "DAO 공식 마킹 레벨 기준",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 🔹 tierFromBoardTest( )와 맞춘 구간
                  _buildTierRow("마스터", "≤ 24발", _getTierColor(DaoTrainingTier.master)),
                  _buildTierRow("프로", "25~28발", _getTierColor(DaoTrainingTier.pro)),
                  _buildTierRow("엘리트", "29~33발", _getTierColor(DaoTrainingTier.elite)),
                  _buildTierRow("챌린저", "34~42발", _getTierColor(DaoTrainingTier.challenger)),
                  _buildTierRow("컴페티터", "43~55발", _getTierColor(DaoTrainingTier.competitor)),
                  _buildTierRow("러너", "56~70발", _getTierColor(DaoTrainingTier.learner)),
                  _buildTierRow("비기너", "71발 이상", _getTierColor(DaoTrainingTier.beginner)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 입력 폼
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _dartsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: "총 사용한 다트 수",
                  hintText: "예: 28",
                  prefixIcon: const Icon(
                    Icons.sports_handball,
                    color: Colors.cyan,
                  ),
                  suffixIcon: _dartsController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _dartsController.clear();
                      setState(() => _previewTier = null);
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.cyan,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return "다트 수를 입력해주세요";
                  }
                  final v = int.tryParse(value!.trim());
                  if (v == null || v <= 0) {
                    return "1 이상의 숫자를 입력해주세요";
                  }
                  if (v > 300) {
                    return "너무 많은 다트 수입니다. 다시 확인해주세요";
                  }
                  return null;
                },
              ),
            ),

            // 실시간 미리보기
            if (_previewTier != null) ...[
              const SizedBox(height: 24),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _getTierColor(_previewTier!).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getTierColor(_previewTier!),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getTierColor(_previewTier!).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "예상 DAO 티어",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _previewTier!.labelKo,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: _getTierColor(_previewTier!),
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      _previewTier!.labelEn,
                      style: TextStyle(
                        fontSize: 20,
                        color:
                        _getTierColor(_previewTier!).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),

            // 계산 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.flag, size: 28),
                label: const Text(
                  "DAO 티어 확정하기",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Center(
              child: Text(
                "결과는 트레이닝 홈에 바로 반영됩니다",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierRow(String tier, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            tier,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            range,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(DaoTrainingTier tier) {
    return switch (tier) {
      DaoTrainingTier.master => Colors.deepPurpleAccent,
      DaoTrainingTier.pro => Colors.redAccent,
      DaoTrainingTier.elite => Colors.orange,
      DaoTrainingTier.challenger => Colors.green,
      DaoTrainingTier.competitor => Colors.teal,
      DaoTrainingTier.learner => Colors.blue,
      DaoTrainingTier.beginner => Colors.grey,
    };
  }
}
