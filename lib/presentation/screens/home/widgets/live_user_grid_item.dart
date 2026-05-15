import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/data/models/practice_session_model.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/l10n/app_localizations.dart';

class LiveUserGridItem extends ConsumerWidget {
  final PracticeSessionModel session;
  final bool isBlur;

  const LiveUserGridItem({
    super.key,
    required this.session,
    this.isBlur = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    // 로그인 및 프로필 정보 확인 (유도 팝업용)
    final isLoggedIn = authState.value != null;

    final bool isLive = session.isActive && !session.isPaused;
    final double opacity = isLive ? 1.0 : 0.6;

    // 실시간 순위 정보
    final totalRanking = ref.watch(totalRankingProvider);
    final rankIndex = totalRanking.indexWhere((item) => item['userId'] == session.uid);
    final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;

    // 시간 데이터 계산
    final totalDuration = session.getTodayTotalDuration();
    final currentDuration = isLive
        ? DateTime.now().difference(session.startTime)
        : Duration.zero;

    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: () {
          if (!isLoggedIn) {
            _showPromptDialog(
                context,
                s.community_home_login_prompt,
                Icons.people_alt_outlined,
                RouteConstants.login
            );
          } else if (isBlur) {
            // 로그인 상태인데 Blur라면 프로필 미등록 상태임
            _showPromptDialog(
                context,
                s.community_home_verify_prompt,
                Icons.verified_user_outlined,
                RouteConstants.profileRegister
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: isLive
                ? Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 1.2)
                : Border.all(color: Colors.white.withOpacity(0.05), width: 1),
            boxShadow: isLive ? [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 1,
              )
            ] : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- 프로필 이미지 및 배지 영역 ---
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF0F172A),
                    backgroundImage: session.profileUrl != null
                        ? NetworkImage(session.profileUrl!)
                        : null,
                    child: session.profileUrl == null
                        ? const Icon(Icons.person, color: Colors.grey, size: 20)
                        : null,
                  ),
                  if (currentRank != null)
                    Positioned(
                      left: -6,
                      top: -6,
                      child: BadgeWidget(rank: currentRank, size: 18),
                    ),
                  if (isLive)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1E293B), width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // 닉네임
              Text(
                session.nickname,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // 현재 세션 시간
              Text(
                isBlur ? "**:***" : _formatDuration(currentDuration),
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),

              // 오늘 총 누적 시간 (다국어 대응)
              if (!isBlur)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.whatshot, size: 9, color: Colors.orangeAccent.withOpacity(0.8)),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          s.live_total_time(_formatDurationSimple(context, totalDuration)),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 4),

              // 장소/기기 정보
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isBlur ? "****" : (session.shopName ?? session.machineType),
                    style: TextStyle(color: Colors.grey[400], fontSize: 8),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 유도 팝업 다이얼로그
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

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
  }

  String _formatDurationSimple(BuildContext context, Duration d) {
    final s = AppLocalizations.of(context)!;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);

    if (h > 0) {
      return "${s.common_hour(h.toString())} ${s.common_minute(m.toString())}";
    }
    return s.common_minute(m.toString());
  }
}