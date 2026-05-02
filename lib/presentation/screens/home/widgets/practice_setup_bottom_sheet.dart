import 'package:flutter/material.dart';
import 'package:daoapp/data/models/practice_session_model.dart';
import 'package:daoapp/data/repositories/practice_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PracticeSetupBottomSheet extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PracticeSetupBottomSheet({super.key, required this.userData});

  @override
  State<PracticeSetupBottomSheet> createState() => _PracticeSetupBottomSheetState();
}

class _PracticeSetupBottomSheetState extends State<PracticeSetupBottomSheet> {
  final _shopController = TextEditingController();
  final _ratingController = TextEditingController();
  String _selectedMachine = '다트라이브';
  final List<String> _machines = ['다트라이브', '피닉스', '스틸', '홈보드', '그란보드'];

  bool get _isShopRequired => _selectedMachine == '다트라이브' || _selectedMachine == '피닉스';

  @override
  void dispose() {
    _shopController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  /// 연습 시작 로직
  Future<void> _start() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_isShopRequired && _shopController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('연습 중인 장소(샵 이름)를 입력해주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newSession = PracticeSessionModel(
      uid: user.uid,
      nickname: widget.userData['koreanName'] ?? '이름 없음',
      profileUrl: widget.userData['profileImageUrl'],
      startTime: DateTime.now(),
      machineType: _selectedMachine,
      shopName: _isShopRequired ? _shopController.text.trim() : _selectedMachine,
      // ✅ 텍스트 형태의 자유 목표 저장
      targetGoal: _ratingController.text.trim(),
      isActive: true,
    );

    try {
      await sl<PracticeRepository>().startPractice(newSession);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('시작 오류: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // 키보드 대응
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '기록 시작',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '오늘의 연습 환경을 설정하고 기록을 시작하세요.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 28),

                      // 1. 머신 선택
                      _buildLabel('사용 머신'),
                      const SizedBox(height: 12),
                      _buildMachineChips(),
                      const SizedBox(height: 28),

                      // 2. 장소 입력 (필요시)
                      if (_isShopRequired) ...[
                        _buildLabel('연습 장소'),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _shopController,
                          hint: '예: PDK 스타디움, 다트하이브',
                          icon: Icons.location_on_rounded,
                        ),
                        const SizedBox(height: 28),
                      ],

                      // 3. 연습 목표 (자유 텍스트)
                      _buildLabel('오늘의 연습 목표 (선택)'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _ratingController,
                        hint: '예: 불 100발, 레이팅 15, 3시간 연습 등',
                        icon: Icons.track_changes_rounded,
                        keyboardType: TextInputType.text, // 텍스트 타입 확인
                      ),
                      const SizedBox(height: 32),

                      // 4. 시작 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _start,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '연습 기록 시작하기',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Color(0xFF475569),
    ),
  );

  Widget _buildMachineChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _machines.map((m) {
        final isSelected = _selectedMachine == m;
        return InkWell(
          onTap: () => setState(() => _selectedMachine = m),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
              ),
            ),
            child: Text(
              m,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1),
        ),
      ),
    );
  }
}