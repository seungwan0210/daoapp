import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/data/models/practice_session_model.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/utils/badge_utils.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    // 1. 상태 및 랭킹 데이터 가져오기
    final bool isLive = session.isActive && !session.isPaused;
    final double opacity = isLive ? 1.0 : 0.6;

    // 실시간 순위 정보 (참고 코드의 랭킹 프로바이더 로직 적용)
    final totalRanking = ref.watch(totalRankingProvider);
    final rankIndex = totalRanking.indexWhere((item) => item['userId'] == session.uid);
    final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;

    // 2. 시간 데이터 계산 (모델의 메서드 활용)
    final totalDuration = session.getTodayTotalDuration();
    final currentDuration = isLive
        ? DateTime.now().difference(session.startTime)
        : Duration.zero;

    return Opacity(
      opacity: opacity,
      child: Container(
        // ✅ [오버플로우 해결] 패딩 최적화
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

                // ✅ 실시간 랭킹 배지 (좌측 상단 배치)
                if (currentRank != null)
                  Positioned(
                    left: -6,
                    top: -6,
                    child: BadgeWidget(rank: currentRank, size: 18),
                  ),

                // ✅ 라이브 상태 점 (우측 하단)
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
            const SizedBox(height: 6), // ✅ 간격 축소

            // 닉네임
            Text(
              session.nickname,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12, // ✅ 폰트 축소
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // 현재 세션 시간 (메인 타이머)
            Text(
              isBlur ? "**:***" : _formatDuration(currentDuration),
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 13, // ✅ 폰트 축소
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),

            // 오늘 총 누적 시간 (서브 정보)
            if (!isBlur)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.whatshot, size: 9, color: Colors.orangeAccent.withOpacity(0.8)),
                    const SizedBox(width: 2),
                    Text(
                      _formatDurationSimple(totalDuration),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 8, // ✅ 폰트 축소
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 4),

            // ✅ [오버플로우 해결] Flexible 적용 및 텍스트 최적화
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
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
  }

  String _formatDurationSimple(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return "Total ${h}h ${m}m";
    return "Total ${m}m";
  }
}