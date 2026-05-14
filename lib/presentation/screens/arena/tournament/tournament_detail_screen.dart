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
import 'package:share_plus/share_plus.dart';

import 'package:daoapp/presentation/widgets/ad_banner.dart';
import 'package:daoapp/core/utils/ad_manager.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class TournamentDetailScreen extends ConsumerWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  void _onShareTournament(BuildContext context, TournamentModel t) {
    final s = AppLocalizations.of(context)!;
    final String deepLink = "https://daoapp-c0527.web.app/tournament?id=${t.id}";
    final String dateStr = DateFormat('yyyy.MM.dd HH:mm').format(t.eventDate.toDate());
    final String feeStr = t.entryFee > 0 ? "${NumberFormat('#,###').format(t.entryFee)}${s.common_currency_won}" : s.common_free;

    final String shareMessage =
        '${s.tournament_detail_share_title}\n\n'
        '${s.tournament_detail_share_info(t.title, t.location, dateStr, feeStr)}\n\n'
        '${s.tournament_detail_share_footer}\n'
        '👉 $deepLink';

    Share.share(shareMessage);
  }

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
    final s = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Scaffold(body: Center(child: Text(s.tournament_detail_loading_error)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.cyan)));

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(s.tournament_detail_not_found, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }

        final t = TournamentModel.fromJson(snapshot.data!.data()!).copyWith(id: snapshot.data!.id);
        final isOrganizer = user != null && (t.createdByUid == user.uid || t.organizerEmails.contains(user.email));
        final canManage = isOrganizer || isAdmin;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: CommonAppBar(
            title: t.title,
            showBackButton: true,
            actions: [
              IconButton(icon: const Icon(Icons.ios_share, color: Colors.black, size: 22), onPressed: () => _onShareTournament(context, t)),
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
                    child: CachedNetworkImage(imageUrl: t.posterUrl!, fit: BoxFit.contain, placeholder: (_, __) => Container(height: 200, color: Colors.grey[100])),
                  ),
                ),
              const SizedBox(height: 16),
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('AD', style: TextStyle(fontSize: 9, color: Colors.grey, letterSpacing: 1.0, fontWeight: FontWeight.w500)),
                  SizedBox(height: 2),
                  AdBanner(type: AdBannerType.detail),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  EntryStatusBadge(tournament: t),
                  Text(s.tournament_detail_entry_count(t.entryCount.toString(), t.maxParticipants >= 9999 ? '∞' : t.maxParticipants.toString()), style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
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
                      _buildInfoRow(Icons.location_on_outlined, s.tournament_edit_field_location, t.location),
                      const Divider(height: 24, thickness: 0.5),
                      _buildInfoRow(Icons.calendar_month_outlined, s.arena_menu_schedule, DateFormat('yyyy.MM.dd HH:mm').format(t.eventDate.toDate())),
                      const Divider(height: 24, thickness: 0.5),
                      _buildInfoRow(Icons.paid_outlined, s.tournament_edit_field_fee, t.entryFee > 0 ? "${NumberFormat('#,###').format(t.entryFee)}${s.common_currency_won}" : s.common_free),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(s.tournament_detail_info_title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(t.description.isEmpty ? s.tournament_detail_no_desc : t.description, style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),
                ),
              ),
              const SizedBox(height: 32),
              _buildParticipantSection(context, t, user, canManage, s),
              const SizedBox(height: 32),
              if (canManage) _buildAdminActions(context, t, isAdmin, s),
            ],
          ),
          bottomNavigationBar: _buildBottomEntryAction(context, t, user, canManage, s),
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

  Widget _buildParticipantSection(BuildContext context, TournamentModel t, User? user, bool canManage, AppLocalizations s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.tournament_detail_list_title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        StreamBuilder<List<TournamentEntryModel>>(
          stream: sl<ArenaRepository>().getEntries(t.id!),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final entries = snapshot.data!;
            if (entries.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text(s.tournament_detail_no_entries, style: TextStyle(color: Colors.grey[400], fontSize: 13))));

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final e = entries[index];
                final bool isPaid = (e.toJson()['isPaid'] ?? false) || e.status == 'confirmed';
                final bool isMyEntry = user?.uid == e.userUid;

                if (t.type == 'team') return _buildTeamEntryCard(context, t.id!, e, index, isPaid, canManage, isMyEntry, s);
                return _buildSingleEntryCard(context, t.id!, e, index, isPaid, canManage, isMyEntry, s);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSingleEntryCard(BuildContext context, String tid, TournamentEntryModel e, int index, bool isPaid, bool canManage, bool isMyEntry, AppLocalizations s) {
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
                Flexible(
                  child: Text(
                    canSeeAll ? e.nameKo : _maskName(e.nameKo),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (e.isManual) Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)), child: Text(s.entry_list_manual, style: const TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                if (e.rating != null) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)), child: Text("Rt. ${e.rating}", style: TextStyle(fontSize: 10, color: Colors.cyan[800], fontWeight: FontWeight.bold))),
              ],
            ),
            subtitle: Text(
              canSeeAll ? e.phone : _maskPhone(e.phone),
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPaid) const Icon(Icons.check_circle_rounded, color: Colors.cyan, size: 20) else Text(s.entry_list_not_paid, style: TextStyle(fontSize: 11, color: Colors.grey[350])),
                if (canManage) IconButton(icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey), onPressed: () => _showEntryManagementSheet(context, tid, e, isPaid, s)),
              ],
            ),
          ),
          if (e.customAnswers.isNotEmpty) _buildCustomAnswersView(e.customAnswers, canSeeAll: canSeeAll),
        ],
      ),
    );
  }

  Widget _buildTeamEntryCard(BuildContext context, String tid, TournamentEntryModel e, int index, bool isPaid, bool canManage, bool isMyEntry, AppLocalizations s) {
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
              Expanded(
                  child: Text(
                    s.entry_list_team_prefix(e.teamName ?? ''),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )
              ),
              if (e.isManual) Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)), child: Text(s.entry_list_manual, style: const TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold))),
              if (isPaid) const Icon(Icons.check_circle_rounded, color: Colors.cyan, size: 20) else Text(s.entry_list_not_paid, style: TextStyle(fontSize: 11, color: Colors.grey[350])),
              if (canManage) IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey), onPressed: () => _showEntryManagementSheet(context, tid, e, isPaid, s)),
            ],
          ),
          const Divider(height: 20),
          _buildMemberRow("${s.entry_list_info_leader}: ${canSeeAll ? e.nameKo : _maskName(e.nameKo)} (${canSeeAll ? e.phone : _maskPhone(e.phone)})", e.rating, isLeader: true),
          if (e.customAnswers.isNotEmpty) _buildCustomAnswersView(e.customAnswers, isTeamMember: true, canSeeAll: canSeeAll),
          const SizedBox(height: 8),
          ...e.members.asMap().entries.map((entry) {
            final m = entry.value;
            final idx = entry.key;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildMemberRow("${s.entry_form_field_member_no(idx + 1)}: ${canSeeAll ? m.name : _maskName(m.name)}", m.rating), if (m.customAnswers.isNotEmpty) _buildCustomAnswersView(m.customAnswers, isTeamMember: true, canSeeAll: canSeeAll), const SizedBox(height: 6)]);
          }),
          if (e.totalRating != null) ...[const Divider(height: 16, thickness: 0.5), Align(alignment: Alignment.centerRight, child: Text(s.entry_list_total_rating(e.totalRating!), style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold)))]
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
      child: Wrap(spacing: 12, runSpacing: 4, children: answers.entries.map((entry) => Text("${entry.key}: ${canSeeAll ? entry.value : _maskAnswer(entry.value)}", style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500))).toList()),
    );
  }

  Widget _buildMemberRow(String name, String? rating, {bool isLeader = false}) {
    return Row(children: [Icon(Icons.person, size: 12, color: isLeader ? Colors.cyan : Colors.grey[400]), const SizedBox(width: 6), Expanded(child: Text(name, style: TextStyle(fontSize: 13, fontWeight: isLeader ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis, maxLines: 1)), if (rating != null) Text("Rt. $rating", style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500))]);
  }

  Widget _buildAdminActions(BuildContext context, TournamentModel t, bool isAdmin, AppLocalizations s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        Text(isAdmin ? s.common_admin_authority : s.tournament_detail_admin_title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.edit, size: 16), label: Text(s.tournament_edit_title), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentEditScreen(tournamentId: t.id!))))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: Colors.red), icon: const Icon(Icons.delete_outline, size: 16), label: Text(s.tournament_detail_admin_delete), onPressed: () => _deleteTournament(context, t.id!, s))),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomEntryAction(BuildContext context, TournamentModel t, User? user, bool canManage, AppLocalizations s) {
    if (user == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final startDate = t.entryStartDate.toDate();
    final endDate = t.entryEndDate.toDate();
    final bool isBeforeEntry = now.isBefore(startDate);
    final bool isAfterEntry = now.isAfter(endDate);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('tournaments').doc(t.id).collection('entries').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final hasEntry = snapshot.hasData && snapshot.data!.exists;
        String buttonText = s.tournament_detail_btn_apply;
        Color buttonColor = Colors.cyan[700]!;
        bool isButtonEnabled = true;

        if (hasEntry) {
          buttonText = s.tournament_detail_btn_cancel;
          buttonColor = Colors.grey[800]!;
        } else if (isBeforeEntry) {
          buttonText = s.tournament_detail_btn_not_period;
          buttonColor = Colors.grey[400]!;
          isButtonEnabled = false;
        } else if (isAfterEntry) {
          buttonText = s.tournament_detail_btn_closed;
          buttonColor = Colors.grey[400]!;
          isButtonEnabled = false;
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canManage) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, RouteConstants.tournamentEntryForm, arguments: {'tournamentId': t.id, 'isManualMode': true}),
                      icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
                      label: Text(s.tournament_detail_btn_manual, style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: Colors.cyan[800],
                        side: BorderSide(color: Colors.cyan[700]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isButtonEnabled
                        ? () {
                      if (hasEntry) _cancelMyEntry(context, t.id!, user.uid, s);
                      else Navigator.pushNamed(context, RouteConstants.tournamentEntryForm, arguments: t.id);
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(buttonText, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isButtonEnabled ? Colors.white : Colors.grey[600])),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEntryManagementSheet(BuildContext context, String tid, TournamentEntryModel e, bool isPaid, AppLocalizations s) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note, color: Colors.blue),
              title: Text(s.tournament_detail_manage_edit),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => TournamentEntryEditScreen(tournamentId: tid, entry: e)));
              },
            ),
            ListTile(
              leading: Icon(isPaid ? Icons.money_off : Icons.check_circle, color: isPaid ? Colors.red : Colors.cyan),
              title: Text(isPaid ? s.tournament_detail_manage_pay_off : s.tournament_detail_manage_pay_on),
              onTap: () async {
                await sl<ArenaRepository>().updatePaymentStatus(tid, e.id ?? e.userUid, !isPaid);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: Text(s.tournament_detail_manage_delete, style: const TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: Text(s.entry_list_delete_confirm_title), content: Text(s.entry_list_delete_confirm_msg(e.nameKo)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.common_cancel)), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.common_delete, style: const TextStyle(color: Colors.red)))]));
                if (confirmed == true) await sl<ArenaRepository>().cancelEntry(tournamentId: tid, userUid: e.id ?? e.userUid);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTournament(BuildContext context, String id, AppLocalizations s) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: Text(s.tournament_detail_admin_delete), content: Text(s.tournament_detail_admin_delete_msg), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.common_cancel)), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.common_delete, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))]));
    if (confirmed == true) {
      try {
        await sl<ArenaRepository>().deleteTournament(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.tournament_detail_admin_delete))); // 혹은 삭제 완료 메시지
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _cancelMyEntry(BuildContext context, String tid, String uid, AppLocalizations s) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: Text(s.entry_form_cancel_title), content: Text(s.entry_form_cancel_msg), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.common_no)), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.entry_form_cancel_confirm, style: const TextStyle(color: Colors.red)))]));
    if (confirmed == true) {
      try {
        await sl<ArenaRepository>().cancelEntry(tournamentId: tid, userUid: uid);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.entry_form_cancel_success)));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}