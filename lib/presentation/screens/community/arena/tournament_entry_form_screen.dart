// lib/presentation/screens/community/arena/tournament_entry_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class TournamentEntryFormScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentEntryFormScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentEntryFormScreen> createState() => _TournamentEntryFormScreenState();
}

class _TournamentEntryFormScreenState extends ConsumerState<TournamentEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameKoCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ratingCtrl = TextEditingController();
  final _homeShopCtrl = TextEditingController();

  TournamentModel? _tournament;
  bool _isLoading = false;
  bool _alreadyEntered = false;

  @override
  void initState() {
    super.initState();
    _loadTournament();
  }

  Future<void> _loadTournament() async {
    final tournament = await sl<ArenaRepository>().getTournament(widget.tournamentId);
    if (tournament != null && mounted) {
      setState(() => _tournament = tournament);
      _checkAlreadyEntered();
    }
  }

  Future<void> _checkAlreadyEntered() async {
    if (_tournament == null) return;
    final entries = await sl<ArenaRepository>().getEntries(_tournament!.id!).first;
    final uid = sl<FirebaseAuth>().currentUser!.uid;
    if (mounted) {
      setState(() => _alreadyEntered = entries.any((e) => e.userUid == uid));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final entry = TournamentEntryModel(
        userUid: sl<FirebaseAuth>().currentUser!.uid,
        nameKo: _nameKoCtrl.text.trim(),
        nameEn: _nameEnCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: sl<FirebaseAuth>().currentUser!.email,
        rating: _ratingCtrl.text.isEmpty ? null : _ratingCtrl.text,
        homeShop: _homeShopCtrl.text.isEmpty ? null : _homeShopCtrl.text,
        createdAt: Timestamp.now(),
      );

      await sl<ArenaRepository>().submitEntry(
        tournamentId: widget.tournamentId,
        entry: entry,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참가 신청 완료!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tournament == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_alreadyEntered) {
      return Scaffold(
        appBar: CommonAppBar(title: '참가 신청', showBackButton: true),
        body: const Center(child: Text('이미 참가 신청하셨습니다', style: TextStyle(fontSize: 18))),
      );
    }

    return Scaffold(
      appBar: CommonAppBar(title: _tournament!.title, showBackButton: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(_tournament!.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('참가 신청서를 작성해 주세요'),
            const SizedBox(height: 30),

            TextFormField(controller: _nameKoCtrl, decoration: const InputDecoration(labelText: '한글이름 *'), validator: (v) => v!.isEmpty ? '필수' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _nameEnCtrl, decoration: const InputDecoration(labelText: '영문이름 *'), validator: (v) => v!.isEmpty ? '필수' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: '연락처 *'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? '필수' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _ratingCtrl, decoration: const InputDecoration(labelText: '레이팅 (선택)')),
            const SizedBox(height: 16),
            TextFormField(controller: _homeShopCtrl, decoration: const InputDecoration(labelText: '홈샵 (선택)')),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('참가 신청 완료', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}