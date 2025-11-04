// lib/presentation/screens/admin/member_register_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class MemberRegisterScreen extends StatefulWidget {
  const MemberRegisterScreen({super.key}); // const 추가!

  @override
  State<MemberRegisterScreen> createState() => _MemberRegisterScreenState();
}

class _MemberRegisterScreenState extends State<MemberRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _koreanNameController = TextEditingController();
  final _englishNameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _koreanNameController.dispose();
    _englishNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _registerMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').add({
        'koreanName': _koreanNameController.text.trim(),
        'englishName': _englishNameController.text.trim(),
        'email': _emailController.text.trim(),
        'isOfficialMember': true,
        'totalPoints': 0,
        'registeredAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KDF 정회원 등록 완료!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KDF 정회원 등록'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 한국 이름
                  TextFormField(
                    controller: _koreanNameController,
                    decoration: const InputDecoration(
                      labelText: '한국 이름 (필수)',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.trim().isEmpty ? '한국 이름을 입력하세요' : null,
                  ),
                  const SizedBox(height: 12),

                  // 영어 이름
                  TextFormField(
                    controller: _englishNameController,
                    decoration: const InputDecoration(
                      labelText: '영어 이름 (필수)',
                      prefixIcon: Icon(Icons.translate),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.trim().isEmpty ? '영어 이름을 입력하세요' : null,
                  ),
                  const SizedBox(height: 12),

                  // 이메일
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 등록 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _registerMember,
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.how_to_reg),
                      label: Text(_isLoading ? '등록 중...' : '정회원 등록'),
                      style: theme.elevatedButtonTheme.style,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}