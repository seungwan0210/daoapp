// lib/presentation/screens/community/circle/widgets/comment_preview.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentPreview extends StatelessWidget {
  final String postId;

  const CommentPreview({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community')
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp')
          .limit(2)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style.copyWith(fontSize: 13),
                  children: [
                    TextSpan(text: data['displayName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    const WidgetSpan(child: SizedBox(width: 4)),
                    TextSpan(text: data['content']),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}