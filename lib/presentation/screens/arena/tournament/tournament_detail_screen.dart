// lib/presentation/screens/community/arena/tournament_detail_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/core/utils/arena_utils.dart';
import 'package:daoapp/core/utils/date_utils.dart'; // ✅ 날짜 포맷용
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournament_edit_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/widgets/entry_status_badge.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TournamentDetailScreen extends ConsumerWidget {
  final String tournamentId;

  const TournamentDetailScreen({
    super.key,
    required this.tournamentId,
  });

  // 대회 삭제 (주최자 + 관리자)
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
        ..pop() // 디테일 화면 닫기
        ..maybePop();

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
        SnackBar(
          content: Text('삭제 실패: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 내 참가신청 취소
  Future<void> _cancelMyEntry(
      BuildContext context, {
        required String entryId,
      }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('참가 신청 취소'),
        content: const Text(
          '해당 대회 참가 신청을 취소하시겠습니까?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('닫기')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournamentId)
          .collection('entries')
          .doc(entryId)
          .delete();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('참가 신청이 취소되었습니다'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('취소 실패: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdminAsync = ref.watch(isAdminProvider);
    final bool isAdmin = isAdminAsync.valueOrNull ?? false;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournamentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: CommonAppBar(title: '대회 상세', showBackButton: true),
            body: Center(child: Text('오류가 발생했습니다: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('대회를 찾을 수 없습니다')),
          );
        }

        final doc = snapshot.data!;
        final data = doc.data()!;
        final tournament = TournamentModel.fromJson(data).copyWith(id: doc.id);

        // 종료 후 3일 경과 여부 (KST)
        final now = nowKst();
        final threeDaysAgo = now.subtract(const Duration(days: 3));
        final isTournamentExpired =
        tournament.eventDate.toDate().isBefore(threeDaysAgo);

        // 주최자·공동주최자 여부
        final bool isOrganizer = user != null &&
            (tournament.createdByUid == user.uid ||
                tournament.organizerEmails.contains(user.email));

        final bool canManage = isOrganizer || isAdmin;

        // 일반 유저는 종료 후 3일 지나면 접근 제한
        if (!canManage && isTournamentExpired) {
          return Scaffold(
            appBar: CommonAppBar(title: '대회 상세', showBackButton: true),
            body: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey),
                  SizedBox(height: 24),
                  Text(
                    '종료된 대회입니다',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '대회 종료 후 3일이 지나 확인할 수 없습니다',
                    style: TextStyle(color: Colors.grey),
                  ),
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

        // ✅ 보기 좋은 날짜/시간 문자열 준비
        final eventDate = tournament.eventDate.toDate();
        final entryStart = tournament.entryStartDate.toDate();
        final entryEnd = tournament.entryEndDate.toDate();

        String _formatDateTime(DateTime dt) {
          final date = AppDateUtils.formatKoreanDate(dt);
          final time =
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          return '$date $time';
        }

        final eventDateStr = _formatDateTime(eventDate);
        final entryStartStr = _formatDateTime(entryStart);
        final entryEndStr = _formatDateTime(entryEnd);

        return Scaffold(
          appBar: CommonAppBar(title: '대회 상세', showBackButton: true),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 포스터
              if (tournament.posterUrl != null &&
                  tournament.posterUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: tournament.posterUrl!,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.grey[200],
                      child:
                      const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(Icons.image_not_supported,
                            size: 64, color: Colors.white70),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.indigo, Colors.purple],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child:
                    Icon(Icons.emoji_events, size: 100, color: Colors.white),
                  ),
                ),

              const SizedBox(height: 24),

              // 상태 뱃지 + 참가 인원
              Row(
                children: [
                  EntryStatusBadge(tournament: tournament),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${tournament.entryCount}/${tournament.maxParticipants}명 참가',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 제목
              Text(
                tournament.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              // 기본 정보
              _InfoRow(icon: Icons.location_on, text: tournament.location),
              _InfoRow(
                icon: Icons.calendar_today,
                text: '대회일: $eventDateStr',
              ),
              _InfoRow(
                icon: Icons.access_time,
                text: '엔트리: $entryStartStr ~ $entryEndStr',
              ),
              if (tournament.entryFee > 0)
                _InfoRow(
                  icon: Icons.paid,
                  text:
                  '참가비: ${tournament.entryFee.toString().replaceAllMapped(
                    RegExp(r'(\d)(?=(\d{3})+(?!\d))'), // ✅ 정규식 수정
                        (m) => '${m[1]},',
                  )}원',
                ),
              if (tournament.hostName.isNotEmpty)
                _InfoRow(
                  icon: Icons.person_outline,
                  text: '담당자: ${tournament.hostName}',
                ),
              if (tournament.hostPhone.isNotEmpty)
                _InfoRow(
                  icon: Icons.phone_outlined,
                  text: '문의: ${tournament.hostPhone}',
                ),

              const SizedBox(height: 24),

              // 상세 내용
              if (tournament.description.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      tournament.description,
                      style: const TextStyle(fontSize: 15, height: 1.6),
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // 일반 사용자: 참가 신청 / 취소
              if (!canManage) ...[
                if (user == null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        '로그인 후 참가 신청이 가능합니다',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('tournaments')
                        .doc(tournament.id!)
                        .collection('entries')
                        .where('userUid', isEqualTo: user.uid)
                        .limit(1)
                        .snapshots(),
                    builder: (context, entrySnap) {
                      final hasEntry = entrySnap.hasData &&
                          entrySnap.data!.docs.isNotEmpty;
                      final entryDoc =
                      hasEntry ? entrySnap.data!.docs.first : null;

                      if (canEnter) {
                        if (!hasEntry) {
                          // 아직 신청 안함 → 신청 버튼
                          return ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                RouteConstants.tournamentEntryForm,
                                arguments: tournament.id!,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              '참가 신청하기',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        } else {
                          // 이미 신청함 → 취소 버튼
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton(
                                onPressed: () => _cancelMyEntry(
                                  context,
                                  entryId: entryDoc!.id,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[600],
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  '참가 신청 취소',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '※ 엔트리 마감 전까지는 직접 취소할 수 있습니다.\n마감 이후 변경이 필요하면 주최자에게 문의해 주세요.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          );
                        }
                      } else {
                        // 엔트리 기간이 아님
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              status == EntryStatus.upcoming
                                  ? '엔트리 시작 전입니다'
                                  : status == EntryStatus.closed
                                  ? '엔트리 마감되었습니다'
                                  : status == EntryStatus.inProgress
                                  ? '현재 대회가 진행 중입니다'
                                  : '이미 종료된 대회입니다',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
              ],

              // 주최자·관리자 전용 기능
              if (canManage) ...[
                const SizedBox(height: 30),
                Text(
                  isAdmin ? '관리자 전용 기능' : '주최자 전용 기능',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
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
                          arguments: {
                            'tournamentId': tournament.id!,
                            'tournamentTitle': tournament.title,
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('수정하기'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TournamentEditScreen(
                                tournamentId: tournament.id!,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text(
                    '대회 삭제하기',
                    style: TextStyle(color: Colors.red),
                  ),
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
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
