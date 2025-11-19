// lib/presentation/screens/arena/tournament_create_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart'; // 수정: AArenaRepository -> ArenaRepository
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/presentation/screens/community/arena/widgets/organizer_email_input_field.dart';
import 'dart:io';

class TournamentCreateScreen extends StatefulWidget {
  const TournamentCreateScreen({super.key});

  @override
  State<TournamentCreateScreen> createState() => _TournamentCreateScreenState();
}

class _TournamentCreateScreenState extends State<TournamentCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _feeController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _contentController = TextEditingController();

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
      appBar: AppBar(
        title: const Text('대회 개설'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 포스터
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey[200],
                      image: _posterImage != null
                          ? DecorationImage(
                        image: FileImage(File(_posterImage!.path)),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: _posterImage == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 60, color: Colors.grey[600]),
                        const SizedBox(height: 12),
                        const Text('포스터 추가', style: TextStyle(fontSize: 18)),
                        Text('탭해서 선택', style: TextStyle(color: Colors.grey[500])),
                      ],
                    )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _sectionTitle('필수 정보'),
              const SizedBox(height: 12),
              _buildTextField(_titleController, '대회명 *', hint: '예: 2025 DAO 부산 오픈'),
              const SizedBox(height: 16),
              _buildTextField(_locationController, '장소 *', hint: '예: 부산 다트존'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_feeController, '참가비 *', keyboardType: TextInputType.number, prefix: '₩ ', hint: '0'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(_maxParticipantsController, '최대 인원', keyboardType: TextInputType.number, hint: '무제한 시 비워두세요'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 대회 날짜 (한 번 누르면 자동 추천!)
              _buildDatePicker(
                label: '대회 날짜 *',
                date: _eventDate,
                onSelect: (picked) {
                  setState(() {
                    _eventDate = picked;
                    // 자동 추천
                    _entryStartDate = picked.subtract(const Duration(days: 14));
                    _entryEndDate = picked.subtract(const Duration(days: 3));
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildDatePicker(
                label: '엔트리 시작 *',
                date: _entryStartDate,
                onSelect: (d) => setState(() => _entryStartDate = d),
              ),
              const SizedBox(height: 12),
              _buildDatePicker(
                label: '엔트리 마감 *',
                date: _entryEndDate,
                onSelect: (d) => setState(() => _entryEndDate = d),
              ),

              // 자동 메일 안내
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  '엔트리 마감 후 주최자 및 공동주최자 이메일로\n참가자 명단(CSV)이 자동 발송됩니다',
                  style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // 대회 내용
              _sectionTitle('대회 내용 (규칙·상금·일정 등) *'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: '• 경기 방식\n• 상금 내역\n• 특별 규칙\n• 기타 안내 사항 등을 자유롭게 작성해주세요',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) => v!.trim().isEmpty ? '대회 내용을 입력해주세요' : null,
              ),
              const SizedBox(height: 32),

              // 공동 주최자
              _sectionTitle('공동 주최자 (선택)'),
              const SizedBox(height: 12),
              OrganizerEmailInputField(
                emails: _organizerEmails,
                onAdd: (e) => setState(() => _organizerEmails.add(e)),
                onRemove: (e) => setState(() => _organizerEmails.remove(e)),
              ),
              const SizedBox(height: 40),

              // 생성 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createTournament,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('대회 개설하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType, String? prefix, String? hint}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        prefixText: prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      validator: label.contains('*') && label != '최대 인원'
          ? (v) => v!.trim().isEmpty ? '$label을 입력해주세요' : null
          : null,
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required Function(DateTime) onSelect,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onSelect(picked);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(date == null ? '선택해주세요' : _formatDate(date),
                style: TextStyle(color: date == null ? Colors.grey : null)),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() => _posterImage = image);
  }

  String _formatDate(DateTime date) => '${date.year}년 ${date.month}월 ${date.day}일';

  Future<void> _createTournament() async {
    if (!_formKey.currentState!.validate() ||
        _eventDate == null ||
        _entryStartDate == null ||
        _entryEndDate == null ||
        _locationController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('필수 항목을 모두 입력해주세요')));
      return;
    }

    if (_entryEndDate!.isBefore(_entryStartDate!) || _eventDate!.isBefore(_entryEndDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('날짜 순서가 올바르지 않습니다')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_posterImage != null) {
        imageUrl = await _storage.uploadFile(_posterImage!.path, 'tournaments/posters');
      }

      final tournament = TournamentModel(
        title: _titleController.text.trim(),
        description: '${_locationController.text.trim()}\n\n${_contentController.text.trim()}',
        imageUrl: imageUrl,
        entryFee: int.tryParse(_feeController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        eventDate: Timestamp.fromDate(_eventDate!),
        entryStartDate: Timestamp.fromDate(_entryStartDate!),
        entryEndDate: Timestamp.fromDate(_entryEndDate!),
        createdByUid: _auth.currentUser!.uid,
        organizerEmails: [_auth.currentUser!.email!, ..._organizerEmails],
        createdAt: Timestamp.now(),
      );

      await _repository.createTournament(tournament);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('대회가 성공적으로 개설되었습니다!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _feeController.dispose();
    _maxParticipantsController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}