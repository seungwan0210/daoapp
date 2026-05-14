import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class TournamentParticipantListScreen extends StatelessWidget {
  final String tournamentId;
  final String tournamentTitle;

  const TournamentParticipantListScreen({
    super.key,
    required this.tournamentId,
    this.tournamentTitle = '참가자 명단',
  });

  ArenaRepository get _repo => sl<ArenaRepository>();
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _adminUid => "NanHPgCdsbMCFkHEs7MtxS51OSX2";

  DocumentReference<Map<String, dynamic>> _entryRef(String docId) =>
      _db.collection('tournaments').doc(tournamentId).collection('entries').doc(docId);

  String _maskText(String? text, {bool isPhone = false}) {
    if (text == null || text.isEmpty) return "-";
    if (isPhone) {
      if (text.contains('-') && text.length >= 10) {
        final parts = text.split('-');
        if (parts.length == 3) return "${parts[0]}-****-${parts[2]}";
      }
      if (text.length >= 10) return text.replaceRange(3, 7, "****");
      return "****";
    } else {
      if (text.length <= 1) return "*";
      if (text.length == 2) return "${text[0]}*";
      return "${text[0]}${'*' * (text.length - 2)}${text[text.length - 1]}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: tournamentTitle, showBackButton: true),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _db.collection('tournaments').doc(tournamentId).snapshots(),
          builder: (context, tSnap) {
            if (!tSnap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyan));
            if (!tSnap.data!.exists) return Center(child: Text(s.entry_list_not_found));

            final tournament = TournamentModel.fromJson(tSnap.data!.data()!);
            final bool isMaster = _currentUid == _adminUid || _currentUid == tournament.createdByUid;

            return StreamBuilder<List<TournamentEntryModel>>(
              stream: _repo.getEntries(tournamentId),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyan));

                final entries = List<TournamentEntryModel>.from(snapshot.data ?? []);
                entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

                if (entries.isEmpty) {
                  return Center(
                    child: Text(s.entry_list_no_data,
                        style: TextStyle(fontSize: 15, color: Colors.grey[400], fontWeight: FontWeight.w500)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    final bool isPaid = (e.toJson()['isPaid'] ?? false);
                    final bool isMyEntry = _currentUid == e.userUid;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        onTap: () => _showDetailBottomSheet(context, e, index + 1, tournament.type, isMaster),
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: _buildOrderCircle(index + 1),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  tournament.type == 'team'
                                      ? s.entry_list_team_prefix(e.teamName ?? '')
                                      : '${e.nameKo} (${e.nameEn})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              if (e.isManual)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: Text(s.entry_list_manual, style: const TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            tournament.type == 'team'
                                ? '${s.entry_list_team_leader(e.nameKo)} · ${(isMaster || isMyEntry) ? e.phone : _maskText(e.phone, isPhone: true)}'
                                : '${(isMaster || isMyEntry) ? e.phone : _maskText(e.phone, isPhone: true)}${e.homeShop != null ? ' · ${e.homeShop}' : ''}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isMaster) _buildPaymentToggle(context, e, isPaid),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
      ),
    );
  }

  Widget _buildOrderCircle(int order) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text('$order', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildPaymentToggle(BuildContext context, TournamentEntryModel e, bool isPaid) {
    final s = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () async {
        try {
          final String docId = e.id ?? e.userUid;
          await _entryRef(docId).update({
            'isPaid': !isPaid,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (err) {
          debugPrint('Update failed: $err');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isPaid ? Colors.cyan.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isPaid ? Colors.cyan.withOpacity(0.5) : Colors.grey[300]!),
        ),
        child: Text(
          isPaid ? s.entry_list_paid : s.entry_list_not_paid,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isPaid ? FontWeight.bold : FontWeight.normal,
            color: isPaid ? Colors.cyan : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  void _showDetailBottomSheet(BuildContext context, TournamentEntryModel e, int order, String type, bool isMaster) {
    final s = AppLocalizations.of(context)!;
    final bool isMyEntry = _currentUid == e.userUid;
    final bool canSeeAll = isMaster || isMyEntry;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text(s.entry_list_detail_no(order), style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),
              Text(
                  type == 'team' ? s.entry_list_team_prefix(e.teamName ?? '') : '${e.nameKo} (${e.nameEn})',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)
              ),
              const Divider(height: 32),

              _infoRowCompact(type == 'team' ? s.entry_list_info_leader : s.entry_list_info_name, '${e.nameKo} (${e.nameEn})'),
              _infoRowCompact(s.entry_list_info_phone, canSeeAll ? e.phone : _maskText(e.phone, isPhone: true)),
              _infoRowCompact(s.entry_list_info_rating, e.rating ?? '-'),
              _infoRowCompact(s.entry_list_info_homeshop, e.homeShop ?? '-'),

              if (e.customAnswers.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(s.entry_list_qna_title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.cyan)),
                const SizedBox(height: 6),
                _buildCustomAnswersView(e.customAnswers, canSeeAll: canSeeAll),
              ],

              if (type == 'team' && e.members.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(s.entry_list_member_title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.cyan)),
                const SizedBox(height: 12),
                ...e.members.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('Rt. ${m.rating}', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (m.customAnswers.isNotEmpty) ...[
                        const Divider(height: 20),
                        _buildCustomAnswersView(m.customAnswers, isInsideCard: true, canSeeAll: canSeeAll),
                      ],
                    ],
                  ),
                )),
                if (e.totalRating != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(s.entry_list_total_rating(e.totalRating!), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
              ],

              const SizedBox(height: 40),
              if (isMaster)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () { Navigator.pop(context); _showEditDialog(context, e); },
                        icon: const Icon(Icons.edit_note, size: 20),
                        label: Text(s.entry_list_btn_edit),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () { Navigator.pop(context); _deleteEntryB(context, e); },
                        icon: const Icon(Icons.delete_outline, size: 20),
                        label: Text(s.entry_list_btn_delete),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAnswersView(Map<String, String> answers, {bool isInsideCard = false, bool canSeeAll = false}) {
    return Container(
      width: double.infinity,
      padding: isInsideCard ? EdgeInsets.zero : const EdgeInsets.all(12),
      decoration: isInsideCard ? null : BoxDecoration(
        color: Colors.cyan.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: answers.entries.map((entry) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ${entry.key}: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Expanded(
                  child: Text(
                      canSeeAll ? entry.value : _maskText(entry.value),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)
                  )
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _infoRowCompact(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, TournamentEntryModel e) {
    final s = AppLocalizations.of(context)!;
    final nameKoCtrl = TextEditingController(text: e.nameKo);
    final nameEnCtrl = TextEditingController(text: e.nameEn);
    final phoneCtrl = TextEditingController(text: e.phone);
    final ratingCtrl = TextEditingController(text: e.rating ?? '');
    final homeShopCtrl = TextEditingController(text: e.homeShop ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.entry_list_edit_dialog_title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameKoCtrl, decoration: InputDecoration(labelText: s.entry_list_edit_name_ko)),
              TextField(controller: nameEnCtrl, decoration: InputDecoration(labelText: s.entry_list_edit_name_en)),
              TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: s.entry_list_edit_phone), keyboardType: TextInputType.phone),
              TextField(controller: ratingCtrl, decoration: InputDecoration(labelText: s.entry_list_edit_rating)),
              TextField(controller: homeShopCtrl, decoration: InputDecoration(labelText: s.entry_list_edit_homeshop)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.common_cancel)),
          TextButton(
            onPressed: () async {
              final String docId = e.id ?? e.userUid;
              await _entryRef(docId).update({
                'nameKo': nameKoCtrl.text.trim(),
                'nameEn': nameEnCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'rating': ratingCtrl.text.trim(),
                'homeShop': homeShopCtrl.text.trim(),
                'updatedAt': Timestamp.now(),
              });
              if(context.mounted) Navigator.pop(ctx);
            },
            child: Text(s.common_save, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntryB(BuildContext context, TournamentEntryModel e) async {
    final s = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.entry_list_delete_confirm_title),
        content: Text(s.entry_list_delete_confirm_msg(e.nameKo)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.common_cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.common_delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _db.runTransaction((tx) async {
        final tRef = _db.collection('tournaments').doc(tournamentId);
        final tSnap = await tx.get(tRef);

        final String docId = e.id ?? e.userUid;
        final entryRef = _entryRef(docId);

        final entrySnap = await tx.get(entryRef);
        if (!entrySnap.exists) return;
        final current = (tSnap.data()?['entryCount'] as int?) ?? 0;
        tx.update(tRef, {
          'entryCount': (current - 1).clamp(0, 9999),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        tx.delete(entryRef);
      });
    } catch (e) {
      debugPrint('Delete failed: $e');
    }
  }
}