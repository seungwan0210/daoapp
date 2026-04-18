// lib/presentation/screens/arena/tournament/tournament_participant_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:intl/intl.dart';

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

  // 헬퍼: 특정 엔트리 문서 참조
  DocumentReference<Map<String, dynamic>> _entryRef(String uid) =>
      _db.collection('tournaments').doc(tournamentId).collection('entries').doc(uid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 트레이닝 홈 감성 배경
      appBar: CommonAppBar(title: tournamentTitle, showBackButton: true),
      body: StreamBuilder<List<TournamentEntryModel>>(
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
              // isPaid 필드가 모델에 정의되어 있다고 가정하거나 JSON에서 직접 추출
              final bool isPaid = (e.toJson()['isPaid'] ?? false);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () => _showDetailBottomSheet(context, e, index + 1),
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text('${index + 1}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                    ),
                    title: Text(
                      '${e.nameKo} (${e.nameEn})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                    subtitle: Text(
                      '${e.phone}${e.homeShop != null ? ' · ${e.homeShop}' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ 입금 확인 퀵 토글 버튼
                        _buildPaymentToggle(e, isPaid),
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
      ),
    );
  }

  // ✅ 입금 상태를 바로 바꿀 수 있는 칩 위젯
  Widget _buildPaymentToggle(TournamentEntryModel e, bool isPaid) {
    return InkWell(
      onTap: () async {
        try {
          await _entryRef(e.userUid).update({'isPaid': !isPaid});
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPaid) const Icon(Icons.check, size: 12, color: Colors.cyan),
            if (isPaid) const SizedBox(width: 4),
            Text(
              isPaid ? '입금완료' : '미입금',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isPaid ? FontWeight.bold : FontWeight.normal,
                color: isPaid ? Colors.cyan : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 상세 바텀시트 (수정/삭제 포함)
  void _showDetailBottomSheet(BuildContext context, TournamentEntryModel e, int order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text('No.$order', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),
              Text('${e.nameKo} (${e.nameEn})', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const Divider(height: 40),
              _infoRowCompact('연락처', e.phone),
              _infoRowCompact('레이팅', e.rating ?? '-'),
              _infoRowCompact('홈샵', e.homeShop ?? '-'),
              _infoRowCompact('이메일', e.email ?? '-'),
              _infoRowCompact('신청일', DateFormat('yyyy.MM.dd HH:mm').format(e.createdAt.toDate())),
              const SizedBox(height: 40),
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

  Widget _infoRowCompact(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  // --- 수정 다이얼로그 & 삭제 로직 (기존 기능 유지) ---
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
              await _entryRef(e.userUid).update({
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

        final entryRef = _entryRef(e.userUid);
        final entrySnap = await tx.get(entryRef);
        if (!entrySnap.exists) return;

        final current = (tSnap.data()?['entryCount'] as int?) ?? 0;

        // ✅ 핵심 수정: 'updatedAt' 필드를 서버 시간으로 함께 업데이트해야 규칙을 통과합니다.
        tx.update(tRef, {
          'entryCount': (current - 1).clamp(0, 9999),
          'updatedAt': FieldValue.serverTimestamp(), // 🔥 이 줄이 열쇠입니다!
        });

        tx.delete(entryRef);
      });
    } catch (e) {
      debugPrint('삭제 실패: $e');
    }
  }
}