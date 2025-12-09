// lib/presentation/screens/training/training_rating_input_screen.dart
import 'package:flutter/material.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';

class TrainingRatingInputScreen extends StatefulWidget {
  const TrainingRatingInputScreen({super.key});

  @override
  State<TrainingRatingInputScreen> createState() =>
      _TrainingRatingInputScreenState();
}

class _TrainingRatingInputScreenState extends State<TrainingRatingInputScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Phoenix 입력
  final TextEditingController _phoenixPpdController = TextEditingController();
  final TextEditingController _phoenixMprController = TextEditingController();

  // Live 입력
  final TextEditingController _livePpdController = TextEditingController();
  final TextEditingController _liveMprController = TextEditingController();

  DaoTrainingProfile? _previewProfile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 실시간 미리보기
    final listener = () => _calculatePreview();
    _phoenixPpdController.addListener(listener);
    _phoenixMprController.addListener(listener);
    _livePpdController.addListener(listener);
    _liveMprController.addListener(listener);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoenixPpdController.dispose();
    _phoenixMprController.dispose();
    _livePpdController.dispose();
    _liveMprController.dispose();
    super.dispose();
  }

  void _calculatePreview() {
    final phoenixPpd = _parseDouble(_phoenixPpdController.text);
    final phoenixMpr = _parseDouble(_phoenixMprController.text);
    final livePpd = _parseDouble(_livePpdController.text);
    final liveMpr = _parseDouble(_liveMprController.text);

    setState(() {
      if (phoenixPpd != null ||
          phoenixMpr != null ||
          livePpd != null ||
          liveMpr != null) {
        _previewProfile = calculateDaoTrainingProfile(
          phoenixPpd: phoenixPpd,
          phoenixMpr: phoenixMpr,
          livePpd: livePpd,
          liveMpr: liveMpr,
        );
      } else {
        _previewProfile = null;
      }
    });
  }

  void _calculateAndReturn() {
    final phoenixPpd = _parseDouble(_phoenixPpdController.text);
    final phoenixMpr = _parseDouble(_phoenixMprController.text);
    final livePpd = _parseDouble(_livePpdController.text);
    final liveMpr = _parseDouble(_liveMprController.text);

    if (phoenixPpd == null &&
        phoenixMpr == null &&
        livePpd == null &&
        liveMpr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 한 가지 값을 입력해주세요.')),
      );
      return;
    }

    final profile = calculateDaoTrainingProfile(
      phoenixPpd: phoenixPpd,
      phoenixMpr: phoenixMpr,
      livePpd: livePpd,
      liveMpr: liveMpr,
    );

    Navigator.pop(context, profile);
  }

  double? _parseDouble(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.trim());
  }

  String _formatRating(double? rating) {
    if (rating == null) return "-";
    if (rating % 1 == 0) return rating.toInt().toString();
    return rating.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("실력 입력"),
        centerTitle: true,
        backgroundColor: Colors.grey[50],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.cyan,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.cyan,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.home_outlined), text: "PHOENIX"),
            Tab(icon: Icon(Icons.sports_esports_outlined), text: "DARTSLIVE"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInputForm(
            title: "PHOENIX (온라인/홈보드)",
            ppdController: _phoenixPpdController,
            mprController: _phoenixMprController,
            ppdHint: "예: 28.52",
            mprHint: "예: 3.29",
            icon: Icons.home,
            color: Colors.cyan,
          ),
          _buildInputForm(
            title: "DARTSLIVE",
            ppdController: _livePpdController,
            mprController: _liveMprController,
            ppdHint: "예: 89.98",
            mprHint: "예: 3.44",
            icon: Icons.gamepad,
            color: Colors.orange,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _calculateAndReturn,
        backgroundColor: Colors.cyan,
        icon: const Icon(Icons.check_circle),
        label: const Text("적용하기",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInputForm({
    required String title,
    required TextEditingController ppdController,
    required TextEditingController mprController,
    required String ppdHint,
    required String mprHint,
    required IconData icon,
    required Color color,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Text(title,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ]),
          const SizedBox(height: 16),
          Text(
            "PPD와 MPR을 모두 입력하면 가장 정확합니다.\n하나만 입력해도 대략적인 값을 계산합니다.",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          /// 🔹 PPD 입력
          TextFormField(
            controller: ppdController,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: "PPD",
              hintText: ppdHint,
              prefixIcon: Icon(Icons.trending_up, color: color),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          /// 🔹 MPR 입력 (색 통일!)
          TextFormField(
            controller: mprController,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: "MPR",
              hintText: mprHint,
              prefixIcon: Icon(Icons.speed, color: color), // ← 수정 포인트
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color, width: 2),
              ),
            ),
          ),

          // 실시간 Preview
          if (_previewProfile != null) ...[
            const SizedBox(height: 32),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.16),
                    color.withOpacity(0.06)
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.preview, color: color),
                    const SizedBox(width: 6),
                    const Text("실시간 계산 결과",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 16),
                  _previewRow("PHOENIX CLASS",
                      _formatRating(_previewProfile!.phoenixClass),
                      Colors.cyan),
                  _previewRow("DARTSLIVE RATING",
                      _formatRating(_previewProfile!.liveRating),
                      Colors.orange),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "DAO 티어: ${_previewProfile!.tier.labelKo}",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color.darken()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style:
            TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

// 색 약간 어둡게
extension ColorX on Color {
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark =
    hsl.withLightness((hsl.lightness - amount).clamp(0, 1));
    return hslDark.toColor();
  }
}
