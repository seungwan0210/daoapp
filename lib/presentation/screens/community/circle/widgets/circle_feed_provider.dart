// lib/presentation/providers/circle_feed_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final circleFeedProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance
      .collection('community')
      .orderBy('timestamp', descending: true)
      .snapshots();
});