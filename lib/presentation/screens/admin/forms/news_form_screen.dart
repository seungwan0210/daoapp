// lib/presentation/screens/admin/forms/news_form_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsFormScreen extends StatefulWidget {
  const NewsFormScreen({super.key});
  @override State<NewsFormScreen> createState() => _NewsFormScreenState();
}

class _NewsFormScreenState extends State<NewsFormScreen> {
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();

  Future<void> _save() async {
    if (_titleController.text.isEmpty || _dateController.text.isEmpty) return;
    await FirebaseFirestore.instance.collection('news').add({
      'title': _titleController.text,
      'date': _dateController.text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('뉴스 등록')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: '날짜 (예: 2025-10-28)'),
            ),
            ElevatedButton(onPressed: _save, child: const Text('저장')),
          ],
        ),
      ),
    );
  }
}