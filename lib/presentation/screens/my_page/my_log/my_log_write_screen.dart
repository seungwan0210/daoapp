import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/data/models/my_log_model.dart';
import 'package:daoapp/services/storage_service.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/providers/my_log_provider.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class MyLogWriteScreen extends ConsumerStatefulWidget {
  final MyLogModel? existingLog;
  final DateTime? initialDate;

  const MyLogWriteScreen({
    super.key,
    this.existingLog,
    this.initialDate,
  });

  @override
  ConsumerState<MyLogWriteScreen> createState() => _MyLogWriteScreenState();
}

class _MyLogWriteScreenState extends ConsumerState<MyLogWriteScreen> {
  final _contentController = TextEditingController();
  final _picker = ImagePicker();

  File? _pickedImage;
  String? _existingPhotoUrl;

  bool _shareToCircle = false;
  bool _isUploading = false;

  bool get _isEditMode => widget.existingLog != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingLog != null) {
      final log = widget.existingLog!;
      _contentController.text = log.content ?? '';
      _shareToCircle = log.isSharedToCircle;
      if (log.photoUrls.isNotEmpty) {
        _existingPhotoUrl = log.photoUrls.first;
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  DateTime get _selectedDateForSave {
    if (_isEditMode) return widget.existingLog!.date;
    return widget.initialDate ?? DateTime.now();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  void _toggleTemplate(String template) {
    String current = _contentController.text;

    if (current.contains(template)) {
      setState(() {
        _contentController.text = current.replaceAll(template, "").replaceAll("\n\n\n", "\n\n").trim();
      });
    } else {
      final separator = current.trim().isEmpty ? '' : '\n\n';
      setState(() {
        _contentController.text = '$current$separator$template';
      });
    }

    _contentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _contentController.text.length)
    );
  }

  Future<void> _save(AppLocalizations s) async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.mylog_write_empty_error)));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      String? uploadedPhotoUrl;

      if (_pickedImage != null) {
        uploadedPhotoUrl = await StorageService().uploadMyLogImage(_pickedImage!);
      }

      final List<String> photoUrls = [];
      if (uploadedPhotoUrl != null) photoUrls.add(uploadedPhotoUrl);
      else if (_existingPhotoUrl != null) photoUrls.add(_existingPhotoUrl!);

      final repo = ref.read(myLogRepositoryProvider);
      final log = MyLogModel(
        id: widget.existingLog?.id,
        userId: userId,
        date: _selectedDateForSave,
        content: content,
        photoUrls: photoUrls,
        isSharedToCircle: _shareToCircle,
        createdAt: widget.existingLog?.createdAt ?? DateTime.now(),
      );

      final logId = await repo.saveLog(log);
      if (_shareToCircle) await repo.shareToCircle(log.copyWith(id: logId));

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.mylog_write_save_fail(e.toString()))));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _sectionTitle(String text, IconData icon) => Row(
    children: [
      Icon(icon, size: 16, color: Colors.cyan[800]),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
    ],
  );

  Widget _templateChip(String label, String template, MaterialColor color) {
    final bool isSelected = _contentController.text.contains(template);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(
            color: isSelected ? Colors.white : color.shade800,
            fontSize: 12,
            fontWeight: FontWeight.bold
        )),
        selected: isSelected,
        selectedColor: color.shade700,
        backgroundColor: color.withOpacity(0.05),
        checkmarkColor: Colors.white,
        shape: StadiumBorder(side: BorderSide(color: color.withOpacity(0.2))),
        onSelected: (_) => _toggleTemplate(template),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    // 🔹 국가별 언어 설정에 따른 날짜 포맷 적용
    final dateStr = DateFormat.yMMMEd(Localizations.localeOf(context).toString()).format(_selectedDateForSave);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CommonAppBar(
        title: _isEditMode ? s.mylog_write_title_edit : s.mylog_write_title_new,
        showBackButton: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0F172A)),
                          child: const Text('🎯', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                            Text(_isEditMode ? s.mylog_write_subtitle_edit : s.mylog_write_subtitle_new,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildImagePicker(s),
                    const SizedBox(height: 32),

                    _sectionTitle(s.mylog_write_guide_title, Icons.auto_awesome_outlined),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _templateChip(s.mylog_write_guide_good, s.mylog_write_template_good, Colors.blue),
                          _templateChip(s.mylog_write_guide_bad, s.mylog_write_template_bad, Colors.orange),
                          _templateChip(s.mylog_write_guide_next, s.mylog_write_template_next, Colors.green),
                          _templateChip(s.mylog_write_guide_review, s.mylog_write_template_review, Colors.purple),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(fontSize: 15, height: 1.6),
                        decoration: InputDecoration(
                          hintText: s.mylog_write_hint,
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 24),

                    AppCard(
                      padding: EdgeInsets.zero,
                      child: SwitchListTile(
                        title: Text(s.mylog_write_share_title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text(_isEditMode ? s.mylog_write_share_subtitle_edit : s.mylog_write_share_subtitle_new, style: const TextStyle(fontSize: 11)),
                        value: _shareToCircle,
                        activeColor: Colors.cyan[700],
                        onChanged: (v) => setState(() => _shareToCircle = v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomAction(s),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(AppLocalizations s) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!, width: 2),
        ),
        child: Stack(
          children: [
            Center(
              child: _pickedImage != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(_pickedImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity))
                  : (_existingPhotoUrl != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network(_existingPhotoUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity))
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text(s.mylog_write_image_add, style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              )),
            ),
            if (_pickedImage != null || _existingPhotoUrl != null)
              Positioned(
                top: 10, right: 10,
                child: GestureDetector(
                  onTap: () => setState(() { _pickedImage = null; _existingPhotoUrl = null; }),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(AppLocalizations s) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: ElevatedButton(
        onPressed: (_contentController.text.isNotEmpty && !_isUploading) ? () => _save(s) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isUploading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent))
            : Text(s.mylog_write_save_btn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}