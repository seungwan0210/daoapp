import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/providers/practice/practice_provider.dart';
import 'package:daoapp/presentation/screens/home/widgets/practice_setup_bottom_sheet.dart';
import 'package:daoapp/presentation/screens/home/widgets/practice_stop_bottom_sheet.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/practice_session_model.dart';
import 'package:daoapp/l10n/app_localizations.dart';

class LivePracticeBoard extends ConsumerWidget {
  const LivePracticeBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);
    final mySessionAsync = ref.watch(myPracticeSessionProvider);
    final totalCount = ref.watch(totalPracticingCountProvider).value ?? 0;
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더: 타이틀 및 전체보기 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.live_board_title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, RouteConstants.livePracticeFullList),
                child: Row(
                  children: [
                    Text(s.live_board_view_all,
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. 나의 연습 상태 영역 (소프트 게이트 적용)
          authState.when(
            data: (user) {
              // ✅ 로그인 안 된 유저도 '연습 시작' 유도 카드를 보여주되, 클릭 시 팝업 발생
              if (user == null) {
                return _buildStartInviteAction(context, s, null);
              }

              return mySessionAsync.when(
                data: (session) {
                  if (session != null && session.isActive) {
                    return _buildMyActiveTimer(context, ref, session);
                  }
                  return _buildStartInviteAction(context, s, user.uid);
                },
                loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => _buildStartInviteAction(context, s, user.uid),
              );
            },
            loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // 3. 하단 요약 바
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, RouteConstants.livePracticeFullList),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      totalCount > 0
                          ? s.live_board_total_count(totalCount.toString())
                          : s.live_board_no_user,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 통합된 시작 유도 액션 (비로그인/로그인/프로필미등록 대응)
  Widget _buildStartInviteAction(BuildContext context, AppLocalizations s, String? uid) {
    if (uid == null) {
      // 1. 비로그인 상태
      return _buildActionCard(
        context,
        title: s.live_board_start_invite, // "연습을 시작하고 기록을 남겨보세요!"
        buttonText: s.live_board_btn_start,
        onTap: () => _showPromptDialog(
            context,
            s.community_home_login_prompt,
            Icons.people_alt_outlined,
            RouteConstants.login
        ),
        isHighlight: true,
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        final hasProfile = snapshot.data?.get('hasProfile') ?? false;

        return _buildActionCard(
          context,
          title: hasProfile ? s.live_board_start_invite : s.live_board_profile_invite,
          buttonText: hasProfile ? s.live_board_btn_start : s.live_board_btn_profile,
          onTap: () {
            if (hasProfile) {
              _showSetupSheet(context, snapshot.data?.data() as Map<String, dynamic>);
            } else {
              // 2. 프로필 미등록 상태 유도 팝업
              _showPromptDialog(
                  context,
                  s.community_home_verify_prompt,
                  Icons.verified_user_outlined,
                  RouteConstants.profileRegister
              );
            }
          },
          isHighlight: hasProfile,
        );
      },
    );
  }

  Widget _buildMyActiveTimer(BuildContext context, WidgetRef ref, PracticeSessionModel session) {
    final s = AppLocalizations.of(context)!;
    final timerDuration = ref.watch(practiceTimerProvider).value ?? Duration.zero;
    final totalDurationBefore = Duration(milliseconds: session.totalDurationBefore);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.cyanAccent, size: 14),
                    const SizedBox(width: 4),
                    Text('${session.shopName ?? session.machineType}',
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(timerDuration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.live_board_total_today(_formatDurationSimple(context, totalDurationBefore)),
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showStopConfirm(context, ref, session),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(s.live_board_btn_stop, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required String title,
    required String buttonText,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              minimumSize: const Size(180, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ✅ 커뮤니티 홈에서 사용한 것과 동일한 다이얼로그 유도 로직
  void _showPromptDialog(BuildContext context, String title, IconData icon, String route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, route);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("이동하기"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetupSheet(BuildContext context, Map<String, dynamic> userData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PracticeSetupBottomSheet(userData: userData),
    );
  }

  void _showStopConfirm(BuildContext context, WidgetRef ref, PracticeSessionModel session) {
    final timerDuration = ref.read(practiceTimerProvider).value ?? Duration.zero;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PracticeStopBottomSheet(
        session: session,
        finalDuration: timerDuration,
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  String _formatDurationSimple(BuildContext context, Duration d) {
    final s = AppLocalizations.of(context)!;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);

    if (hours > 0) {
      return "${s.common_hour(hours.toString())} ${s.common_minute(minutes.toString())}";
    }
    return s.common_minute(minutes.toString());
  }
}