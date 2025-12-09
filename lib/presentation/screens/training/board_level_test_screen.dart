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

  DaoTrainingProfile? _previewProfile;

  @override
  void initState() {
    super.initState();
    _dartsController.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _dartsController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final text = _dartsController.text.trim();
    if (text.isEmpty) {
      setState(() => _previewProfile = null);
      return;
    }

    final darts = int.tryParse(text);
    if (darts == null || darts <= 0) {
      setState(() => _previewProfile = null);
      return;
    }

    setState(() {
      _previewProfile = calculateDaoTrainingProfile(boardTestDarts: darts);
    });
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final dartsUsed = int.parse(_dartsController.text.trim());
    final profile = calculateDaoTrainingProfile(boardTestDarts: dartsUsed);
    Navigator.pop(context, profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("보드 마킹 레벨 테스트"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.grey[50],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "다트 보드 마킹 정확도 테스트",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "1번부터 20번까지 순서대로 명중하며,\n"
                  "총 몇 발이 들었는지 입력해주세요.",
              style: TextStyle(color: Colors.grey[700], height: 1.4),
            ),
            const SizedBox(height: 32),

            _buildTierGuideCard(),

            const SizedBox(height: 32),
            _buildInputForm(),

            if (_previewProfile != null) ...[
              const SizedBox(height: 32),
              _buildPreviewCard(),
            ],

            const SizedBox(height: 40),
            _buildActionButton(),
            const SizedBox(height: 12),
            const Center(
              child: Text("결과는 트레이닝 홈에 바로 반영됩니다",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  /// DAO 7티어 기준표
  Widget _buildTierGuideCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyan.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          const Text("DAO 공식 마킹 레벨 기준",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          _buildTierRow("마스터", "≤ 24발", _tierColor(DaoTrainingTier.master)),
          _buildTierRow("프로", "25~28발", _tierColor(DaoTrainingTier.pro)),
          _buildTierRow("엘리트", "29~33발", _tierColor(DaoTrainingTier.elite)),
          _buildTierRow("챌린저", "34~42발", _tierColor(DaoTrainingTier.challenger)),
          _buildTierRow("컴페티터", "43~55발", _tierColor(DaoTrainingTier.competitor)),
          _buildTierRow("러너", "56~70발", _tierColor(DaoTrainingTier.learner)),
          _buildTierRow("비기너", "71발 이상", _tierColor(DaoTrainingTier.beginner)),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return Form(
      key: _formKey,
      child: TextFormField(
        controller: _dartsController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: "총 사용한 다트 수",
          hintText: "예: 28",
          prefixIcon: const Icon(Icons.sports_handball, color: Colors.cyan),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.cyan, width: 2),
          ),
        ),
        validator: (value) {
          if ((value ?? '').trim().isEmpty) return "다트 수를 입력해주세요";
          final v = int.tryParse(value!.trim());
          if (v == null || v <= 0) return "1 이상의 숫자를 입력해주세요";
          if (v > 300) return "너무 많은 다트 수입니다. 다시 확인해주세요";
          return null;
        },
      ),
    );
  }

  /// 실시간 미리보기
  Widget _buildPreviewCard() {
    final tier = _previewProfile!.tier;
    final color = _tierColor(tier);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 3),
      ),
      child: Column(
        children: [
          const Text("예상 DAO 티어", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          Text(tier.labelKo,
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color)),
          Text(tier.labelEn,
              style: TextStyle(fontSize: 18, color: color.withOpacity(0.7))),
        ],
      ),
    );
  }

  /// 확정 버튼
  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.flag, size: 26),
        label: const Text("DAO 티어 확정하기",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
        ),
      ),
    );
  }

  Widget _buildTierRow(String label, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(range, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Color _tierColor(DaoTrainingTier tier) {
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
