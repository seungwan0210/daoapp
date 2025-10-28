// lib/presentation/providers/user_home_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _firestore = FirebaseFirestore.instance;

/// TOP3 랭킹 - 통합 리더보드
final top3Provider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  return _firestore
      .collection('leaderboards_integrated')
      .orderBy('totalPoints', descending: true)
      .limit(3)
      .snapshots();
});

/// 다음 예정 경기
final nextEventProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  return _firestore
      .collection('events')
      .where('status', isEqualTo: 'scheduled')
      .orderBy('date', descending: false) // 가장 이른 날짜
      .limit(1)
      .snapshots();
});

/// 공지 배너 - 활성화된 공지만, 최신순
final noticeBannerProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  return _firestore
      .collection('notices')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots();
});

/// 최신 뉴스 - 최대 5개
final newsProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  return _firestore
      .collection('news')
      .where('isActive', isEqualTo: true) // 비활성화 뉴스 제외
      .orderBy('createdAt', descending: true)
      .limit(5)
      .snapshots();
});

/// 스폰서 배너 - 활성화된 스폰서만, 최대 5개
final sponsorBannerProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  return _firestore
      .collection('sponsors') // ← 컬렉션 이름 통일 (banners_sponsors → sponsors)
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(5)
      .snapshots();
});