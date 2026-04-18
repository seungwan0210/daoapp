// lib/presentation/screens/arena/tournament/tournament_detail_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournament_edit_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/widgets/entry_status_badge.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TournamentDetailScreen extends ConsumerWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  String _maskName(String name) {
    if (name.isEmpty) return "";
    if (name.length == 1) return name;
    return name[0] + ("*" * (name.length - 1));
  }

  String _maskPhone(String phone) {
    if (phone.length >= 10) {
      return "${phone.substring(0, 3)}-****-${phone.substring(phone.length - 4)}";
    }
    return "****";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.cyan)));
        }

        final t = TournamentModel.fromJson(snapshot.data!.data()!).copyWith(id: snapshot.data!.id);
        final isOrganizer = user != null && (t.createdByUid == user.uid || t.organizerEmails.contains(user.email));
        final canManage = isOrganizer || isAdmin;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: CommonAppBar(title: t.title, showBackButton: true),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              if (t.posterUrl != null && t.posterUrl!.isNotEmpty)
                AppCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: t.posterUrl!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => Container(height: 200, color: Colors.grey[100]),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  EntryStatusBadge(tournament: t),
                  Text(
                    "신청 ${t.entryCount}/${t.maxParticipants >= 9999 ? '∞' : t.maxParticipants}명",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(t.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 20),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.location_on_outlined, "장소", t.location),
                      const Divider(height: 24, thickness: 0.5),
                      _buildInfoRow(Icons.calendar_month_outlined, "일시", DateFormat('yyyy.MM.dd HH:mm').format(t.eventDate.toDate())),
                      const Divider(height: 24, thickness: 0.5),
                      _buildInfoRow(Icons.paid_outlined, "참가비", t.entryFee > 0 ? "${NumberFormat('#,###').format(t.entryFee)}원" : "무료"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text("대회 상세 정보", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    t.description.isEmpty ? "상세 정보가 없습니다." : t.description,
                    style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildParticipantSection(context, t, user, canManage),
              const SizedBox(height: 32),
              if (canManage) _buildAdminActions(context, t, isAdmin),
            ],
          ),
          bottomNavigationBar: _buildBottomEntryAction(context, t, user, canManage),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.cyan[700]),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildParticipantSection(BuildContext context, TournamentModel t, User? user, bool canManage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("실시간 참가 명단", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        StreamBuilder<List<TournamentEntryModel>>(
          stream: sl<ArenaRepository>().getEntries(t.id!),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final entries = snapshot.data!;
            if (entries.isEmpty) return Center(child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("아직 신청자가 없습니다.", style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            ));

            return AppCard(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[50]),
                itemBuilder: (context, index) {
                  final e = entries[index];

                  // 🔥 [중요] 입금 확인 로직: DB 필드(isPaid)를 우선 참조
                  final rawJson = e.toJson();
                  final bool isPaid = rawJson['isPaid'] == true || e.status == 'confirmed';

                  return ListTile(
                    dense: true,
                    leading: Text("${index + 1}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    title: Text(
                      canManage ? e.nameKo : _maskName(e.nameKo),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      canManage ? e.phone : _maskPhone(e.phone),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ 체크 아이콘이 실시간으로 보이게 함
                        if (isPaid)
                          const Icon(Icons.check_circle_rounded, color: Colors.cyan, size: 20)
                        else
                          Text("미입금", style: TextStyle(fontSize: 11, color: Colors.grey[350])),
                        if (canManage)
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                            onPressed: () => _showEntryManagementSheet(context, t.id!, e, isPaid),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdminActions(BuildContext context, TournamentModel t, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        Text(isAdmin ? "관리자 권한" : "주최자 권한", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text("대회 수정"),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentEditScreen(tournamentId: t.id!))),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text("대회 삭제"),
                onPressed: () => _deleteTournament(context, t.id!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomEntryAction(BuildContext context, TournamentModel t, User? user, bool canManage) {
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('tournaments').doc(t.id).collection('entries').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final hasEntry = snapshot.hasData && snapshot.data!.exists;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: ElevatedButton(
              onPressed: () {
                if (hasEntry) {
                  _cancelMyEntry(context, t.id!, user.uid);
                } else {
                  Navigator.pushNamed(context, RouteConstants.tournamentEntryForm, arguments: t.id);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: hasEntry ? Colors.grey[800] : Colors.cyan[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                hasEntry ? "참가 신청 취소하기" : "참가 신청하기",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEntryManagementSheet(BuildContext context, String tid, TournamentEntryModel e, bool isPaid) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isPaid ? Icons.money_off : Icons.check_circle, color: isPaid ? Colors.red : Colors.cyan),
              title: Text(isPaid ? "입금 확인 취소(미입금으로)" : "입금 확인 처리(v)"),
              onTap: () async {
                // ✅ isPaid와 status를 동시에 업데이트하여 UI와 규칙 모두 만족
                await FirebaseFirestore.instance
                    .collection('tournaments')
                    .doc(tid)
                    .collection('entries')
                    .doc(e.userUid)
                    .update({
                  'isPaid': !isPaid,
                  'status': !isPaid ? 'confirmed' : 'applied',
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text("엔트리 강제 삭제", style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("엔트리 삭제"),
                    content: Text("${e.nameKo} 참가자를 삭제하시겠습니까?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await sl<ArenaRepository>().cancelEntry(tournamentId: tid, userUid: e.userUid);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTournament(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("대회 삭제"),
        content: const Text("정말로 이 대회를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await sl<ArenaRepository>().deleteTournament(id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _cancelMyEntry(BuildContext context, String tid, String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("참가 취소"),
        content: const Text("참가 신청을 취소하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("아니오")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("취소하기", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await sl<ArenaRepository>().cancelEntry(tournamentId: tid, userUid: uid);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("참가 신청이 취소되었습니다.")));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류가 발생했습니다: $e")));
        }
      }
    }
  }
}