// lib/presentation/screens/admin/forms/sponsor_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class SponsorFormScreen extends StatefulWidget {
  const SponsorFormScreen({super.key});
  @override State<SponsorFormScreen> createState() => _SponsorFormScreenState();
}

class _SponsorFormScreenState extends State<SponsorFormScreen> {
  File? _image;
  bool _isActive = true;
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (_image == null) return;

    final ref = FirebaseStorage.instance
        .ref()
        .child('sponsors')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    await ref.putFile(_image!);
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('banners_sponsors').add({
      'imageUrl': url,
      'active': _isActive,
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('스폰서 배너 등록')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _image == null
                ? const Text('이미지를 선택하세요')
                : Image.file(_image!, height: 200),
            ElevatedButton(onPressed: _pickImage, child: const Text('이미지 선택')),
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