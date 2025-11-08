// lib/presentation/screens/community/arena/arena_review_detail_screen.dart
import 'package:flutter/material.dart';

class ArenaReviewDetailScreen extends StatelessWidget {
  final String reviewId;
  const ArenaReviewDetailScreen({super.key, required this.reviewId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("아레나 리뷰 상세")),
      body: Center(child: Text("리뷰 ID: $reviewId")),
    );
  }
}