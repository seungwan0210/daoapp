// lib/presentation/screens/arena/tournament/tournament_participant_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
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

  CollectionReference<Map<String, dynamic>> get _tournamentCol =>
      FirebaseFirestore.instance.collection('tournaments');

  DocumentReference<Map<String, dynamic>> get _tournamentDoc =>
      _tournamentCol.doc(tournamentId);

  CollectionReference<Map<String, dynamic>> get _entriesCol =>
      _tournamentDoc.collection('entries');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: tournamentTitle, showBackButton: true),
      body: StreamBuilder<List<TournamentEntryModel>>(
        stream: _repo.getEntries(tournamentId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = List<TournamentEntryModel>.from(snapshot.data ?? []);

          // ✅ 안전 정렬(오래된 신청이 위로)
          // createdAt은 required Timestamp라 null 고려 불필요
          entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

          if (entries.isEmpty) {
            return const Center(
              child: Text(
                '아직 참가자가 없습니다',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final e = entries[index];

              final subtitleLines = <String>[];
              subtitleLines.add(e.phone);

              if ((e.homeShop ?? '').trim().isNotEmpty) {
                subtitleLines.add('홈샵: ${e.homeShop}');
              }
              if ((e.email ?? '').trim().isNotEmpty) {
                subtitleLines.add('이메일: ${e.email}');
              }

              // ✅ B안: entries/{docId} = userUid
              final docId = e.userUid.trim();
              final canEditDelete = docId.isNotEmpty;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    '${e.nameKo} (${e.nameEn})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    subtitleLines.join('\n'),
                    style: const TextStyle(height: 1.4),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if ((e.rating ?? '').trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            e.rating!.trim(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (!canEditDelete) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('userUid가 없어 수정/삭제할 수 없습니다'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          switch (value) {
                            case 'edit':
                              _showEditDialog(context, e);
                              break;
                            case 'delete':
                              _deleteEntryB(context, e);
                              break;
                          }
                        },
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('수정하기'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('삭제(엔트리 취소)',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => _showDetailBottomSheet(context, e, index + 1),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ✅ 풀스크린 바텀시트 (드래그 + 스크롤 + 크게 보기)
  void _showDetailBottomSheet(
      BuildContext context,
      TournamentEntryModel e,
      int order,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'No.$order',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${e.nameKo} (${e.nameEn})',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 40, thickness: 1),
                  _infoRowBig('연락처', e.phone),
                  _infoRowBig(
                      '레이팅', (e.rating ?? '').trim().isEmpty ? '-' : e.rating!),
                  _infoRowBig('홈샵',
                      (e.homeShop ?? '').trim().isEmpty ? '-' : e.homeShop!),
                  _infoRowBig('이메일',
                      (e.email ?? '').trim().isEmpty ? '-' : e.email!),
                  _infoRowBig(
                    '신청 시각',
                    DateFormat('yyyy년 M월 d일 HH:mm').format(e.createdAt.toDate()),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: e.userUid.trim().isEmpty
                              ? null
                              : () {
                            Navigator.pop(context);
                            _showEditDialog(context, e);
                          },
                          icon: const Icon(Icons.edit, size: 20),
                          label: const Text('수정하기',
                              style: TextStyle(fontSize: 17)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: e.userUid.trim().isEmpty
                              ? null
                              : () {
                            Navigator.pop(context);
                            _deleteEntryB(context, e);
                          },
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          label: const Text(
                            '삭제',
                            style: TextStyle(color: Colors.red, fontSize: 17),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoRowBig(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, TournamentEntryModel e) {
    final docId = e.userUid.trim();

    final nameKoCtrl = TextEditingController(text: e.nameKo);
    final nameEnCtrl = TextEditingController(text: e.nameEn);
    final phoneCtrl = TextEditingController(text: e.phone);
    final ratingCtrl = TextEditingController(text: e.rating ?? '');
    final homeShopCtrl = TextEditingController(text: e.homeShop ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('참가자 정보 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameKoCtrl,
                  decoration: const InputDecoration(labelText: '한글 이름'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameEnCtrl,
                  decoration: const InputDecoration(labelText: '영문 이름'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: '연락처'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ratingCtrl,
                  decoration: const InputDecoration(labelText: '레이팅 (선택)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: homeShopCtrl,
                  decoration: const InputDecoration(labelText: '홈샵 (선택)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                if (docId.isEmpty) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('userUid가 없어 수정할 수 없습니다'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                try {
                  await _entriesCol.doc(docId).update({
                    'nameKo': nameKoCtrl.text.trim(),
                    'nameEn': nameEnCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'rating': ratingCtrl.text.trim().isEmpty
                        ? null
                        : ratingCtrl.text.trim(),
                    'homeShop': homeShopCtrl.text.trim().isEmpty
                        ? null
                        : homeShopCtrl.text.trim(),

                    // ✅ 운영상 유용 (모델에 없어도 필드 저장 OK)
                    'updatedAt': Timestamp.now(),
                  });

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('참가자 정보가 수정되었습니다'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (err) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('수정 실패: $err'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('저장',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// ✅ B안 삭제: 트랜잭션으로 entryCount -1 + entries/{userUid} 삭제
  Future<void> _deleteEntryB(BuildContext context, TournamentEntryModel e) async {
    final docId = e.userUid.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('엔트리 삭제'),
        content: Text(
          '"${e.nameKo} (${e.nameEn})" 참가자를 명단에서 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제하기', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('userUid가 없어 삭제할 수 없습니다'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final tSnap = await tx.get(_tournamentDoc);
        if (!tSnap.exists) return;

        final entryRef = _entriesCol.doc(docId);
        final entrySnap = await tx.get(entryRef);

        // 이미 없으면 카운트도 건드리지 않음 (중복 삭제 방지)
        if (!entrySnap.exists) return;

        final data = tSnap.data() ?? {};
        final current = (data['entryCount'] as int?) ?? 0;
        final next = (current - 1) < 0 ? 0 : (current - 1);

        tx.update(_tournamentDoc, {
          'entryCount': next,
          'updatedAt': Timestamp.now(),
        });
        tx.delete(entryRef);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('엔트리가 삭제되었습니다'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('삭제 실패: $err'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
