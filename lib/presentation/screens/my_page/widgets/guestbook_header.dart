// lib/presentation/widgets/guestbook_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🆕 추가
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
// ✅ 수정 코드 (랭킹 프로바이더 하나로 통합)
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';

class GuestbookHeader extends ConsumerWidget { // 👈 ConsumerWidget으로 변경
  final String userId;
  const GuestbookHeader({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // 👈 WidgetRef 추가
    // 1. 실시간 통합 랭킹 데이터 구독 (방 주인의 순위 확인용)
    final totalRanking = ref.watch(totalRankingProvider);
    final rankIndex = totalRanking.indexWhere((item) => item['userId'] == userId);
    final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 80);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final photoUrl = data['profileImageUrl'] as String?;
        final koreanName = data['koreanName']?.toString().trim() ?? '이름 없음';
        final englishName = data['englishName']?.toString().trim();
        final shopName = data['shopName']?.toString().trim();

        // 배럴 정보 추출
        final barrelName = data['barrelName']?.toString().trim() ?? '';
        final shaft = data['shaft']?.toString().trim() ?? '';
        final flight = data['flight']?.toString().trim() ?? '';
        final tip = data['tip']?.toString().trim() ?? '';
        final barrelImageUrl = data['barrelImageUrl'] as String?;

        final hasBarrelInfo = barrelName.isNotEmpty ||
            shaft.isNotEmpty ||
            flight.isNotEmpty ||
            tip.isNotEmpty ||
            (barrelImageUrl?.isNotEmpty == true);

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 2. 프로필 사진 + 실시간 배지 (중앙 정렬 Stack)
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: photoUrl?.isNotEmpty == true
                        ? () => _showFullImage(context, photoUrl!)
                        : null,
                    child: CircleAvatar(
                      radius: 45, // 크기를 살짝 키움
                      backgroundColor: Colors.grey[200],
                      backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
                      child: photoUrl?.isNotEmpty != true
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                  ),
                  // 🔥 실시간 랭킹 배지 (사진 좌측 상단에 배치)
                  if (currentRank != null)
                    Positioned(
                      left: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: BadgeWidget(rank: currentRank, size: 28),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // 이름 및 샵 정보
              Text(koreanName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (englishName?.isNotEmpty == true)
                Text(englishName!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              if (shopName?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('· $shopName',
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                ),

              // 3. 배럴 정보 섹션
              if (hasBarrelInfo) ...[
                const SizedBox(height: 20),
                _buildBarrelSection(
                  context: context,
                  barrelImageUrl: barrelImageUrl,
                  barrelName: barrelName,
                  shaft: shaft,
                  flight: flight,
                  tip: tip,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBarrelSection({
    required BuildContext context,
    required String? barrelImageUrl,
    required String barrelName,
    required String shaft,
    required String flight,
    required String tip,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.military_tech, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'PLAYERS_DART',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (barrelImageUrl?.isNotEmpty == true)
                GestureDetector(
                  onTap: () => _showFullImage(context, barrelImageUrl!),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(barrelImageUrl!, width: 70, height: 70, fit: BoxFit.cover),
                    ),
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    if (barrelName.isNotEmpty) _infoRow('BARREL', barrelName),
                    if (shaft.isNotEmpty) _infoRow('SHAFT', shaft),
                    if (flight.isNotEmpty) _infoRow('FLIGHT', flight),
                    if (tip.isNotEmpty) _infoRow('TIP', tip),
                  ],
                ),
              ),
            ],
          ),
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
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 55,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}