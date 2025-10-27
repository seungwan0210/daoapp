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

// 공지 배너
final noticeBannerProvider = StreamProvider.autoDispose((ref) {
  return firestore
      .collection('banners_notices')
      .where('active', isEqualTo: true)
      .snapshots(); // orderBy 제거!
});

// 뉴스
final newsProvider = StreamProvider.autoDispose((ref) {
  return firestore
      .collection('news')
      .orderBy('date', descending: true)
      .limit(5)
      .snapshots();
});

// 스폰서 배너
final sponsorBannerProvider = StreamProvider.autoDispose((ref) {
  return firestore
      .collection('banners_sponsors')
      .where('active', isEqualTo: true)
      .snapshots();
});