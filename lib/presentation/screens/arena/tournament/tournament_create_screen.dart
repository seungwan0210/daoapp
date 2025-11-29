// lib/presentation/screens/community/arena/tournament_create_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/services/storage_service.dart';

class TournamentCreateScreen extends ConsumerStatefulWidget {
  const TournamentCreateScreen({super.key});

  @override
  ConsumerState<TournamentCreateScreen> createState() =>
      _TournamentCreateScreenState();
}

class _TournamentCreateScreenState
    extends ConsumerState<TournamentCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _hostNameCtrl = TextEditingController();
  final _hostPhoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  List<String> _coOrganizers = [];

  DateTime? _eventDate;
  DateTime? _entryStartDate;
  DateTime? _entryEndDate;

  File? _posterFile;
  bool _isUploading = false;

  bool get _canSubmit =>
      _titleCtrl.text.trim().isNotEmpty &&
          _locationCtrl.text.trim().isNotEmpty &&
          _hostNameCtrl.text.trim().isNotEmpty &&
          _hostPhoneCtrl.text.trim().isNotEmpty &&
          _feeCtrl.text.trim().isNotEmpty &&
          _maxCtrl.text.trim().isNotEmpty &&
          _eventDate != null &&
          _entryStartDate != null &&
          _entryEndDate != null;

  @override
  void initState() {
    super.initState();
    // ✅ 입력값 바뀔 때마다 버튼 활성화 상태 갱신
    void attachListener(TextEditingController c) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }

    attachListener(_titleCtrl);
    attachListener(_locationCtrl);
    attachListener(_hostNameCtrl);
    attachListener(_hostPhoneCtrl);
    attachListener(_feeCtrl);
    attachListener(_maxCtrl);
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

  Future<void> _pickPoster() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _posterFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_eventDate == null || _entryStartDate == null || _entryEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('대회 날짜와 엔트리 시작/마감 날짜를 모두 선택해주세요'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 날짜 관계 유효성 검사
    if (!(_entryStartDate!.isBefore(_entryEndDate!) &&
        _entryEndDate!.isBefore(_eventDate!))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('날짜 설정을 다시 확인해주세요.\n'
              '엔트리 시작 < 엔트리 마감 < 대회 날짜 순서여야 합니다.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? posterUrl;
      if (_posterFile != null) {
        posterUrl = await sl<StorageService>().uploadFile(
          _posterFile!.path,
          'tournaments/posters',
        );
      }

      final user = sl<FirebaseAuth>().currentUser!;
      final repo = sl<ArenaRepository>();

      final maxText = _maxCtrl.text.replaceAll(',', '').trim();
      final int maxParticipants =
      (maxText.toLowerCase() == '무제한' || maxText == '0')
          ? 9999
          : int.tryParse(maxText) ?? 64;

      final int entryFee =
      int.parse(_feeCtrl.text.replaceAll(',', '').trim());

      // organizerEmails: 유효한 이메일만 저장
      final List<String> organizerEmails = [];
      if (user.email != null && user.email!.isNotEmpty) {
        organizerEmails.add(user.email!);
      }
      organizerEmails.addAll(_coOrganizers);

      final tournament = TournamentModel(
        title: _titleCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        maxParticipants: maxParticipants,
        posterUrl: posterUrl,
        entryFee: entryFee,
        eventDate: Timestamp.fromDate(_eventDate!),
        entryStartDate: Timestamp.fromDate(_entryStartDate!),
        entryEndDate: Timestamp.fromDate(_entryEndDate!),
        createdByUid: user.uid,
        organizerEmails: organizerEmails,
        hostName: _hostNameCtrl.text.trim(),
        hostPhone: _hostPhoneCtrl.text.trim(),
        createdAt: Timestamp.now(),
        entrySummarySent: false, // 메일 발송 플래그 초기값
        entryCount: 0, // 명시적으로 초기화
        isCanceled: false,
      );

      await repo.createTournament(tournament);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('대회 개설 완료!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '대회 개설',
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
              onPressed: _canSubmit && !_isUploading ? _submit : null,
              child: _isUploading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(
                '개설',
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
                  child: _posterFile != null
                      ? _buildPosterPreview(theme)
                      : _buildPosterPlaceholder(theme),
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
                    hintStyle:
                    TextStyle(fontSize: 16, color: Colors.grey[400]),
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

                // 담당자 이름
                TextFormField(
                  controller: _hostNameCtrl,
                  decoration: const InputDecoration(
                    labelText: '담당자 이름',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? '담당자 이름을 입력해주세요'
                      : null,
                ),
                const SizedBox(height: 12),

                // 담당자 연락처
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
                  validator: (v) => v == null || v.trim().isEmpty
                      ? '담당자 연락처를 입력해주세요'
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  '※ 참가자 문의는 이 연락처로 안내됩니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return '필수 입력';
                          }
                          final fee =
                          int.tryParse(v.replaceAll(',', '').trim());
                          if (fee == null || fee < 1000) {
                            return '1,000원 이상';
                          }
                          if (fee % 1000 != 0) {
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
                          hintText: '00',
                          prefixIcon: Icon(Icons.groups_outlined),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
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

                // 추천 설정 안내
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: theme.colorScheme.primary,
                        size: 26,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: theme.colorScheme.onBackground,
                            ),
                            children: [
                              const TextSpan(
                                text: '추천 설정\n',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.5,
                                ),
                              ),
                              const TextSpan(text: '• 엔트리 시작: '),
                              TextSpan(
                                text: '대회 10일 전\n',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const TextSpan(
                                text: '   → 참가자 모집 기간을 넉넉히 확보할 수 있어요\n',
                              ),
                              const TextSpan(text: '• 엔트리 마감: '),
                              TextSpan(
                                text: '대회 3일 전\n',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const TextSpan(
                                text:
                                '   → 명단 정리·이메일 발송·대진표 제작에 충분한 여유를 줍니다',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 이메일 발송 안내
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.green[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mark_email_read_outlined,
                        color: Colors.blue[700],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '엔트리 마감 시 주최자 및 공동주최자에게\n'
                              '최종 참가자 명단이 자동으로 이메일 발송됩니다.',
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 날짜 선택
                _buildDateTile('대회 날짜', _eventDate, (d) {
                  setState(() {
                    _eventDate = d;
                    // 기본 추천값: 10일 전 / 3일 전
                    _entryStartDate = d.subtract(const Duration(days: 10));
                    _entryEndDate = d.subtract(const Duration(days: 3));
                  });
                }),
                const SizedBox(height: 12),
                _buildDateTile(
                  '엔트리 시작 (자동)',
                  _entryStartDate,
                      (d) => setState(() => _entryStartDate = d),
                ),
                const SizedBox(height: 12),
                _buildDateTile(
                  '엔트리 마감 (자동)',
                  _entryEndDate,
                      (d) => setState(() => _entryEndDate = d),
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
                const SizedBox(height: 36),

                // 공동주최자
                _CoOrganizerInput(onChanged: (list) => _coOrganizers = list),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 포스터 플레이스홀더
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
            "포스터 추가하기",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "터치해서 사진을 선택하세요",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  // 포스터 프리뷰
  Widget _buildPosterPreview(ThemeData theme) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            _posterFile!,
            width: double.infinity,
            height: 340,
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
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: GestureDetector(
            onTap: _pickPoster,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_library,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "변경",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      fontSize: 15,
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

  // 날짜 타일
  Widget _buildDateTile(
      String label,
      DateTime? date,
      Function(DateTime) onSelect,
      ) {
    final isAuto = label.contains('자동');
    final isEvent = label.contains('대회');

    return Card(
      elevation: isAuto ? 0.8 : 3,
      color: isAuto ? Colors.green[30] : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isEvent ? Colors.orange : Colors.green).withOpacity(0.1),
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
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isAuto ? Colors.green[800] : null,
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
        trailing: Icon(
          Icons.calendar_today,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) {
            final time = await showTimePicker(
              context: context,
              initialTime:
              TimeOfDay.fromDateTime(date ?? DateTime.now()),
            );
            if (time != null) {
              onSelect(
                picked.copyWith(
                  hour: time.hour,
                  minute: time.minute,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

// 콤마 포매터
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) return newValue;
    final text = newValue.text.replaceAll(',', '');
    if (text.isEmpty) return newValue.copyWith(text: '');
    final number = int.tryParse(text) ?? 0;
    final formatted = NumberFormat('#,###').format(number);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// 공동주최자 입력
class _CoOrganizerInput extends StatefulWidget {
  final Function(List<String>) onChanged;
  const _CoOrganizerInput({required this.onChanged});

  @override
  State<_CoOrganizerInput> createState() => _CoOrganizerInputState();
}

class _CoOrganizerInputState extends State<_CoOrganizerInput> {
  final _ctrl = TextEditingController();
  final List<String> _emails = [];

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
                  '공동주최자 이메일 추가 (선택)',
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
