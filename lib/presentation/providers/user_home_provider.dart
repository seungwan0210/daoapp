// lib/presentation/providers/user_home_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

// TOP3 랭킹
final top3Provider = StreamProvider.autoDispose((ref) {
  return firestore
      .collection('leaderboards_integrated')
      .orderBy('totalPoints', descending: true)
      .limit(3)
      .snapshots();
});

// 다음 경기
final nextEventProvider = StreamProvider.autoDispose((ref) {
  return firestore
      .collection('events')
      .where('status', isEqualTo: 'scheduled')
      .orderBy('date')
      .limit(1)
      .snapshots();
});

// 공지 배너 - 컬렉션 이름 수정 + 정렬 추가
final noticeBannerProvider = StreamProvider.autoDispose((ref) {
  return firestore
      .collection('notices')                    // banners_notices → notices
      .orderBy('createdAt', descending: true)   // 최신순
      .snapshots();
});

// 뉴스
final newsProvider = StreamProvider.autoDispose((ref) {
  return firestore
      .collection('news')
      .orderBy('createdAt', descending: true)   // date → createdAt (정확한 필드)
      .limit(5)
      .snapshots();
});

// 스폰서 배너
final sponsorBannerProvider = StreamProvider.autoDispose((ref) {
  return firestore
      .collection('sponsors')
      .where('isActive', isEqualTo: true)   // ← isActive (대문자 A)
      .orderBy('createdAt', descending: true)
      .snapshots();
});