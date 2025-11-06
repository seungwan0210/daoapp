// lib/presentation/screens/admin/event_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class EventEditScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  const EventEditScreen({
    super.key,
    required this.docId,
    required this.initialData,
  });

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  late String _time;
  late String _shopName;
  late int _entryFee;
  late String _admin;
  late String _contact;
  String? _winner;
  String? _existingImageUrl;

  File? _pickedImage;
  bool _isUploading = false;

  late final TextEditingController _winnerController;

  @override
  void initState() {
    super.initState();
    _winnerController = TextEditingController();

    final data = widget.initialData;
    final timestamp = data['date'] as Timestamp?;
    _date = timestamp?.toDate() ?? DateTime.now();
    _time = data['time'] ?? '';
    _shopName = data['shopName'] ?? '';
    _entryFee = data['entryFee'] ?? 0;
    _admin = data['admin'] ?? '';
    _contact = data['contact'] ?? '';
    _winner = data['winner'];
    _existingImageUrl = data['resultImageUrl'];

    _winnerController.text = _winner ?? '';
  }

  @override
  void dispose() {
    _winnerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<String?> _uploadImage(File image) async {
    setState(() => _isUploading = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('event_results')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      final snapshot = await ref.putFile(image);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 업로드 실패: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  bool get _isPastEvent {
    final parts = _time.split(':');
    if (parts.length < 2) return false;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final eventDateTime = DateTime(_date.year, _date.month, _date.day, hour, minute);
    return eventDateTime.isBefore(DateTime.now());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    _winner = _winnerController.text.trim().isEmpty ? null : _winnerController.text.trim();

    String? resultImageUrl = _existingImageUrl;
    if (_pickedImage != null) {
      resultImageUrl = await _uploadImage(_pickedImage!);
      if (resultImageUrl == null) return;
    }

    final data = {
      'winner': _winner,
      'resultImageUrl': resultImageUrl,
    };

    try {
      await FirebaseFirestore.instance.collection('events').doc(widget.docId).update(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수정 완료!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: '경기 결과 관리',
        showBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 기존 정보 (읽기 전용)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('경기 정보', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('날짜: ${AppDateUtils.formatKoreanDate(_date)}'),
                  Text('시간: $_time'),
                  Text('장소: $_shopName'),
                  Text('참가비: $_entryFee원'),
                  Text('관리자: $_admin'),
                  Text('연락처: $_contact'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 우승자 입력
            if (_isPastEvent)
              AppCard(
                child: TextFormField(
                  controller: _winnerController,
                  decoration: InputDecoration(
                    labelText: '우승자 이름',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.emoji_events),
                  ),
                ),
              ),
            if (_isPastEvent) const SizedBox(height: 16),

            // 사진 업로드
            if (_isPastEvent)
              AppCard(
                child: Column(
                  children: [
                    if (_pickedImage != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_pickedImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                              onPressed: () => setState(() => _pickedImage = null),
                            ),
                          ),
                        ],
                      )
                    else if (_existingImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(_existingImageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 12),
                    _isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo),
                      label: Text(_pickedImage != null ? '사진 변경' : '결과 사진 추가'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            if (_isPastEvent) const SizedBox(height: 24),

            // 저장 버튼
            if (_isPastEvent)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('저장하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            if (!_isPastEvent)
              const Center(child: Text('종료된 경기에서만 수정 가능합니다.', style: TextStyle(color: Colors.grey))),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}