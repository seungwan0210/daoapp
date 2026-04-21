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
import 'package:daoapp/presentation/screens/arena/tournament/tournament_entry_edit_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/widgets/entry_status_badge.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart'; // ✅ 추가됨

// ✅ AdMob 배너 광고 위젯 임포트
import 'package:daoapp/presentation/widgets/ad_banner.dart';
import 'package:daoapp/core/utils/ad_manager.dart';

class TournamentDetailScreen extends ConsumerWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  // ✅ [추가] 공유 기능 함수
  void _onShareTournament(TournamentModel t) {
    // 🔗 나중에 Firebase Dynamic Links 설정 완료 후 해당 주소로 교체하세요.
    final String deepLink = "https://daoapp.page.link/tournament?id=${t.id}";

    final String shareMessage =
        '[DAO 아레나] 새로운 다트 대회가 열렸습니다! 🎯\n\n'
        '🏆 대회명: ${t.title}\n'
        '📍 장소: ${t.location}\n'
        '📅 일시: ${DateFormat('yyyy.MM.dd HH:mm').format(t.eventDate.toDate())}\n'
        '💰 참가비: ${t.entryFee > 0 ? "${NumberFormat('#,###').format(t.entryFee)}원" : "무료"}\n\n'
        '지금 DAO 앱에서 실시간 명단을 확인하고 신청하세요!\n'
        '👉 $deepLink';

    Share.share(shareMessage);
  }

  // 🔐 개인정보 보호를 위한 마스킹 로직
  String _maskName(String name) {
    if (name.isEmpty) return "";
    if (name.length <= 1) return name;
    if (name.length == 2) return "${name[0]}*";
    return "${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}";
  }

  String _maskPhone(String phone) {
    if (phone.length >= 10) {
      if (phone.contains('-')) {
        final parts = phone.split('-');
        if (parts.length == 3) return "${parts[0]}-****-${parts[2]}";
      }
      return "${phone.substring(0, 3)}-****-${phone.substring(phone.length - 4)}";
    }
    return "****";
  }

  String _maskAnswer(String? text) {
    if (text == null || text.isEmpty) return "-";
    if (text.length <= 1) return "*";
    if (text.length == 2) return "${text[0]}*";
    return "${text[0]}${'*' * (text.length - 2)}${text[text.length - 1]}";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).snapshots(),
      builder: (context, snapshot) {
        // 1. 에러가 발생한 경우
        if (snapshot.hasError) {
          return const Scaffold(body: Center(child: Text("데이터 로딩 중 오류가 발생했습니다.")));
        }

        // 2. 로딩 중일 때 (데이터가 아직 안 왔을 때)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.cyan)));
        }

        // 3. ✅ [핵심] 데이터가 없거나 문서가 삭제된 경우
        // 채팅방 공지는 남아있는데 대회가 삭제되었을 때 이쪽으로 들어옵니다.
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.pop(context), // 뒤로가기 가능하게
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    "존재하지 않거나 삭제된 대회입니다. 😅",
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        }

        // 4. 데이터가 정상적으로 있을 때 (기존 로직)
        final t = TournamentModel.fromJson(snapshot.data!.data()!).copyWith(id: snapshot.data!.id);
        final isOrganizer = user != null && (t.createdByUid == user.uid || t.organizerEmails.contains(user.email));
        final canManage = isOrganizer || isAdmin;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: CommonAppBar(
            title: t.title,
            showBackButton: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.ios_share, color: Colors.black, size: 22),
                onPressed: () => _onShareTournament(t),
              ),
              const SizedBox(width: 8),
            ],
          ),
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

              /// ==========================================
              /// 🔥 [정책 준수] 광고 영역 삽입 (포스터 이미지 아래)
              /// ==========================================
              const SizedBox(height: 16),
              Column( // 👈 색상 연산 에러 방지를 위해 여기 const를 뺍니다.
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AD',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[400], // 이제 에러 없이 잘 작동합니다.
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // ✅ [핵심] 상세페이지 전용 ID 타입 지정
                  const AdBanner(type: AdBannerType.detail),
                ],
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

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final e = entries[index];
                final bool isPaid = (e.toJson()['isPaid'] ?? false) || e.status == 'confirmed';
                final bool isMyEntry = user?.uid == e.userUid;

                if (t.type == 'team') {
                  return _buildTeamEntryCard(context, t.id!, e, index, isPaid, canManage, isMyEntry);
                }
                return _buildSingleEntryCard(context, t.id!, e, index, isPaid, canManage, isMyEntry);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSingleEntryCard(BuildContext context, String tid, TournamentEntryModel e, int index, bool isPaid, bool canManage, bool isMyEntry) {
    final bool canSeeAll = canManage || isMyEntry;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            leading: Text("${index + 1}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            title: Row(
              children: [
                Text(canSeeAll ? e.nameKo : _maskName(e.nameKo), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (e.rating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                    child: Text("Rt. ${e.rating}", style: TextStyle(fontSize: 10, color: Colors.cyan[800], fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: Text(canSeeAll ? e.phone : _maskPhone(e.phone), style: const TextStyle(fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPaid) const Icon(Icons.check_circle_rounded, color: Colors.cyan, size: 20)
                else Text("미입금", style: TextStyle(fontSize: 11, color: Colors.grey[350])),
                if (canManage)
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                    onPressed: () => _showEntryManagementSheet(context, tid, e, isPaid),
                  ),
              ],
            ),
          ),
          if (e.customAnswers.isNotEmpty) _buildCustomAnswersView(e.customAnswers, canSeeAll: canSeeAll),
        ],
      ),
    );
  }

  Widget _buildTeamEntryCard(BuildContext context, String tid, TournamentEntryModel e, int index, bool isPaid, bool canManage, bool isMyEntry) {
    final bool canSeeAll = canManage || isMyEntry;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("${index + 1}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8),
              Expanded(child: Text("[팀] ${e.teamName ?? '이름 없음'}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black87))),
              if (isPaid) const Icon(Icons.check_circle_rounded, color: Colors.cyan, size: 20)
              else Text("미입금", style: TextStyle(fontSize: 11, color: Colors.grey[350])),
              if (canManage)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                  onPressed: () => _showEntryManagementSheet(context, tid, e, isPaid),
                ),
            ],
          ),
          const Divider(height: 20),
          _buildMemberRow(
              "팀장: ${canSeeAll ? e.nameKo : _maskName(e.nameKo)} (${canSeeAll ? e.phone : _maskPhone(e.phone)})",
              e.rating,
              isLeader: true
          ),
          if (e.customAnswers.isNotEmpty) _buildCustomAnswersView(e.customAnswers, isTeamMember: true, canSeeAll: canSeeAll),
          const SizedBox(height: 8),
          ...e.members.asMap().entries.map((entry) {
            final m = entry.value;
            final idx = entry.key;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMemberRow("팀원${idx + 1}: ${canSeeAll ? m.name : _maskName(m.name)}", m.rating),
                if (m.customAnswers.isNotEmpty) _buildCustomAnswersView(m.customAnswers, isTeamMember: true, canSeeAll: canSeeAll),
                const SizedBox(height: 6),
              ],
            );
          }),
          if (e.totalRating != null) ...[
            const Divider(height: 16, thickness: 0.5),
            Align(alignment: Alignment.centerRight, child: Text("팀 합계 Rt. ${e.totalRating}", style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold))),
          ]
        ],
      ),
    );
  }

  Widget _buildCustomAnswersView(Map<String, String> answers, {bool isTeamMember = false, bool canSeeAll = false}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(left: isTeamMember ? 20 : 16, right: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(6)),
      child: Wrap(
        spacing: 12, runSpacing: 4,
        children: answers.entries.map((entry) => Text(
          "${entry.key}: ${canSeeAll ? entry.value : _maskAnswer(entry.value)}",
          style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500),
        )).toList(),
      ),
    );
  }

  Widget _buildMemberRow(String name, String? rating, {bool isLeader = false}) {
    return Row(
      children: [
        Icon(Icons.person, size: 12, color: isLeader ? Colors.cyan : Colors.grey[400]),
        const SizedBox(width: 6),
        Expanded(child: Text(name, style: TextStyle(fontSize: 13, fontWeight: isLeader ? FontWeight.bold : FontWeight.normal))),
        if (rating != null) Text("Rt. $rating", style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
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
            Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.edit, size: 16), label: const Text("대회 수정"), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentEditScreen(tournamentId: t.id!))))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: Colors.red), icon: const Icon(Icons.delete_outline, size: 16), label: const Text("대회 삭제"), onPressed: () => _deleteTournament(context, t.id!))),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomEntryAction(BuildContext context, TournamentModel t, User? user, bool canManage) {
    if (user == null) return const SizedBox.shrink();

    // 🕒 현재 시간과 대회 신청 기간 비교
    final now = DateTime.now();
    final startDate = t.entryStartDate.toDate();
    final endDate = t.entryEndDate.toDate();

    final bool isBeforeEntry = now.isBefore(startDate); // 신청 시작 전
    final bool isAfterEntry = now.isAfter(endDate);     // 신청 마감 후

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(t.id)
          .collection('entries')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final hasEntry = snapshot.hasData && snapshot.data!.exists;

        // 🎨 버튼 상태 결정 로직
        String buttonText = "참가 신청하기";
        Color buttonColor = Colors.cyan[700]!;
        bool isButtonEnabled = true;

        if (hasEntry) {
          // 이미 신청한 경우: 기간과 상관없이 언제든 '취소'는 가능하게 (유저 편의성)
          buttonText = "참가 신청 취소하기";
          buttonColor = Colors.grey[800]!;
        } else if (isBeforeEntry) {
          // 신청 시작 전
          buttonText = "신청 기간이 아닙니다";
          buttonColor = Colors.grey[400]!;
          isButtonEnabled = false;
        } else if (isAfterEntry) {
          // 신청 마감 후
          buttonText = "신청이 마감되었습니다";
          buttonColor = Colors.grey[400]!;
          isButtonEnabled = false;
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: ElevatedButton(
              onPressed: isButtonEnabled
                  ? () {
                if (hasEntry) {
                  _cancelMyEntry(context, t.id!, user.uid);
                } else {
                  Navigator.pushNamed(context, RouteConstants.tournamentEntryForm, arguments: t.id);
                }
              }
                  : null, // 비활성화 상태면 클릭 차단
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                disabledBackgroundColor: Colors.grey[300], // 비활성화 시 연한 회색
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isButtonEnabled ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ [수정] 참가자 관리 시트에서 '정보 수정' 메뉴 클릭 시 새로운 화면으로 이동하도록 변경
  void _showEntryManagementSheet(BuildContext context, String tid, TournamentEntryModel e, bool isPaid) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note, color: Colors.blue),
              title: const Text("참가자 정보 수정"),
              onTap: () {
                Navigator.pop(context); // 시트 닫기
                // ✅ 팝업 다이얼로그 대신 새로 만든 '수정 전용 화면'으로 이동!
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TournamentEntryEditScreen(
                      tournamentId: tid,
                      entry: e,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(isPaid ? Icons.money_off : Icons.check_circle, color: isPaid ? Colors.red : Colors.cyan),
              title: Text(isPaid ? "입금 확인 취소" : "입금 확인 처리"),
              onTap: () async {
                await sl<ArenaRepository>().updatePaymentStatus(tid, e.userUid, !isPaid);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text("엔트리 강제 삭제", style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text("엔트리 삭제"), content: Text("${e.nameKo} 참가자를 삭제하시겠습니까?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red)))]));
                if (confirmed == true) await sl<ArenaRepository>().cancelEntry(tournamentId: tid, userUid: e.userUid);
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
        title: const Text("대회 완전 삭제"),
        content: const Text("참가자 명단과 포스터 사진을 포함한 모든 데이터가 영구적으로 삭제됩니다. 정말 진행하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("삭제", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await sl<ArenaRepository>().deleteTournament(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("대회가 완전히 삭제되었습니다.")));
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("삭제 실패: $e")));
        }
      }
    }
  }

  Future<void> _cancelMyEntry(BuildContext context, String tid, String uid) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text("참가 취소"), content: const Text("참가 신청을 취소하시겠습니까?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("아니오")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("취소하기", style: TextStyle(color: Colors.red)))]));
    if (confirmed == true) {
      try {
        await sl<ArenaRepository>().cancelEntry(tournamentId: tid, userUid: uid);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("참가 신청이 취소되었습니다.")));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류가 발생했습니다: $e")));
      }
    }
  }
}