// lib/presentation/screens/arena/tournament_entry_form_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // ← 이거 추가!! (Timestamp 때문에)
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TournamentEntryFormScreen extends StatefulWidget {
  final String tournamentId;
  const TournamentEntryFormScreen({Key? key, required this.tournamentId}) : super(key: key);

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('참가 신청')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nameKoController, decoration: const InputDecoration(labelText: '한글 이름 *'), validator: (v) => v!.isEmpty ? '필수' : null),
              TextFormField(controller: _nameEnController, decoration: const InputDecoration(labelText: '영문 이름 *'), validator: (v) => v!.isEmpty ? '필수' : null),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: '연락처 *'), validator: (v) => v!.isEmpty ? '필수' : null),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: '이메일')),
              TextFormField(controller: _ratingController, decoration: const InputDecoration(labelText: '레이팅')),
              TextFormField(controller: _homeShopController, decoration: const InputDecoration(labelText: '홈샵')),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('등록하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final entry = TournamentEntryModel(
        userUid: sl<FirebaseAuth>().currentUser?.uid,
        nameKo: _nameKoController.text,
        nameEn: _nameEnController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        rating: _ratingController.text,
        homeShop: _homeShopController.text,
        createdAt: Timestamp.now(),  // 이제 정상 인식!!
      );

      await _repo.submitEntry(tournamentId: widget.tournamentId, entry: entry);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('참가 신청 완료!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}