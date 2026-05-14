import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/data/models/practice_session_model.dart';
import 'package:daoapp/data/repositories/practice_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class PracticeSetupBottomSheet extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PracticeSetupBottomSheet({super.key, required this.userData});

  @override
  State<PracticeSetupBottomSheet> createState() => _PracticeSetupBottomSheetState();
}

class _PracticeSetupBottomSheetState extends State<PracticeSetupBottomSheet> {
  final _shopController = TextEditingController();
  final _ratingController = TextEditingController();
  String _selectedMachine = 'DARTSLIVE';

  // 머신 이름은 고유 명사이므로 리스트는 그대로 유지하되,
  // UI 노출 시 필요하다면 번역 로직을 넣을 수 있습니다.
  final List<String> _machines = ['DARTSLIVE', 'PHOENIXDARTS', 'STEEL', 'DARTSLIVE HOME', 'GRAN BOARD'];

  bool get _isShopRequired => _selectedMachine == 'DARTSLIVE' || _selectedMachine == 'PHOENIXDARTS';

  @override
  void dispose() {
    _shopController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final s = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_isShopRequired && _shopController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.practice_setup_error_location), // 🔹 다국어화
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newSession = PracticeSessionModel(
      uid: user.uid,
      nickname: widget.userData['koreanName'] ?? 'Guest',
      profileUrl: widget.userData['profileImageUrl'],
      startTime: DateTime.now(),
      machineType: _selectedMachine,
      shopName: _isShopRequired ? _shopController.text.trim() : _selectedMachine,
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
            content: Text(s.practice_setup_error_start(e.toString())), // 🔹 다국어화
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
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
                          Text(
                            s.practice_setup_title, // 🔹 다국어화
                            style: const TextStyle(
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
                      Text(
                        s.practice_setup_sub, // 🔹 다국어화
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 28),

                      _buildLabel(s.practice_setup_machine), // 🔹 다국어화
                      const SizedBox(height: 12),
                      _buildMachineChips(),
                      const SizedBox(height: 28),

                      if (_isShopRequired) ...[
                        _buildLabel(s.practice_setup_location), // 🔹 다국어화
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _shopController,
                          hint: s.practice_setup_location_hint, // 🔹 다국어화
                          icon: Icons.location_on_rounded,
                        ),
                        const SizedBox(height: 28),
                      ],

                      _buildLabel(s.practice_setup_goal), // 🔹 다국어화
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _ratingController,
                        hint: s.practice_setup_goal_hint, // 🔹 다국어화
                        icon: Icons.track_changes_rounded,
                      ),
                      const SizedBox(height: 32),

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
                          child: Text(
                            s.practice_setup_btn_start, // 🔹 다국어화
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              m, // 🔹 머신 이름은 고유 명사로 취급
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