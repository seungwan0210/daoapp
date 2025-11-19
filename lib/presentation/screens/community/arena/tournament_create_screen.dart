// lib/presentation/screens/arena/tournament_create_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/services/storage_service.dart';  // ← 여기 추가!!
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class TournamentCreateScreen extends StatefulWidget {
  const TournamentCreateScreen({Key? key}) : super(key: key);

  @override
  State<TournamentCreateScreen> createState() => _TournamentCreateScreenState();
}

class _TournamentCreateScreenState extends State<TournamentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _feeController = TextEditingController();
  final _emailController = TextEditingController();

  DateTime? _eventDate;
  DateTime? _entryStartDate;
  DateTime? _entryEndDate;

  XFile? _posterImage;
  final List<String> _organizerEmails = [];
  bool _isLoading = false;

  final _repository = sl<ArenaRepository>();
  final _storage = sl<StorageService>();
  final _auth = sl<FirebaseAuth>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('대회 개설하기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 포스터 업로드
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                    image: _posterImage != null
                        ? DecorationImage(
                      image: FileImage(File(_posterImage!.path)),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: _posterImage == null
                      ? const Center(child: Text('포스터 이미지 선택 (선택)', style: TextStyle(fontSize: 16)))
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: '대회 제목 *')),
              TextFormField(controller: _descController, decoration: const InputDecoration(labelText: '대회 설명 *'), maxLines: 4),
              TextFormField(controller: _feeController, decoration: const InputDecoration(labelText: '참가비 (원)')),

              // 날짜 선택
              ListTile(
                title: Text(_eventDate == null ? '대회 날짜 선택 *' : '대회일: ${_formatDate(_eventDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(context, (date) => setState(() => _eventDate = date)),
              ),
              ListTile(
                title: Text(_entryStartDate == null ? '엔트리 시작일 *' : '엔트리 시작: ${_formatDate(_entryStartDate!)}'),
                onTap: () => _pickDate(context, (date) => setState(() => _entryStartDate = date)),
              ),
              ListTile(
                title: Text(_entryEndDate == null ? '엔트리 마감일 *' : '엔트리 마감: ${_formatDate(_entryEndDate!)}'),
                onTap: () => _pickDate(context, (date) => setState(() => _entryEndDate = date)),
              ),

              // 주최자 이메일
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: TextField(controller: _emailController, decoration: const InputDecoration(hintText: '공동 주최자 이메일'))),
                  IconButton(icon: const Icon(Icons.add), onPressed: _addEmail),
                ],
              ),
              Wrap(
                spacing: 8,
                children: _organizerEmails.map((e) => Chip(label: Text(e), onDeleted: () => setState(() => _organizerEmails.remove(e)))).toList(),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createTournament,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('대회 개설하기', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _posterImage = image);
  }

  Future<void> _pickDate(BuildContext context, Function(DateTime) onPicked) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) onPicked(date);
  }

  void _addEmail() {
    if (_emailController.text.isNotEmpty && _emailController.text.contains('@')) {
      setState(() {
        _organizerEmails.add(_emailController.text.trim());
        _emailController.clear();
      });
    }
  }

  String _formatDate(DateTime date) => '${date.year}-${date.month}-${date.day}';

  Future<void> _createTournament() async {
    if (!_formKey.currentState!.validate() || _eventDate == null || _entryStartDate == null || _entryEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('필수 항목을 입력해주세요')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_posterImage != null) {
        imageUrl = await _storage.uploadFile(_posterImage!.path, 'tournaments/posters');
      }

      final tournament = TournamentModel(
        title: _titleController.text,
        description: _descController.text,
        imageUrl: imageUrl,
        entryFee: int.tryParse(_feeController.text) ?? 0,
        eventDate: Timestamp.fromDate(_eventDate!),
        entryStartDate: Timestamp.fromDate(_entryStartDate!),
        entryEndDate: Timestamp.fromDate(_entryEndDate!),
        createdByUid: _auth.currentUser!.uid,
        organizerEmails: [_auth.currentUser!.email!, ..._organizerEmails],
        createdAt: Timestamp.now(),
      );

      await _repository.createTournament(tournament);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('대회가 성공적으로 개설되었습니다!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}