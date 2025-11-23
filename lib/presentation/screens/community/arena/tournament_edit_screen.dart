// lib/presentation/screens/community/arena/tournament_edit_screen.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/services/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class TournamentEditScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentEditScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  State<TournamentEditScreen> createState() => _TournamentEditScreenState();
}

class _TournamentEditScreenState extends State<TournamentEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _hostNameCtrl = TextEditingController();   // 🔹 담당자 이름
  final _hostPhoneCtrl = TextEditingController();  // 🔹 담당자 연락처
  final _descCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  DateTime? _eventDate;
  DateTime? _entryStartDate;
  DateTime? _entryEndDate;

  File? _posterFile; // 새로 선택한 포스터
  String? _posterUrl; // 기존 포스터 URL

  List<String> _coOrganizers = [];

  bool _isLoading = true;
  bool _isSaving = false;

  TournamentModel? _original;

  bool get _canSubmit =>
      _titleCtrl.text.trim().isNotEmpty &&
          _locationCtrl.text.trim().isNotEmpty &&
          _hostNameCtrl.text.trim().isNotEmpty &&
          _hostPhoneCtrl.text.trim().isNotEmpty &&
          _eventDate != null &&
          _feeCtrl.text.trim().isNotEmpty &&
          _maxCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadTournament();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _hostNameCtrl.dispose();
    _hostPhoneCtrl.dispose();
    _descCtrl.dispose();
    _feeCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTournament() async {
    try {
      final repo = sl<ArenaRepository>();
      final data = await repo.getTournament(widget.tournamentId);

      if (data == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('대회 정보를 찾을 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
        return;
      }

      _original = data;

      final user = sl<FirebaseAuth>().currentUser;
      final hostEmail = user?.email ?? '';

      // 컨트롤러/상태 초기값 세팅
      _titleCtrl.text = data.title;
      _locationCtrl.text = data.location;
      _hostNameCtrl.text = data.hostName;     // 🔹 담당자 이름 초기값
      _hostPhoneCtrl.text = data.hostPhone;   // 🔹 담당자 연락처 초기값
      _descCtrl.text = data.description;
      _feeCtrl.text = NumberFormat('#,###').format(data.entryFee);

      if (data.maxParticipants >= 9999) {
        _maxCtrl.text = '무제한';
      } else {
        _maxCtrl.text = NumberFormat('#,###').format(data.maxParticipants);
      }

      _eventDate = data.eventDate.toDate();
      _entryStartDate = data.entryStartDate.toDate();
      _entryEndDate = data.entryEndDate.toDate();

      _posterUrl = data.posterUrl;

      // 공동주최자 (본인 이메일은 제외)
      _coOrganizers = data.organizerEmails
          .where(
            (e) =>
        e.isNotEmpty &&
            (hostEmail.isEmpty ||
                e.toLowerCase() != hostEmail.toLowerCase()),
      )
          .toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('대회 정보를 불러오는 중 오류: $e'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickPoster() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _posterFile = File(picked.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventDate == null ||
        _entryStartDate == null ||
        _entryEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('날짜를 모두 선택해주세요'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = sl<FirebaseAuth>().currentUser!;
      String hostEmail = user.email ?? '';

      String? posterUrl = _posterUrl;

      // 새 포스터 업로드
      if (_posterFile != null) {
        posterUrl = await sl<StorageService>().uploadFile(
          _posterFile!.path,
          'tournaments/posters',
        );
      }

      final maxText = _maxCtrl.text.replaceAll(',', '').trim();
      final int maxParticipants =
      (maxText.toLowerCase() == '무제한' || maxText == '0')
          ? 9999
          : int.tryParse(maxText) ?? (_original?.maxParticipants ?? 64);

      final int entryFee = int.parse(_feeCtrl.text.replaceAll(',', ''));

      // 업데이트할 필드만 구성
      final Map<String, dynamic> updateData = {
        'title': _titleCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'hostName': _hostNameCtrl.text.trim(),     // 🔹 담당자 이름
        'hostPhone': _hostPhoneCtrl.text.trim(),   // 🔹 담당자 연락처
        'description': _descCtrl.text.trim(),
        'entryFee': entryFee,
        'maxParticipants': maxParticipants,
        'eventDate': Timestamp.fromDate(_eventDate!),
        'entryStartDate': Timestamp.fromDate(_entryStartDate!),
        'entryEndDate': Timestamp.fromDate(_entryEndDate!),
        'organizerEmails': [
          if (hostEmail.isNotEmpty) hostEmail,
          ..._coOrganizers,
        ],
        'updatedAt': Timestamp.now(),
      };

      if (posterUrl != null && posterUrl.isNotEmpty) {
        updateData['posterUrl'] = posterUrl;
      }

      await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.tournamentId)
          .update(updateData);

      if (!mounted) return;

      Navigator.pop(context); // 수정 화면 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('대회 정보가 수정되었습니다'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('수정 중 오류 발생: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '대회 수정',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onBackground,
        surfaceTintColor: Colors.transparent,
        actions: [
          AnimatedOpacity(
            opacity: _canSubmit ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: TextButton(
              onPressed: _canSubmit && !_isSaving ? _submit : null,
              child: _isSaving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(
                '저장',
                style: TextStyle(
                  color: _canSubmit
                      ? theme.colorScheme.primary
                      : Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 포스터
                GestureDetector(
                  onTap: _pickPoster,
                  child: _buildPosterArea(theme),
                ),
                const SizedBox(height: 36),

                // 대회명
                TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '대회명을 입력하세요',
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 장소
                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: '장소',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (v) =>
                  v?.trim().isEmpty ?? true ? '장소를 입력해주세요' : null,
                ),
                const SizedBox(height: 16),

                // 🔹 담당자 이름
                TextFormField(
                  controller: _hostNameCtrl,
                  decoration: const InputDecoration(
                    labelText: '담당자 이름',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? '담당자 이름을 입력해주세요' : null,
                ),
                const SizedBox(height: 16),

                // 🔹 담당자 연락처
                TextFormField(
                  controller: _hostPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '담당자 연락처',
                    hintText: '예: 010-1234-5678',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? '담당자 연락처를 입력해주세요' : null,
                ),
                const SizedBox(height: 20),

                // 참가비 + 최대 인원
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _feeCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [ThousandsFormatter()],
                        decoration: const InputDecoration(
                          labelText: '참가비',
                          prefixIcon: Icon(Icons.paid_outlined),
                          suffixText: ' 원',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return '필수 입력';
                          }
                          final fee = int.tryParse(
                              v.replaceAll(',', '').trim());
                          if (fee == null || fee < 0) {
                            return '0원 이상 숫자로 입력';
                          }
                          if (fee > 0 && fee % 1000 != 0) {
                            return '1,000원 단위로 입력';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '최대 인원',
                          hintText: '00 또는 무제한',
                          prefixIcon: Icon(Icons.groups_outlined),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return '필수 입력';
                          }
                          final cleaned =
                          v.replaceAll(',', '').trim().toLowerCase();
                          if (cleaned == '무제한') return null;
                          final n = int.tryParse(cleaned);
                          if (n == null || n < 2) {
                            return '2명 이상 또는 "무제한"';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 안내 텍스트 (수정 화면이라 살짝 톤만)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    '대회 날짜와 엔트리 시작/마감일은 자유롭게 수정할 수 있습니다.\n'
                        '참가자에게 이미 공지가 나간 경우, 변경 사항을 다시 공지해 주세요.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 날짜 선택
                _buildDateTile(
                  label: '대회 날짜',
                  date: _eventDate,
                  context: context,
                  onSelect: (d) => setState(() => _eventDate = d),
                ),
                const SizedBox(height: 12),
                _buildDateTile(
                  label: '엔트리 시작',
                  date: _entryStartDate,
                  context: context,
                  onSelect: (d) => setState(() => _entryStartDate = d),
                ),
                const SizedBox(height: 12),
                _buildDateTile(
                  label: '엔트리 마감',
                  date: _entryEndDate,
                  context: context,
                  onSelect: (d) => setState(() => _entryEndDate = d),
                ),
                const SizedBox(height: 16),

                // 상세 내용
                TextField(
                  controller: _descCtrl,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: '대회 규칙, 상금, 기타 안내사항 등을 자세히 작성해주세요',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 28),

                // 공동주최자
                _CoOrganizerInput(
                  initialEmails: _coOrganizers,
                  onChanged: (list) => _coOrganizers = list,
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 포스터 영역 (기존 + 새 선택 반영)
  Widget _buildPosterArea(ThemeData theme) {
    // 새 파일이 있으면 그게 우선
    if (_posterFile != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              _posterFile!,
              width: double.infinity,
              height: 260,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => setState(() => _posterFile = null),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child:
                const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: _pickPoster,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      '변경',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 기존 포스터가 있는 경우
    if (_posterUrl != null && _posterUrl!.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              _posterUrl!,
              width: double.infinity,
              height: 260,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPosterPlaceholder(theme),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: _pickPoster,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      '다시 선택',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 아무 것도 없을 때 플레이스홀더
    return _buildPosterPlaceholder(theme);
  }

  Widget _buildPosterPlaceholder(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_a_photo_outlined,
              size: 42,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '포스터 추가/변경하기',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '터치해서 사진을 선택하세요',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime? date,
    required BuildContext context,
    required Function(DateTime) onSelect,
  }) {
    final isEvent = label.contains('대회');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isEvent ? Colors.orange : Colors.green)
                .withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isEvent ? Icons.emoji_events : Icons.access_time,
            color: isEvent ? Colors.orange[700] : Colors.green[700],
            size: 26,
          ),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            date != null
                ? DateFormat('yyyy년 M월 d일 (EEE)  HH:mm').format(date)
                : '탭하여 날짜 선택',
            style: TextStyle(
              fontSize: 15,
              color: date != null ? Colors.black87 : Colors.grey[500],
            ),
          ),
        ),
        trailing: Icon(Icons.calendar_today,
            color: Theme.of(context).colorScheme.primary),
        onTap: () async {
          final now = DateTime.now();
          final initial = date ?? now;
          final picked = await showDatePicker(
            context: context,
            initialDate: initial.isBefore(now) ? now : initial,
            firstDate: DateTime(now.year - 1),
            lastDate: DateTime(now.year + 2),
          );
          if (picked != null) {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(initial),
            );
            if (time != null) {
              onSelect(picked.copyWith(
                hour: time.hour,
                minute: time.minute,
              ));
            }
          }
        },
      ),
    );
  }
}

/// 콤마 포매터 (create 화면과 동일 기능)
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final text = newValue.text.replaceAll(',', '');
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final number = int.tryParse(text) ?? 0;
    final formatted = NumberFormat('#,###').format(number);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// 공동주최자 이메일 입력 위젯 (create 화면과 거의 동일)
class _CoOrganizerInput extends StatefulWidget {
  final List<String> initialEmails;
  final Function(List<String>) onChanged;

  const _CoOrganizerInput({
    required this.initialEmails,
    required this.onChanged,
  });

  @override
  State<_CoOrganizerInput> createState() => _CoOrganizerInputState();
}

class _CoOrganizerInputState extends State<_CoOrganizerInput> {
  final _ctrl = TextEditingController();
  late List<String> _emails;

  @override
  void initState() {
    super.initState();
    _emails = List<String>.from(widget.initialEmails);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_alt, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  '공동주최자 이메일 수정 (선택)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'example@gmail.com',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: _addEmail,
                ),
              ),
              onSubmitted: (_) => _addEmail(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emails
                  .map(
                    (email) => Chip(
                  label: Text(
                    email,
                    style: const TextStyle(fontSize: 14),
                  ),
                  backgroundColor:
                  theme.colorScheme.primary.withOpacity(0.1),
                  deleteIconColor: theme.colorScheme.primary,
                  onDeleted: () {
                    setState(() {
                      _emails.remove(email);
                      widget.onChanged(_emails);
                    });
                  },
                ),
              )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _addEmail() {
    final email = _ctrl.text.trim();
    if (email.isNotEmpty &&
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email) &&
        !_emails.contains(email)) {
      setState(() {
        _emails.add(email);
        widget.onChanged(_emails);
      });
      _ctrl.clear();
    } else if (email.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('올바른 이메일 주소를 입력해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
