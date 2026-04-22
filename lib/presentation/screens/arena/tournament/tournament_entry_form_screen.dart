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

class TournamentEntryFormScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final bool isManualMode; // ✅ [추가] 수동 등록 모드 여부

  const TournamentEntryFormScreen({
    super.key,
    required this.tournamentId,
    this.isManualMode = false, // ✅ 기본값은 일반 신청(false)
  });

  @override
  ConsumerState<TournamentEntryFormScreen> createState() =>
      _TournamentEntryFormScreenState();
}

class _TournamentEntryFormScreenState
    extends ConsumerState<TournamentEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // 대표자(팀장) 정보
  final _teamNameCtrl = TextEditingController();
  final _nameKoCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ratingCtrl = TextEditingController();
  final _homeShopCtrl = TextEditingController();

  final Map<String, TextEditingController> _leaderCustomCtrls = {};
  final List<Map<String, TextEditingController>> _memberCustomCtrls = [];

  List<TextEditingController> _memberNames = [];
  List<TextEditingController> _memberRatings = [];

  bool _isSubmitting = false;
  int _currentTeamSize = 2;

  @override
  void dispose() {
    _teamNameCtrl.dispose(); _nameKoCtrl.dispose(); _nameEnCtrl.dispose();
    _phoneCtrl.dispose(); _ratingCtrl.dispose(); _homeShopCtrl.dispose();
    _leaderCustomCtrls.forEach((_, ctrl) => ctrl.dispose());
    for (var c in _memberNames) c.dispose();
    for (var c in _memberRatings) c.dispose();
    for (var map in _memberCustomCtrls) { map.forEach((_, ctrl) => ctrl.dispose()); }
    super.dispose();
  }

  void _showSnack(BuildContext context, String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: success ? Colors.green : Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  void _updateMemberCount(int delta, int maxTeamSize, List<String> questions) {
    setState(() {
      int newCount = _currentTeamSize + delta;
      if (newCount >= 2 && newCount <= maxTeamSize) {
        _currentTeamSize = newCount;
        if (delta > 0) {
          _memberNames.add(TextEditingController());
          _memberRatings.add(TextEditingController());
          final Map<String, TextEditingController> newMap = {};
          for (var q in questions) { newMap[q] = TextEditingController(); }
          _memberCustomCtrls.add(newMap);
        } else {
          _memberNames.removeLast().dispose();
          _memberRatings.removeLast().dispose();
          final removedMap = _memberCustomCtrls.removeLast();
          removedMap.forEach((_, ctrl) => ctrl.dispose());
        }
      }
    });
  }

  void _initControllers(TournamentModel t) {
    if (_memberNames.isNotEmpty || _leaderCustomCtrls.isNotEmpty) return;
    for (var q in t.customQuestions) { _leaderCustomCtrls[q] = TextEditingController(); }
    if (t.type == 'team') {
      _memberNames.add(TextEditingController());
      _memberRatings.add(TextEditingController());
      final Map<String, TextEditingController> firstMemberMap = {};
      for (var q in t.customQuestions) { firstMemberMap[q] = TextEditingController(); }
      _memberCustomCtrls.add(firstMemberMap);
    }
  }

  Future<void> _submit(TournamentModel t, User user) async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final Map<String, String> leaderAnswers = {};
      _leaderCustomCtrls.forEach((key, ctrl) { leaderAnswers[key] = ctrl.text.trim(); });

      List<TeamMember> members = [];
      int totalRating = int.tryParse(_ratingCtrl.text) ?? 0;

      if (t.type == 'team') {
        for (int i = 0; i < _memberNames.length; i++) {
          final Map<String, String> memberAnswers = {};
          _memberCustomCtrls[i].forEach((key, ctrl) { memberAnswers[key] = ctrl.text.trim(); });
          members.add(TeamMember(
            name: _memberNames[i].text.trim(),
            rating: _memberRatings[i].text.trim(),
            customAnswers: memberAnswers,
          ));
          totalRating += int.tryParse(_memberRatings[i].text) ?? 0;
        }
      }

      // 🎯 [수정] 수동 모드 데이터 반영
      final entry = TournamentEntryModel(
        userUid: user.uid, // 주최자의 UID가 들어가지만 Repository에서 분기됨
        nameKo: _nameKoCtrl.text.trim(),
        nameEn: _nameEnCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: widget.isManualMode ? "offline@manual.entry" : user.email, // ✅ 수동은 임시 메일
        rating: _ratingCtrl.text.trim().isEmpty ? null : _ratingCtrl.text.trim(),
        homeShop: _homeShopCtrl.text.trim().isEmpty ? null : _homeShopCtrl.text.trim(),
        teamName: t.type == 'team' ? _teamNameCtrl.text.trim() : null,
        members: members,
        totalRating: t.type == 'team' ? totalRating.toString() : null,
        customAnswers: leaderAnswers,
        isManual: widget.isManualMode, // ✅ 수동 여부
        registeredBy: widget.isManualMode ? user.uid : null, // ✅ 주최자 기록
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        status: widget.isManualMode ? 'confirmed' : 'applied', // ✅ 수동은 즉시 확정
      );

      await sl<ArenaRepository>().submitEntry(tournamentId: t.id!, entry: entry);

      if (!mounted) return;
      _showSnack(context, widget.isManualMode ? '수동 등록이 완료되었습니다.' : '참가 신청 완료!', success: true);
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
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('취소하기', style: TextStyle(color: Colors.redAccent))),
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
      return const Scaffold(backgroundColor: Colors.white, appBar: CommonAppBar(title: '참가 신청', showBackButton: true), body: Center(child: Text('로그인이 필요합니다.')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: widget.isManualMode ? '오프라인 참가자 추가' : '참가 신청', showBackButton: true),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).snapshots(),
        builder: (context, tSnap) {
          if (!tSnap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyan));
          if (!tSnap.data!.exists) return const Center(child: Text("대회를 찾을 수 없습니다."));

          final tournament = TournamentModel.fromJson(tSnap.data!.data()!).copyWith(id: tSnap.data!.id);
          _initControllers(tournament);

          // 🎯 [수정] 수동 모드일 때는 '이미 신청함' UI를 띄우지 않고 바로 폼으로 보냄
          if (widget.isManualMode) {
            return _buildFormUI(tournament, user);
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).collection('entries').doc(user.uid).snapshots(),
            builder: (context, mySnap) {
              final alreadyEntered = mySnap.hasData && mySnap.data!.exists;
              final entryData = alreadyEntered ? mySnap.data!.data() as Map<String, dynamic> : null;
              final bool isPaid = entryData?['isPaid'] ?? false;

              if (alreadyEntered) return _buildAlreadyEnteredUI(tournament, user, isPaid);
              return _buildFormUI(tournament, user);
            },
          );
        },
      ),
    );
  }

  Widget _buildAlreadyEnteredUI(TournamentModel t, User user, bool isPaid) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isPaid ? Icons.check_circle_rounded : Icons.pending_actions_rounded, size: 80, color: isPaid ? Colors.cyan : Colors.orangeAccent),
          const SizedBox(height: 24),
          Text(isPaid ? '입금 확인 완료!' : '신청 접수 완료', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(isPaid ? '참가비 입금이 확인되었습니다.\n대회 당일 현장에서 뵙겠습니다!' : '신청서가 정상 접수되었습니다.\n주최자가 입금을 확인하면 "입금완료"로 변경됩니다.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], height: 1.5, fontSize: 14)),
          const SizedBox(height: 40),
          if (!isPaid) SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _isSubmitting ? null : () => _cancelEntry(t.id!, user), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("참가 신청 취소하기", style: TextStyle(fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  Widget _buildFormUI(TournamentModel t, User user) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          // ✅ 수동 등록 시 주최자 전용 안내 배너
          if (widget.isManualMode)
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 20),
              color: Colors.cyan.shade50,
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.cyan.shade700, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(child: Text("주최자 권한으로 외부 참가자를 등록합니다.\n입력한 정보는 실시간 명단에 즉시 반영됩니다.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87))),
                ],
              ),
            ),

          Text(t.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(t.type == 'team' ? "팀 참가 신청 정보를 입력해 주세요." : "개인 참가 신청 정보를 입력해 주세요.", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          const SizedBox(height: 24),

          Text(t.type == 'team' ? "팀장 정보" : "내 정보", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (t.type == 'team') ...[ _buildField("팀명 *", _teamNameCtrl, Icons.groups_outlined), const SizedBox(height: 16), ],
                _buildField("이름(한글) *", _nameKoCtrl, Icons.person_outline),
                const SizedBox(height: 16),
                _buildField("이름(영문) *", _nameEnCtrl, Icons.language_outlined),
                const SizedBox(height: 16),
                _buildField("연락처 *", _phoneCtrl, Icons.phone_android_outlined, isPhone: true),
                const SizedBox(height: 16),
                _buildField("레이팅 (선택)", _ratingCtrl, Icons.star_outline, isPhone: true),
                const SizedBox(height: 16),
                _buildField("홈샵 (선택)", _homeShopCtrl, Icons.home_work_outlined),
                if (t.customQuestions.isNotEmpty) ...[ const Divider(height: 32), ...t.customQuestions.map((q) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildField(q, _leaderCustomCtrls[q]!, Icons.help_outline))) ],
              ],
            ),
          ),

          if (t.type == 'team') ...[
            const SizedBox(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("팀원 정보", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)), Container(decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)), child: Row(children: [IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.cyan), onPressed: () => _updateMemberCount(-1, t.teamSize, t.customQuestions)), Text('$_currentTeamSize명', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), IconButton(icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.cyan), onPressed: () => _updateMemberCount(1, t.teamSize, t.customQuestions))]))]),
            const SizedBox(height: 12),
            ...List.generate(_memberNames.length, (index) => Padding(padding: const EdgeInsets.only(bottom: 16), child: AppCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("팀원 ${index + 2}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 12), _buildField("이름(한글) *", _memberNames[index], Icons.person_add_alt_1_outlined), const SizedBox(height: 16), _buildField("레이팅 *", _memberRatings[index], Icons.star_border_outlined, isPhone: true), if (t.customQuestions.isNotEmpty) ...[ const Divider(height: 32), ...t.customQuestions.map((q) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildField(q, _memberCustomCtrls[index][q]!, Icons.help_outline))) ]])))),
          ],

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isSubmitting ? null : () => _submit(t, user),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan[700], padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(widget.isManualMode ? "수동 참가 등록 완료" : "참가 신청 완료", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {bool isPhone = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isPhone ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20, color: Colors.grey[400]), labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13), contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.cyan))),
      validator: (v) => (v == null || v.trim().isEmpty) && label.contains('*') ? '필수 입력 항목입니다.' : null,
    );
  }
}