// lib/presentation/screens/community/arena/tournament_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:daoapp/core/utils/arena_utils.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/providers/app_providers.dart'; // isAdminProvider 가져오기
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/screens/community/arena/widgets/entry_status_badge.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class TournamentDetailScreen extends ConsumerWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  // 진짜 삭제 함수 (주최자 + 관리자 모두 사용 가능)
  Future<void> _deleteTournament(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('대회 삭제'),
        content: const Text(
          '정말 삭제하시겠습니까?\n삭제된 대회는 복구할 수 없습니다.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournamentId)
          .delete();

      if (!context.mounted) return;
      Navigator.of(context)
        ..pop() // 다이얼로그 닫기
        ..pop(); // 디테일 화면 닫기

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('대회가 삭제되었습니다'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = sl<ArenaRepository>();
    final user = sl<FirebaseAuth>().currentUser;

    // 관리자 여부 확인 (isAdminProvider 사용)
    final isAdminAsync = ref.watch(isAdminProvider);
    final bool isAdmin = isAdminAsync.valueOrNull ?? false;

    return FutureBuilder<TournamentModel?>(
      future: repo.getTournament(tournamentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text('대회를 찾을 수 없습니다')));
        }

        final tournament = snapshot.data!;
        final now = DateTime.now();
        final threeDaysAgo = now.subtract(const Duration(days: 3));
        final isTournamentExpired = tournament.eventDate.toDate().isBefore(threeDaysAgo);

        // 주최자 또는 공동주최자 여부
        final bool isOrganizer = user != null &&
            (tournament.createdByUid == user.uid ||
                tournament.organizerEmails.contains(user.email));

        // 관리자 또는 주최자면 항상 보이게
        final bool canManage = isOrganizer || isAdmin;

        // 일반 사용자는 종료 3일 지난 대회 못 보게
        if (!canManage && isTournamentExpired) {
          return Scaffold(
            appBar: CommonAppBar(title: '대회 상세', showBackButton: true),
            body: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey),
                  SizedBox(height: 24),
                  Text('종료된 대회입니다', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text('대회 종료 후 3일이 지나 확인할 수 없습니다', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        final status = ArenaUtils.getEntryStatus(
          entryStartDate: tournament.entryStartDate,
          entryEndDate: tournament.entryEndDate,
          eventDate: tournament.eventDate,
        );
        final bool canEnter = status == EntryStatus.open;

        return Scaffold(
          appBar: CommonAppBar(title: '대회 상세', showBackButton: true),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 포스터
              if (tournament.posterUrl != null && tournament.posterUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: tournament.posterUrl!,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                  ),
                )
              else
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.indigo, Colors.purple]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Icon(Icons.emoji_events, size: 100, color: Colors.white)),
                ),

              const SizedBox(height: 24),

              Row(
                children: [
                  EntryStatusBadge(tournament: tournament),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                    child: Text('${tournament.entryCount}/${tournament.maxParticipants}명 참가', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Text(tournament.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),

              const SizedBox(height: 20),
              _InfoRow(icon: Icons.location_on, text: tournament.location),
              _InfoRow(icon: Icons.calendar_today, text: '대회일: ${tournament.eventDate.toDate().toLocal().toString().substring(0, 16)}'),
              _InfoRow(icon: Icons.access_time, text: '엔트리: ${tournament.entryStartDate.toDate().toLocal().toString().substring(0, 16)} ~ ${tournament.entryEndDate.toDate().toLocal().toString().substring(0, 16)}'),
              if (tournament.entryFee > 0)
                _InfoRow(icon: Icons.paid, text: '참가비: ${tournament.entryFee.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원'),

              const SizedBox(height: 24),
              if (tournament.description.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(tournament.description, style: const TextStyle(fontSize: 15, height: 1.6)),
                  ),
                ),

              const SizedBox(height: 40),

              // 일반 사용자: 참가 신청
              if (!canManage) ...[
                if (canEnter)
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, RouteConstants.tournamentEntryForm, arguments: tournament.id!),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('참가 신청하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Text(status == EntryStatus.upcoming ? '엔트리 시작 전입니다' : '엔트리 마감되었습니다', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600))),
                  ),
              ],

              // 주최자 또는 관리자 전용 기능
              if (canManage) ...[
                const SizedBox(height: 30),
                Text(
                  isAdmin ? '관리자 전용 기능' : '주최자 전용 기능',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.list_alt),
                        label: const Text('참가자 명단'),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          RouteConstants.tournamentParticipantList,
                          arguments: {'tournamentId': tournament.id!, 'tournamentTitle': tournament.title},
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('수정하기'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('수정 기능은 준비중입니다')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text('대회 삭제하기', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: () => _deleteTournament(context),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}