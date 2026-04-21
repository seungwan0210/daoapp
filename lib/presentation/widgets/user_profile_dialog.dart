import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/utils/badge_utils.dart';
// ✅ 수정 코드 (랭킹 프로바이더 하나로 통합)
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';

class UserProfileDialog extends ConsumerWidget {
  final String koreanName;
  final String? englishName;
  final String? photoUrl;
  final String? shopName;
  final Map<String, dynamic>? barrelData;
  final bool isMe;
  final String userId;

  const UserProfileDialog({
    super.key,
    required this.koreanName,
    this.englishName,
    this.photoUrl,
    this.shopName,
    this.barrelData,
    required this.isMe,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 1. 실시간 통합 랭킹 데이터 구독
    final totalRanking = ref.watch(totalRankingProvider);
    final rankIndex = totalRanking.indexWhere((item) => item['userId'] == userId);
    final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

              // 🔥 배럴 데이터 복구: 인자로 들어온게 없으면 DB에서 직접 파싱
              final bName = (barrelData?['barrelName'] ?? data['barrelName'])?.toString().trim() ?? '';
              final bImage = (barrelData?['barrelImageUrl'] ?? data['barrelImageUrl'])?.toString().trim() ?? '';
              final bShaft = (barrelData?['shaft'] ?? data['shaft'])?.toString().trim() ?? '';
              final bFlight = (barrelData?['flight'] ?? data['flight'])?.toString().trim() ?? '';
              final bTip = (barrelData?['tip'] ?? data['tip'])?.toString().trim() ?? '';

              final hasBarrelInfo = bName.isNotEmpty || bShaft.isNotEmpty || bFlight.isNotEmpty || bTip.isNotEmpty || bImage.isNotEmpty;

              // 배지 추출
              final badgesMap = BadgeUtils.extractBadges(data);
              final badgeKeys = BadgeUtils.extractActiveBadges(badgesMap);

              // 보여줄 배지 위젯 리스트 생성 (실시간 우선)
              final List<Widget> badgeWidgets = [];
              if (currentRank != null) {
                badgeWidgets.add(BadgeWidget(rank: currentRank, size: 24));
              }
              for (var key in badgeKeys) {
                if (badgeWidgets.length >= 2) break;
                badgeWidgets.add(BadgeWidget(badgeKey: key, size: 24));
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. 상단: 아바타 + 배지 (옆으로 붙임)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: photoUrl?.isNotEmpty == true ? () => _showFullImage(context, photoUrl!) : null,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
                            child: photoUrl?.isNotEmpty != true ? const Icon(Icons.person, size: 60) : null,
                          ),
                        ),
                        // 배지 아이콘들을 사진 좌측 상단에 겹쳐서 표시
                        ...badgeWidgets.asMap().entries.map((entry) {
                          final idx = entry.key;
                          return Positioned(
                            left: -10 - (idx * 20),
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)]),
                              child: entry.value,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 2. 이름 및 소속
                    Text(koreanName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (englishName?.isNotEmpty == true)
                      Text(englishName!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    if (shopName?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('· $shopName', style: TextStyle(fontSize: 14, color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                      ),

                    // 3. 배럴 정보 섹션 (데이터가 있을 때만 노출)
                    if (hasBarrelInfo) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text('PLAYERS_DART', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary)),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (bImage.isNotEmpty)
                            GestureDetector(
                              onTap: () => _showFullImage(context, bImage),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(bImage, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (bName.isNotEmpty) _infoRow('BARREL', bName),
                                if (bShaft.isNotEmpty) _infoRow('SHAFT', bShaft),
                                if (bFlight.isNotEmpty) _infoRow('FLIGHT', bFlight),
                                if (bTip.isNotEmpty) _infoRow('TIP', bTip),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 4. 하단 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.create, size: 18),
                        label: Text(isMe ? "내 방명록 가기" : "방명록 쓰러 가기"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, RouteConstants.guestbook, arguments: userId);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("닫기")),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain))),
            Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(ctx))),
          ],
        ),
      ),
    );
  }
}