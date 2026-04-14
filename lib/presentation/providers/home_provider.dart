// lib/presentation/providers/home_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

/// TOP3 랭킹
final top3Provider = StreamProvider.autoDispose((ref) {
  return _firestore
      .collection('leaderboards_integrated')
      .orderBy('totalPoints', descending: true)
      .limit(3)
      .snapshots();
});

/// 다음 경기 (이벤트)
final nextEventProvider = StreamProvider.autoDispose((ref) {
  return _firestore
      .collection('events')                   // ✅ 컬렉션 이름 그대로 사용
      .where('status', isEqualTo: 'scheduled')
      .orderBy('date')                        // 기존 필드 유지
      .limit(1)
      .snapshots();
});

/// 공지 배너
/// 👉 컬렉션 이름은 "기존에 쓰던 이름" 유지 (예: banners_notices)
final noticeBannerProvider = StreamProvider.autoDispose((ref) {
  return _firestore
      .collection('banners_notices')          // 🔥 여기서 컬렉션 이름만 기존 그대로 사용
      .orderBy('createdAt', descending: true) // 정렬만 추가
      .snapshots();
});

/// 뉴스
final newsProvider = StreamProvider.autoDispose((ref) {
  return _firestore
      .collection('news')                     // 컬렉션 이름 그대로
      .orderBy('createdAt', descending: true) // createdAt 필드 기준 최신순
      .limit(5)
      .snapshots();
});

/// 스폰서 배너
final sponsorBannerProvider = StreamProvider.autoDispose((ref) {
  return _firestore
      .collection('sponsors')                 // 기존 sponsors 컬렉션 유지
      .where('isActive', isEqualTo: true)     // isActive = true 인 것만
      .orderBy('createdAt', descending: true)
      .snapshots();
});
