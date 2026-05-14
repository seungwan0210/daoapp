// lib/presentation/screens/training/board_level_test_screen.dart
import 'package:flutter/material.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 임포트 추가

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

  // 🔹 티어 라벨 다국어 헬퍼
  String _getTierLabel(DaoTrainingTier tier) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'en') return tier.labelEn;
    if (locale.languageCode == 'ja') return tier.labelJa;
    if (locale.languageCode == 'zh') {
      return locale.scriptCode == 'Hant' ? tier.labelZhHant : tier.labelZhHans;
    }
    return tier.labelKo;
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
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tier_test_title), // 🔹 다국어화
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.grey[50],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.tier_test_headline, // 🔹 다국어화
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              s.tier_test_desc, // 🔹 다국어화
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
            Center(
              child: Text(s.tier_test_result_notice, // 🔹 다국어화
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  /// DAO 7티어 기준표
  Widget _buildTierGuideCard() {
    final s = AppLocalizations.of(context)!;
    // 다트 단위 (발 / darts)
    final String unit = s.drill_stat_darts;

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
          Text(s.tier_test_guide_title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          _buildTierRow(_getTierLabel(DaoTrainingTier.master), "≤ 24$unit", _tierColor(DaoTrainingTier.master)),
          _buildTierRow(_getTierLabel(DaoTrainingTier.pro), "25~28$unit", _tierColor(DaoTrainingTier.pro)),
          _buildTierRow(_getTierLabel(DaoTrainingTier.elite), "29~33$unit", _tierColor(DaoTrainingTier.elite)),
          _buildTierRow(_getTierLabel(DaoTrainingTier.challenger), "34~42$unit", _tierColor(DaoTrainingTier.challenger)),
          _buildTierRow(_getTierLabel(DaoTrainingTier.competitor), "43~55$unit", _tierColor(DaoTrainingTier.competitor)),
          _buildTierRow(_getTierLabel(DaoTrainingTier.learner), "56~70$unit", _tierColor(DaoTrainingTier.learner)),
          _buildTierRow(_getTierLabel(DaoTrainingTier.beginner), "71$unit ~", _tierColor(DaoTrainingTier.beginner)),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    final s = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: TextFormField(
        controller: _dartsController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: s.tier_test_input_label,
          hintText: s.tier_test_input_hint,
          prefixIcon: const Icon(Icons.sports_handball, color: Colors.cyan),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.cyan, width: 2),
          ),
        ),
        validator: (value) {
          if ((value ?? '').trim().isEmpty) return s.tier_test_err_empty;
          final v = int.tryParse(value!.trim());
          if (v == null || v <= 0) return s.tier_test_err_invalid;
          if (v > 300) return s.tier_test_err_too_many;
          return null;
        },
      ),
    );
  }

  /// 실시간 미리보기
  Widget _buildPreviewCard() {
    final s = AppLocalizations.of(context)!;
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
          Text(s.tier_predict_label, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          Text(_getTierLabel(tier),
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color)),
          // 영어 라벨은 디자인 포인트로 작게 유지
          Text(tier.labelEn,
              style: TextStyle(fontSize: 14, color: color.withOpacity(0.7))),
        ],
      ),
    );
  }

  /// 확정 버튼
  Widget _buildActionButton() {
    final s = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.flag, size: 26),
        label: Text(s.tier_test_btn_confirm,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
      DaoTrainingTier.beginner => const Color(0xFFFF8EC7),
    };
  }
}