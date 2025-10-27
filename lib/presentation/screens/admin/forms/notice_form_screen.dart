// lib/presentation/screens/admin/forms/notice_form_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeFormScreen extends StatefulWidget {
  const NoticeFormScreen({super.key});
  @override State<NoticeFormScreen> createState() => _NoticeFormScreenState();
}

class _NoticeFormScreenState extends State<NoticeFormScreen> {
  final _textController = TextEditingController();
  bool _isActive = true;

  Future<void> _save() async {
    if (_textController.text.isEmpty) return;
    await FirebaseFirestore.instance.collection('banners_notices').add({
      'text': _textController.text,
      'active': _isActive,
      'createdAt': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('공지 등록')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(labelText: '공지 내용'),
            ),
            SwitchListTile(
              title: const Text('활성화'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            ElevatedButton(onPressed: _save, child: const Text('저장')),
          ],
        ),
      ),
    );
  }
}