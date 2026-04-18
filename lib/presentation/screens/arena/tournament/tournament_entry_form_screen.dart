// lib/presentation/screens/arena/tournament/tournament_entry_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/utils/arena_utils.dart';

class TournamentEntryFormScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentEntryFormScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  ConsumerState<TournamentEntryFormScreen> createState() =>
      _TournamentEntryFormScreenState();
}

class _TournamentEntryFormScreenState
    extends ConsumerState<TournamentEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameKoCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ratingCtrl = TextEditingController();
  final _homeShopCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameKoCtrl.dispose();
    _nameEnCtrl.dispose();
    _phoneCtrl.dispose();
    _ratingCtrl.dispose();
    _homeShopCtrl.dispose();
    super.dispose();
  }

  void _showSnack(BuildContext context, String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit(String tid, User user) async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final entry = TournamentEntryModel(
        userUid: user.uid,
        nameKo: _nameKoCtrl.text.trim(),
        nameEn: _nameEnCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: user.email,
        rating: _ratingCtrl.text.trim().isEmpty ? null : _ratingCtrl.text.trim(),
        homeShop: _homeShopCtrl.text.trim().isEmpty ? null : _homeShopCtrl.text.trim(),
        createdAt: Timestamp.now(),
        // isPaid 필드는 서버/관리자에서 처리하므로 초기값은 false(또는 미포함)
      );

      await sl<ArenaRepository>().submitEntry(tournamentId: tid, entry: entry);

      if (!mounted) return;
      _showSnack(context, '참가 신청 완료!', success: true);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack(context, '신청 실패: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _cancelEntry(String tid, User user) async {
    if (_isSubmitting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('참가 취소', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('참가 신청을 취소하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('아니오')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('취소하기', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      await sl<ArenaRepository>().cancelEntry(tournamentId: tid, userUid: user.uid);
      if (!mounted) return;
      _showSnack(context, '신청이 취소되었습니다.', success: true);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack(context, '취소 실패: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = sl<FirebaseAuth>().currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: const CommonAppBar(title: '참가 신청', showBackButton: true),
        body: const Center(child: Text('로그인이 필요합니다.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: '참가 신청', showBackButton: true),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).snapshots(),
        builder: (context, tSnap) {
          if (!tSnap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyan));
          if (!tSnap.data!.exists) return const Center(child: Text("대회를 찾을 수 없습니다."));

          final tournament = TournamentModel.fromJson(tSnap.data!.data()!).copyWith(id: tSnap.data!.id);

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).collection('entries').doc(user.uid).snapshots(),
            builder: (context, mySnap) {
              final alreadyEntered = mySnap.hasData && mySnap.data!.exists;
              final entryData = alreadyEntered ? mySnap.data!.data() as Map<String, dynamic> : null;
              final bool isPaid = entryData?['isPaid'] ?? false;

              if (alreadyEntered) {
                return _buildAlreadyEnteredUI(tournament, user, isPaid);
              }

              return _buildFormUI(tournament, user);
            },
          );
        },
      ),
    );
  }

  // --- 1. 이미 신청한 경우 UI ---
  Widget _buildAlreadyEnteredUI(TournamentModel t, User user, bool isPaid) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPaid ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
            size: 80,
            color: isPaid ? Colors.cyan : Colors.orangeAccent,
          ),
          const SizedBox(height: 24),
          Text(
            isPaid ? '입금 확인 완료!' : '신청 접수 완료',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            isPaid
                ? '참가비 입금이 확인되었습니다.\n대회 당일 현장에서 뵙겠습니다!'
                : '신청서가 정상 접수되었습니다.\n주최자가 입금을 확인하면 "입금완료"로 변경됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 40),
          if (!isPaid)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => _cancelEntry(t.id!, user),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("참가 신청 취소하기", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  // --- 2. 참가 신청 폼 UI (깨끗한 빈 값 시작) ---
  Widget _buildFormUI(TournamentModel t, User user) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(t.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text("참가 신청 정보를 입력해 주세요.", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          const SizedBox(height: 24),

          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildField("한글 성함 *", _nameKoCtrl, Icons.person_outline),
                const SizedBox(height: 16),
                _buildField("영문 성함 *", _nameEnCtrl, Icons.language_outlined),
                const SizedBox(height: 16),
                _buildField("연락처 *", _phoneCtrl, Icons.phone_android_outlined, isPhone: true),
                const SizedBox(height: 16),
                _buildField("레이팅 (선택)", _ratingCtrl, Icons.star_outline),
                const SizedBox(height: 16),
                _buildField("홈샵 (선택)", _homeShopCtrl, Icons.home_work_outlined),
              ],
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isSubmitting ? null : () => _submit(t.id!, user),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan[700],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("참가 신청 완료", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {bool isPhone = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[400]),
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.cyan)),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) && label.contains('*') ? '필수 입력 항목입니다.' : null,
    );
  }
}