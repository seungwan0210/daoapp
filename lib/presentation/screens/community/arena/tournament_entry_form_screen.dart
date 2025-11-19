// lib/presentation/screens/arena/tournament_entry_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TournamentEntryFormScreen extends StatefulWidget {
  final String tournamentId;
  const TournamentEntryFormScreen({super.key, required this.tournamentId});

  @override
  State<TournamentEntryFormScreen> createState() => _TournamentEntryFormScreenState();
}

class _TournamentEntryFormScreenState extends State<TournamentEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameKoController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _ratingController = TextEditingController();
  final _homeShopController = TextEditingController();

  bool _isLoading = false;
  final _repo = sl<ArenaRepository>();

  @override
  void initState() {
    super.initState();
    // 현재 사용자 이메일 자동 입력 (편의성 UP!)
    final user = sl<FirebaseAuth>().currentUser;
    if (user?.email != null) {
      _emailController.text = user!.email!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('참가 신청'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    '참가 정보를 입력해주세요',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('필수 항목은 * 표시되어 있습니다', style: TextStyle(color: Colors.grey[600])),

                  const SizedBox(height: 32),

                  // 한글 이름
                  TextFormField(
                    controller: _nameKoController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: '한글 이름 *',
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    validator: (v) => v?.trim().isEmpty ?? true ? '한글 이름을 입력해주세요' : null,
                  ),
                  const SizedBox(height: 16),

                  // 영문 이름
                  TextFormField(
                    controller: _nameEnController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: '영문 이름 (대문자) *',
                      prefixIcon: const Icon(Icons.abc),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      hintText: '예: HONG GILDONG',
                    ),
                    validator: (v) => v?.trim().isEmpty ?? true ? '영문 이름을 입력해주세요' : null,
                  ),
                  const SizedBox(height: 16),

                  // 연락처 (자동 하이픈)
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneInputFormatter()],
                    decoration: InputDecoration(
                      labelText: '연락처 *',
                      prefixIcon: const Icon(Icons.phone),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      hintText: '010-1234-5678',
                    ),
                    validator: (v) {
                      if (v?.trim().isEmpty ?? true) return '연락처를 입력해주세요';
                      if (!RegExp(r'^010-\d{4}-\d{4}$').hasMatch(v!)) return '올바른 형식으로 입력해주세요';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 이메일
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: '이메일',
                      prefixIcon: const Icon(Icons.email),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 레이팅
                  TextFormField(
                    controller: _ratingController,
                    decoration: InputDecoration(
                      labelText: '레이팅 (선택)',
                      prefixIcon: const Icon(Icons.star),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      hintText: '예: 2500',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // 홈샵
                  TextFormField(
                    controller: _homeShopController,
                    decoration: InputDecoration(
                      labelText: '홈샵 (선택)',
                      prefixIcon: const Icon(Icons.store),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      hintText: '예: 강남 당구장',
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 참가하기 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Icon(Icons.how_to_reg, size: 28),
                      label: Text(
                        _isLoading ? '신청 중...' : '참가 신청하기',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: Colors.green.withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // 로딩 오버레이
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white, strokeWidth: 5),
                    SizedBox(height: 24),
                    Text('참가 신청 중...', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final entry = TournamentEntryModel(
        userUid: sl<FirebaseAuth>().currentUser?.uid,
        nameKo: _nameKoController.text.trim(),
        nameEn: _nameEnController.text.trim().toUpperCase(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        rating: _ratingController.text.trim().isEmpty ? null : _ratingController.text.trim(),
        homeShop: _homeShopController.text.trim().isEmpty ? null : _homeShopController.text.trim(),
        createdAt: Timestamp.now(),
      );

      await _repo.submitEntry(tournamentId: widget.tournamentId, entry: entry);

      if (!mounted) return;

      // 성공 애니메이션 + 팝업
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('참가 신청이 완료되었습니다!'),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e'), backgroundColor: Colors.red[600]),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameKoController.dispose();
    _nameEnController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ratingController.dispose();
    _homeShopController.dispose();
    super.dispose();
  }
}

// 한국식 전화번호 자동 하이픈 포맷터
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('-', '');
    if (text.length > 11) text = text.substring(0, 11);

    if (text.length >= 11) {
      text = '${text.substring(0, 3)}-${text.substring(3, 7)}-${text.substring(7, 11)}';
    } else if (text.length >= 7) {
      text = '${text.substring(0, 3)}-${text.substring(3, 7)}-${text.substring(7)}';
    } else if (text.length >= 3) {
      text = '${text.substring(0, 3)}-${text.substring(3)}';
    }

    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}