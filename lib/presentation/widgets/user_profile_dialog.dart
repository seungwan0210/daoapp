// lib/presentation/widgets/user_profile_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/utils/badge_utils.dart'; // 추가

class UserProfileDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .snapshots(),
            builder: (context, snapshot) {
              Map<String, dynamic> userData = {};
              Map<String, dynamic> badges = {};

              if (snapshot.hasData && snapshot.data!.data() != null) {
                userData = snapshot.data!.data() as Map<String, dynamic>;
                badges = BadgeUtils.extractBadges(userData); // 통일된 추출
              }

              final badgeKeys = BadgeUtils.extractActiveBadges(badges); // 최신순 정렬

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 프로필 사진 (클릭 → 확대)
                    GestureDetector(
                      onTap: photoUrl?.isNotEmpty == true
                          ? () => _showFullImage(context, photoUrl!)
                          : null,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: photoUrl?.isNotEmpty == true
                            ? NetworkImage(photoUrl!)
                            : null,
                        child: photoUrl?.isNotEmpty != true
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 이름 + 영어 이름 + 샵
                    Text(
                      koreanName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    if (englishName?.isNotEmpty == true)
                      Text(
                        englishName!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    if (shopName?.isNotEmpty == true)
                      Text(
                        '· $shopName',
                        style: TextStyle(fontSize: 14, color: theme.colorScheme.primary),
                        textAlign: TextAlign.center,
                      ),

                    // 배지 (최대 4개, 툴팁 포함)
                    if (badgeKeys.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: badgeKeys.take(4).map((key) {
                          return Tooltip(
                            message: BadgeUtils.getBadgeTooltip(key),
                            child: BadgeWidget(badgeKey: key, size: 24),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // 배럴 정보
                    if (barrelData != null) ...[
                      const Divider(height: 24),
                      const Text(
                        'PLAYERS_DART',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      if (barrelData!['barrelImageUrl']?.isNotEmpty == true)
                        Center(
                          child: GestureDetector(
                            onTap: () => _showFullImage(context, barrelData!['barrelImageUrl']),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                barrelData!['barrelImageUrl'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (barrelData!['barrelName']?.isNotEmpty == true)
                        _infoRow('BARREL', barrelData!['barrelName']),
                      if (barrelData!['shaft']?.isNotEmpty == true)
                        _infoRow('SHAFT', barrelData!['shaft']),
                      if (barrelData!['flight']?.isNotEmpty == true)
                        _infoRow('FLIGHT', barrelData!['flight']),
                      if (barrelData!['tip']?.isNotEmpty == true)
                        _infoRow('TIP', barrelData!['tip']),
                    ],
                    const SizedBox(height: 20),

                    // 방명록 버튼
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
                    const SizedBox(height: 12),
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

  void _showFullImage(BuildContext context, String url) {
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = screenSize.width * 0.9;
    final maxHeight = screenSize.height * 0.7;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.8,
                maxScale: 2.5,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) =>
                      loadingProgress == null
                          ? child
                          : Container(
                        width: maxWidth,
                        height: maxHeight * 0.6,
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
                        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                      ),
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: maxWidth,
                        height: maxHeight * 0.6,
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error, color: Colors.white70, size: 48),
                            SizedBox(height: 12),
                            Text('이미지를 불러올 수 없어요', style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}