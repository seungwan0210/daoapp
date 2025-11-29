// lib/presentation/widgets/guestbook_header.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuestbookHeader extends StatelessWidget {
  final String userId;
  const GuestbookHeader({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 프로필 사진
              GestureDetector(
                onTap: photoUrl?.isNotEmpty == true
                    ? () => _showFullImage(context, photoUrl!)
                    : null,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
                  child: photoUrl?.isNotEmpty != true
                      ? const Icon(Icons.person, size: 48, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 12),

              // 이름
              Text(koreanName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (englishName?.isNotEmpty == true)
                Text(englishName!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              if (shopName?.isNotEmpty == true)
                Text('· $shopName', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary)),

              // 배럴 정보 섹션 (조건부 렌더링 + 부드러운 디자인)
              if (hasBarrelInfo) ...[
                const SizedBox(height: 16),
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

  // 배럴 정보 섹션 (재사용 가능 + 깔끔한 디자인)
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 + 아이콘
          Row(
            children: [
              Icon(Icons.sports_esports, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '플레이어 장비',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 배럴 사진
          if (barrelImageUrl?.isNotEmpty == true)
            Center(
              child: GestureDetector(
                onTap: () => _showFullImage(context, barrelImageUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    barrelImageUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          if (barrelImageUrl?.isNotEmpty == true) const SizedBox(height: 10),

          // 정보 리스트
          if (barrelName.isNotEmpty) _infoRow('배럴', barrelName),
          if (shaft.isNotEmpty) _infoRow('샤프트', shaft),
          if (flight.isNotEmpty) _infoRow('플라이트', flight),
          if (tip.isNotEmpty) _infoRow('팁', tip),
        ],
      ),
    );
  }

  // 사진 확대
  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 정보 행
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}