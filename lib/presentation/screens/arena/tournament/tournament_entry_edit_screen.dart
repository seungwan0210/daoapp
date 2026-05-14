import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

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

    final s = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);

    try {
      final String docId = widget.entry.id ?? widget.entry.userUid;

      await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.tournamentId)
          .collection('entries')
          .doc(docId)
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
            SnackBar(content: Text(s.entry_edit_success), behavior: SnackBarBehavior.floating)
        );
      }
    } catch (e) {
      debugPrint("Update failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.entry_edit_fail(e.toString())), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(
        title: s.entry_edit_title,
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _updateEntry,
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyan))
                : Text(s.common_save, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.cyan)),
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
              if (widget.entry.isManual)
                AppCard(
                  color: Colors.amber.shade50,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_attributes, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(child: Text(s.entry_edit_manual_banner, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange))),
                      ],
                    ),
                  ),
                ),

              if (widget.entry.teamName != null) ...[
                _sectionTitle(s.entry_edit_setup, Icons.account_tree_outlined),
                const SizedBox(height: 12),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildTextField(_teamNameCtrl, s.entry_form_field_team_name, Icons.groups_outlined, s),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              _sectionTitle(s.entry_edit_section_leader, Icons.person_outline),
              const SizedBox(height: 12),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(_nameCtrl, s.entry_list_info_name, Icons.badge_outlined, s),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneCtrl, s.entry_form_field_phone, Icons.phone_android_outlined, s, isPhone: true),
                      const SizedBox(height: 16),
                      _buildTextField(_ratingCtrl, s.entry_form_field_rating, Icons.bolt_outlined, s),
                      const SizedBox(height: 16),
                      _buildTextField(_homeShopCtrl, s.entry_form_field_homeshop, Icons.storefront_outlined, s),
                    ],
                  ),
                ),
              ),

              if (_customAnswers.isNotEmpty) ...[
                const SizedBox(height: 32),
                _sectionTitle(s.entry_edit_section_leader_qna, Icons.quiz_outlined),
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
                _sectionTitle(s.entry_edit_section_member, Icons.people_alt_outlined),
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
                            Text(s.entry_edit_field_member_no(idx + 1), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan, fontSize: 13)),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: m.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(labelText: s.entry_list_info_name, prefixIcon: const Icon(Icons.person_outline, size: 20)),
                              onChanged: (val) => _members[idx] = m.copyWith(name: val),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: m.rating,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(labelText: s.entry_form_field_rating, prefixIcon: const Icon(Icons.bolt_outlined, size: 20)),
                              onChanged: (val) => _members[idx] = m.copyWith(rating: val),
                            ),

                            if (m.customAnswers.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 20, bottom: 8),
                                child: Text(s.entry_edit_field_member_qna, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
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

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, AppLocalizations s, {bool isPhone = false}) {
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
      validator: (v) => (v == null || v.trim().isEmpty) ? s.entry_form_field_required : null,
    );
  }
}