import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'dart:io';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  File? _image;
  bool _isLoading = false;
  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CommonAppBar(
        title: s.report_screen_title, // 🔹 다국어 적용
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: s.report_form_title_label, // 🔹 다국어 적용
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      labelText: s.report_form_content_label, // 🔹 다국어 적용
                      hintText: s.report_form_content_hint, // 🔹 다국어 적용
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    enableSuggestions: false,
                    autocorrect: false,
                  ),
                ),
                const SizedBox(height: 16),

                if (_image != null)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 8),

                OutlinedButton.icon(
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(_image == null ? s.report_form_photo_add : s.report_form_photo_change), // 🔹 다국어 적용
                  onPressed: _pickImage,
                ),
                const SizedBox(height: 16),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: () => _submitReport(user, s), // 🔹 s 전달
                  child: Text(s.report_form_submit), // 🔹 다국어 적용
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _submitReport(User? user, AppLocalizations s) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.common_login_required)), // 🔹 공통 키 활용
      );
      return;
    }

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.report_form_error_empty)), // 🔹 다국어 적용
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      if (_image != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('reports')
            .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_image!);
        imageUrl = await ref.getDownloadURL();
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>?;

      final reporterName = (userData?['koreanName'] ??
          userData?['nickname'] ??
          user.displayName ??
          user.email ??
          s.common_anonymous) // 🔹 공통 키 활용
          .toString();

      await FirebaseFirestore.instance.collection('reports').add({
        'userId': user.uid,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'isResolved': false,
        'reporterId': user.uid,
        'reporterName': reporterName,
        'reporterEmail': user.email,
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'currentScreen': 'Unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'processed': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.report_form_success)), // 🔹 다국어 적용
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.report_form_fail(e.toString()))), // 🔹 다국어 적용
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}