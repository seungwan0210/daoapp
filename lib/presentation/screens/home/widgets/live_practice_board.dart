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
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class LivePracticeBoard extends ConsumerWidget {
  const LivePracticeBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스
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
              Text(s.live_board_title, // 🔹 다국어화
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, RouteConstants.livePracticeFullList),
                child: Row(
                  children: [
                    Text(s.live_board_view_all, style: TextStyle(fontSize: 13, color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. 나의 연습 상태 영역 (로그인/상태 분기)
          authState.when(
            data: (user) {
              if (user == null) return _buildLoginInvite(context);

              return mySessionAsync.when(
                data: (session) {
                  if (session != null && session.isActive) {
                    return _buildMyActiveTimer(context, ref, session);
                  }
                  return _buildStartAction(context, user.uid);
                },
                loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => _buildStartAction(context, user.uid),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // 3. 하단 요약 바: 현재 총 연습 인원 표시
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
                          ? s.live_board_total_count(totalCount.toString()) // 🔹 인자 전달형 다국어
                          : s.live_board_no_user, // 🔹 다국어화
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

  Widget _buildLoginInvite(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return _buildActionCard(
      context,
      title: s.live_board_login_invite,
      buttonText: s.login_title, // 기존에 설정한 login_title 재사용
      onTap: () => Navigator.pushNamed(context, RouteConstants.login),
    );
  }

  Widget _buildStartAction(BuildContext context, String uid) {
    final s = AppLocalizations.of(context)!;
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
              Navigator.pushNamed(context, RouteConstants.profileRegister);
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
                  s.live_board_total_today(_formatDurationSimple(context, totalDurationBefore)), // 🔹 시간 포맷 다국어 대응
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

  // --- 시간 포맷 헬퍼 함수들 ---

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  // 🔹 BuildContext를 추가하여 언어팩을 내부에서 호출하도록 수정
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