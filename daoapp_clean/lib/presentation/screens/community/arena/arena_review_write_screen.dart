// lib/presentation/screens/community/arena/arena_review_write_screen.dart
import 'package:flutter/material.dart';

class ArenaReviewWriteScreen extends StatelessWidget {
  const ArenaReviewWriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("아레나 리뷰 작성")),
      body: const Center(child: Text("리뷰 작성")),
    );
  }
}