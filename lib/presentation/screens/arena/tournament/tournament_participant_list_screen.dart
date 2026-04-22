import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

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
  String get _adminUid => "NanHPgCdsbMCFkHEs7MtxS51OSX2"; // 승완님 UID

  // 🎯 [수정] UID 대신 문서 고유 ID(docId)를 직접 받도록 변경하여 수동 등록자 대응
  DocumentReference<Map<String, dynamic>> _entryRef(String docId) =>
      _db.collection('tournaments').doc(tournamentId).collection('entries').doc(docId);

  // 🛡️ 마스킹 헬퍼 함수
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: tournamentTitle, showBackButton: true),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _db.collection('tournaments').doc(tournamentId).snapshots(),
          builder: (context, tSnap) {
            if (!tSnap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyan));
            if (!tSnap.data!.exists) return const Center(child: Text("대회를 찾을 수 없습니다."));

            final tournament = TournamentModel.fromJson(tSnap.data!.data()!);
            final bool isMaster = _currentUid == _adminUid || _currentUid == tournament.createdByUid;

            return StreamBuilder<List<TournamentEntryModel>>(
              stream: _repo.getEntries(tournamentId),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('오류: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyan));

                final entries = List<TournamentEntryModel>.from(snapshot.data ?? []);
                entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

                if (entries.isEmpty) {
                  return Center(
                    child: Text('아직 참가자가 없습니다',
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
                              Text(
                                tournament.type == 'team'
                                    ? '[팀] ${e.teamName ?? '이름 없음'}'
                                    : '${e.nameKo} (${e.nameEn})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                              ),
                              // 🎯 [추가] 수동 등록 배지 표시
                              if (e.isManual)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: const Text("수동", style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            tournament.type == 'team'
                                ? '팀장: ${e.nameKo} · ${ (isMaster || isMyEntry) ? e.phone : _maskText(e.phone, isPhone: true)}'
                                : '${ (isMaster || isMyEntry) ? e.phone : _maskText(e.phone, isPhone: true)}${e.homeShop != null ? ' · ${e.homeShop}' : ''}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isMaster) _buildPaymentToggle(e, isPaid),
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

  Widget _buildPaymentToggle(TournamentEntryModel e, bool isPaid) {
    return InkWell(
      onTap: () async {
        try {
          // 🎯 [수정] 수동 등록 유저는 e.id(랜덤문서ID)를 사용해야 함
          final String docId = e.id ?? e.userUid;
          await _entryRef(docId).update({
            'isPaid': !isPaid,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (err) {
          debugPrint('입금 업데이트 실패: $err');
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
          isPaid ? '입금완료' : '미입금',
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
              Center(child: Text('No.$order', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),
              Text(
                  type == 'team' ? '[팀] ${e.teamName}' : '${e.nameKo} (${e.nameEn})',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)
              ),
              const Divider(height: 32),

              _infoRowCompact(type == 'team' ? '팀장 성함' : '성함', '${e.nameKo} (${e.nameEn})'),
              _infoRowCompact('연락처', canSeeAll ? e.phone : _maskText(e.phone, isPhone: true)),
              _infoRowCompact('레이팅', e.rating ?? '-'),
              _infoRowCompact('홈샵', e.homeShop ?? '-'),

              if (e.customAnswers.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('신청 질문 답변', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.cyan)),
                const SizedBox(height: 6),
                _buildCustomAnswersView(e.customAnswers, canSeeAll: canSeeAll),
              ],

              if (type == 'team' && e.members.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Text('팀원 목록 및 개별 답변', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.cyan)),
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
                    child: Text('팀 합계 레이팅: ${e.totalRating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                        label: const Text('정보 수정'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () { Navigator.pop(context); _deleteEntryB(context, e); },
                        icon: const Icon(Icons.delete_outline, size: 20),
                        label: const Text('엔트리 삭제'),
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
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, TournamentEntryModel e) {
    final nameKoCtrl = TextEditingController(text: e.nameKo);
    final nameEnCtrl = TextEditingController(text: e.nameEn);
    final phoneCtrl = TextEditingController(text: e.phone);
    final ratingCtrl = TextEditingController(text: e.rating ?? '');
    final homeShopCtrl = TextEditingController(text: e.homeShop ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('참가자 정보 수정', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameKoCtrl, decoration: const InputDecoration(labelText: '한글 이름')),
              TextField(controller: nameEnCtrl, decoration: const InputDecoration(labelText: '영문 이름')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: '연락처'), keyboardType: TextInputType.phone),
              TextField(controller: ratingCtrl, decoration: const InputDecoration(labelText: '레이팅 (선택)')),
              TextField(controller: homeShopCtrl, decoration: const InputDecoration(labelText: '홈샵 (선택)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              // 🎯 [수정] 수동 등록자 대응을 위해 e.id ?? e.userUid 사용
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
            child: const Text('저장', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntryB(BuildContext context, TournamentEntryModel e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('엔트리 삭제'),
        content: Text('"${e.nameKo}" 참가자를 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _db.runTransaction((tx) async {
        final tRef = _db.collection('tournaments').doc(tournamentId);
        final tSnap = await tx.get(tRef);

        // 🎯 [수정] 수동 등록자 대응을 위해 e.id ?? e.userUid 사용
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
      debugPrint('삭제 실패: $e');
    }
  }
}