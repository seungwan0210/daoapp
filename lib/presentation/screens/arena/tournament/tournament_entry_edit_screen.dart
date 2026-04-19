import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class TournamentEntryEditScreen extends StatefulWidget {
  final String tournamentId;
  final TournamentEntryModel entry;

  const TournamentEntryEditScreen({
    super.key,
    required this.tournamentId,
    required this.entry
  });

  @override
  State<TournamentEntryEditScreen> createState() => _TournamentEntryEditScreenState();
}

class _TournamentEntryEditScreenState extends State<TournamentEntryEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _ratingCtrl;
  late TextEditingController _homeShopCtrl;
  late TextEditingController _teamNameCtrl;

  late Map<String, String> _customAnswers;
  late List<TeamMember> _members;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _nameCtrl = TextEditingController(text: e.nameKo);
    _phoneCtrl = TextEditingController(text: e.phone);
    _ratingCtrl = TextEditingController(text: e.rating);
    _homeShopCtrl = TextEditingController(text: e.homeShop);
    _teamNameCtrl = TextEditingController(text: e.teamName);

    _customAnswers = Map<String, String>.from(e.customAnswers);

    // ✅ 초기 로드 시 깊은 복사 확실히 수행
    _members = e.members.map((m) => TeamMember(
      name: m.name,
      rating: m.rating,
      customAnswers: Map<String, String>.from(m.customAnswers),
    )).toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _ratingCtrl.dispose();
    _homeShopCtrl.dispose(); _teamNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateEntry() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.tournamentId)
          .collection('entries')
          .doc(widget.entry.userUid)
          .update({
        'teamName': _teamNameCtrl.text.trim(),
        'nameKo': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'rating': _ratingCtrl.text.trim(),
        'homeShop': _homeShopCtrl.text.trim(),
        'customAnswers': _customAnswers,
        'members': _members.map((m) => m.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("참가 정보가 수정되었습니다."), behavior: SnackBarBehavior.floating)
        );
      }
    } catch (e) {
      debugPrint("수정 실패: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(
        title: "엔트리 정보 수정",
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _updateEntry,
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyan))
                : const Text('저장', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.cyan)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              if (widget.entry.teamName != null) ...[
                _sectionTitle('대회 방식 설정', Icons.account_tree_outlined),
                const SizedBox(height: 12),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildTextField(_teamNameCtrl, "팀명", Icons.groups_outlined),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              _sectionTitle('대표자(팀장) 정보', Icons.person_outline),
              const SizedBox(height: 12),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(_nameCtrl, "성함", Icons.badge_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneCtrl, "연락처", Icons.phone_android_outlined, isPhone: true),
                      const SizedBox(height: 16),
                      _buildTextField(_ratingCtrl, "레이팅", Icons.bolt_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_homeShopCtrl, "홈샵", Icons.storefront_outlined),
                    ],
                  ),
                ),
              ),

              if (_customAnswers.isNotEmpty) ...[
                const SizedBox(height: 32),
                _sectionTitle('대표자 개별 답변', Icons.quiz_outlined),
                const SizedBox(height: 12),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: _customAnswers.keys.map((key) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          initialValue: _customAnswers[key],
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: key,
                            labelStyle: const TextStyle(fontSize: 13),
                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyan, width: 2)),
                          ),
                          onChanged: (val) => _customAnswers[key] = val,
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              ],

              if (_members.isNotEmpty) ...[
                const SizedBox(height: 32),
                _sectionTitle('팀원 정보 및 답변 수정', Icons.people_alt_outlined),
                const SizedBox(height: 12),
                ..._members.asMap().entries.map((entry) {
                  int idx = entry.key;
                  TeamMember m = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('팀원 ${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan, fontSize: 13)),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: m.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(labelText: "성함", prefixIcon: Icon(Icons.person_outline, size: 20)),
                              onChanged: (val) => _members[idx] = m.copyWith(name: val),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: m.rating,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(labelText: "레이팅", prefixIcon: Icon(Icons.bolt_outlined, size: 20)),
                              onChanged: (val) => _members[idx] = m.copyWith(rating: val),
                            ),

                            if (m.customAnswers.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.only(top: 20, bottom: 8),
                                child: Text("팀원 개별 답변", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                              ),
                              ...m.customAnswers.keys.map((qKey) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: TextFormField(
                                  initialValue: m.customAnswers[qKey],
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    labelText: qKey,
                                    labelStyle: const TextStyle(fontSize: 12),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  onChanged: (val) {
                                    // ✅ 핵심 수정 포인트: 맵의 값을 직접 수정하지 않고
                                    // 새로운 맵을 생성하여 객체를 업데이트합니다.
                                    final newAnswers = Map<String, String>.from(_members[idx].customAnswers);
                                    newAnswers[qKey] = val;
                                    _members[idx] = _members[idx].copyWith(customAnswers: newAnswers);
                                  },
                                ),
                              )).toList(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, IconData icon) => Row(
    children: [
      Icon(icon, size: 18, color: Colors.cyan),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
    ],
  );

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool isPhone = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[400]),
        labelStyle: const TextStyle(fontSize: 13),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyan, width: 2)),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? '필수 입력' : null,
    );
  }
}