import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/l10n/app_localizations.dart';
import 'package:daoapp/presentation/providers/locale_provider.dart'; // 로케일 프로바이더
import 'package:daoapp/presentation/screens/my_page/notice_detail_screen.dart'; // 상세화면 임포트

class NoticeListScreen extends ConsumerStatefulWidget {
  const NoticeListScreen({super.key});

  @override
  ConsumerState<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends ConsumerState<NoticeListScreen> {
  // 읽음 여부 캐시 (성능 향상)
  final Map<String, bool> _readStatusCache = {};

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    // 현재 앱의 언어 설정 가져오기 (ko, en, ja 등)
    final currentLocale = ref.watch(localeProvider);
    final langCode = currentLocale.languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // 🔥 키값 적용: notice_title
      appBar: CommonAppBar(title: s.notice_title, showBackButton: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notices')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // 🔥 키값 적용: notice_error (변수 포함)
            return Center(child: Text(s.notice_error(snapshot.error.toString())));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            // 🔥 키값 적용: notice_empty
            return Center(child: Text(s.notice_empty));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id;

              // 💡 다국어 제목 추출 로직
              final Map<String, dynamic> langs = data['langs'] ?? {};
              // 현재 언어 데이터가 없으면 한국어(ko)를 기본값으로 사용
              // 🔥 키값 적용: notice_no_title (백업용)
              final String title = langs[langCode]?['title'] ??
                  langs['ko']?['title'] ??
                  s.notice_no_title;

              final timestamp = (data['createdAt'] as Timestamp?)?.toDate();
              final isUnread = _isUnread(docId);
              final hasImages = (data['imageUrls'] as List?)?.isNotEmpty ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: isUnread
                      ? Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  )
                      : null,
                  title: Row(
                    children: [
                      if (hasImages)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.image, size: 16, color: Colors.grey),
                        ),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                            color: isUnread ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: timestamp != null
                      ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      AppDateUtils.formatRelativeTime(timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnread ? Colors.grey[700] : Colors.grey[500],
                      ),
                    ),
                  )
                      : null,
                  trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                  onTap: () async {
                    final user = FirebaseAuth.instance.currentUser;

                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('readNotices')
                          .doc(docId)
                          .set({'timestamp': FieldValue.serverTimestamp()});

                      if (mounted) {
                        setState(() => _readStatusCache[docId] = false);
                        ref.invalidate(unreadNoticesCountProvider);
                      }
                    }

                    // ✅ 상세 화면으로 이동
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoticeDetailScreen(noticeData: data),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 읽음 여부 확인 (캐시 + 비로그인 처리)
  bool _isUnread(String docId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return true; // 비로그인 → 항상 안 읽음

    // 캐시 확인
    if (_readStatusCache.containsKey(docId)) {
      return !_readStatusCache[docId]!;
    }

    // 초기값 (기본값: 안 읽음)
    _readStatusCache[docId] = true;

    // 비동기로 실제 읽음 여부 확인
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('readNotices')
        .doc(docId)
        .get()
        .then((readDoc) {
      if (mounted) {
        setState(() {
          _readStatusCache[docId] = readDoc.exists;
        });
      }
    });

    return true; // 초기값
  }
}