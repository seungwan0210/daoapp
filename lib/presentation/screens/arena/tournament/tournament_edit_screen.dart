import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/services/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart'; // ✅ 알람 휠 UI
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
  final _hostNameCtrl = TextEditingController();
  final _hostPhoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  // ✅ 날짜/시간 분리
  DateTime? _eventDay; // 대회 날짜(YYYY-MM-DD)
  TimeOfDay? _eventTime; // 대회 시간(HH:mm)
  DateTime? _entryStartDay; // 엔트리 시작 날짜
  DateTime? _entryEndDay; // 엔트리 마감 날짜

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
          _eventDay != null &&
          _eventTime != null &&
          _entryStartDay != null &&
          _entryEndDay != null &&
          _feeCtrl.text.trim().isNotEmpty &&
          _maxCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadTournament();

    // ✅ 입력 변화에 따라 상단 저장 버튼 상태 갱신
    void attach(TextEditingController c) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }

    attach(_titleCtrl);
    attach(_locationCtrl);
    attach(_hostNameCtrl);
    attach(_hostPhoneCtrl);
    attach(_feeCtrl);
    attach(_maxCtrl);
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

  // =========================
  // ✅ 날짜/시간 유틸
  // =========================
  DateTime _stripToDay(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _combineDayTime(DateTime day, TimeOfDay time) {
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  DateTime _entryStartDateTime() {
    final d = _entryStartDay!;
    return DateTime(d.year, d.month, d.day, 0, 0); // 00:00 고정
  }

  DateTime _entryEndDateTime() {
    final d = _entryEndDay!;
    return DateTime(d.year, d.month, d.day, 23, 59); // 23:59 고정
  }

  String _formatDay(DateTime d) =>
      DateFormat('yyyy년 M월 d일 (EEE)', 'ko_KR').format(d);

  String _formatTimeOfDay(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  // =========================
  // ✅ 알람 스타일(휠) 시간 선택기
  // =========================
  Future<TimeOfDay?> _showAlarmStyleTimePicker(
      BuildContext context, {
        required TimeOfDay initial,
        int minuteInterval = 5,
        String title = '시간 선택',
      }) async {
    int hour = initial.hour;
    int minute = (initial.minute ~/ minuteInterval) * minuteInterval;

    return showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: false,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('취소'),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(
                        ctx,
                        TimeOfDay(hour: hour, minute: minute),
                      ),
                      child: const Text('완료'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController:
                        FixedExtentScrollController(initialItem: hour),
                        itemExtent: 40,
                        onSelectedItemChanged: (v) => hour = v,
                        children: List.generate(
                          24,
                              (i) => Center(
                            child: Text(i.toString().padLeft(2, '0')),
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      ':',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: minute ~/ minuteInterval,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (idx) =>
                        minute = idx * minuteInterval,
                        children: List.generate(
                          (60 / minuteInterval).round(),
                              (i) => Center(
                            child: Text(
                              (i * minuteInterval)
                                  .toString()
                                  .padLeft(2, '0'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================
  // ✅ 이메일 정리/중복제거
  // =========================
  List<String> _dedupeEmails(List<String> raw) {
    final seen = <String>{};
    final out = <String>[];

    for (final e in raw) {
      final t = e.trim();
      if (t.isEmpty) continue;
      final key = t.toLowerCase();
      if (seen.add(key)) out.add(t);
    }
    return out;
  }

  // =========================
  // ✅ 로드
  // =========================
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
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
        return;
      }

      _original = data;

      final user = sl<FirebaseAuth>().currentUser;
      final hostEmail = (user?.email ?? '').trim();

      _titleCtrl.text = data.title;
      _locationCtrl.text = data.location;
      _hostNameCtrl.text = data.hostName;
      _hostPhoneCtrl.text = data.hostPhone;
      _descCtrl.text = data.description;
      _feeCtrl.text = NumberFormat('#,###').format(data.entryFee);

      if (data.maxParticipants >= 9999) {
        _maxCtrl.text = '무제한';
      } else {
        _maxCtrl.text = NumberFormat('#,###').format(data.maxParticipants);
      }

      // ✅ 기존 Timestamp -> 화면 값으로 정규화
      final eventDt = data.eventDate.toDate();
      final entryStartDt = data.entryStartDate.toDate();
      final entryEndDt = data.entryEndDate.toDate();

      _eventDay = _stripToDay(eventDt);
      _eventTime = TimeOfDay(hour: eventDt.hour, minute: eventDt.minute);

      _entryStartDay = _stripToDay(entryStartDt);
      _entryEndDay = _stripToDay(entryEndDt);

      _posterUrl = data.posterUrl;

      // hostEmail 제외한 공동주최자 목록
      _coOrganizers = data.organizerEmails.where((e) {
        final email = e.trim();
        if (email.isEmpty) return false;
        if (hostEmail.isEmpty) return true;
        return email.toLowerCase() != hostEmail.toLowerCase();
      }).toList();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('대회 정보를 불러오는 중 오류: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  // =========================
  // ✅ 포스터
  // =========================
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

  // =========================
  // ✅ 저장
  // =========================
  Future<void> _submit() async {
    if (_isSaving) return; // ✅ 연타 방지
    if (!_formKey.currentState!.validate()) return;

    if (_eventDay == null ||
        _eventTime == null ||
        _entryStartDay == null ||
        _entryEndDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('날짜/시간을 모두 선택해주세요'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // ✅ 로그인 방어 (CreateScreen과 동일하게)
    final user = sl<FirebaseAuth>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 후 수정이 가능합니다'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final eventDateTime = _combineDayTime(_eventDay!, _eventTime!);
    final entryStart = _entryStartDateTime();
    final entryEnd = _entryEndDateTime();

    // ✅ CreateScreen과 동일 규칙: 시작 < 마감 < 대회일시
    if (!(entryStart.isBefore(entryEnd) && entryEnd.isBefore(eventDateTime))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '날짜/시간 설정을 다시 확인해주세요.\n'
                '엔트리 시작 < 엔트리 마감 < 대회 일시 순서여야 합니다.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final hostEmail = (user.email ?? '').trim();

      String? posterUrl = _posterUrl;
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

      final int entryFee = int.parse(_feeCtrl.text.replaceAll(',', '').trim());

      // ✅ 이메일 중복 제거 + hostEmail 포함
      final organizerEmails = _dedupeEmails([
        if (hostEmail.isNotEmpty) hostEmail,
        ..._coOrganizers,
      ]);

      final Map<String, dynamic> updateData = {
        'title': _titleCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'hostName': _hostNameCtrl.text.trim(),
        'hostPhone': _hostPhoneCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'entryFee': entryFee,
        'maxParticipants': maxParticipants,
        'eventDate': Timestamp.fromDate(eventDateTime),
        'entryStartDate': Timestamp.fromDate(entryStart),
        'entryEndDate': Timestamp.fromDate(entryEnd),
        'organizerEmails': organizerEmails,
        'updatedAt': Timestamp.now(),
      };

      // ✅ 포스터는 (기존 유지 or 새 업로드)만 반영
      if (posterUrl != null && posterUrl.isNotEmpty) {
        updateData['posterUrl'] = posterUrl;
      }

      await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.tournamentId)
          .update(updateData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('대회 정보가 수정되었습니다'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
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

  // =========================
  // ✅ UI
  // =========================
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
                child: CircularProgressIndicator(strokeWidth: 2),
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
                GestureDetector(
                  onTap: _pickPoster,
                  child: _buildPosterArea(theme),
                ),
                const SizedBox(height: 36),

                // ✅ FIX 1: title도 Form validator에 포함되도록 TextFormField로 변경
                TextFormField(
                  controller: _titleCtrl,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '대회명을 입력하세요',
                    hintStyle: TextStyle(fontSize: 16, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '대회명을 입력해주세요' : null,
                ),
                const SizedBox(height: 32),

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
                const SizedBox(height: 20),

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
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return '필수 입력';
                          final fee = int.tryParse(v.replaceAll(',', '').trim());
                          if (fee == null || fee < 0) return '0원 이상 숫자로 입력';
                          if (fee > 0 && fee % 1000 != 0) return '1,000원 단위로 입력';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maxCtrl,
                        decoration: const InputDecoration(
                          labelText: '최대 인원',
                          hintText: '00 또는 무제한',
                          prefixIcon: Icon(Icons.groups_outlined),
                          border: OutlineInputBorder(),
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return '필수 입력';
                          final cleaned = v.replaceAll(',', '').trim().toLowerCase();
                          if (cleaned == '무제한') return null;
                          final n = int.tryParse(cleaned);
                          if (n == null || n < 2) return '2명 이상 또는 "무제한"';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

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
                    '✅ 대회일은 "날짜"와 "시간"을 따로 선택합니다.\n'
                        '✅ 엔트리 시작은 선택한 날짜의 00:00, 마감은 23:59로 자동 고정됩니다.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _buildDayTile(
                  label: '대회 날짜',
                  day: _eventDay,
                  context: context,
                  onSelect: (pickedDay) =>
                      setState(() => _eventDay = _stripToDay(pickedDay)),
                  leadingIcon: Icons.calendar_month,
                  leadingColor: Colors.orange,
                ),
                const SizedBox(height: 12),

                _buildTimeTile(
                  label: '대회 시간',
                  time: _eventTime,
                  context: context,
                  onSelect: (t) => setState(() => _eventTime = t),
                  leadingIcon: Icons.access_time,
                  leadingColor: Colors.orange,
                  defaultTime: const TimeOfDay(hour: 9, minute: 0),
                ),
                const SizedBox(height: 12),

                _buildDayTile(
                  label: '엔트리 시작 날짜',
                  day: _entryStartDay,
                  context: context,
                  onSelect: (pickedDay) =>
                      setState(() => _entryStartDay = _stripToDay(pickedDay)),
                  leadingIcon: Icons.play_circle_outline,
                  leadingColor: Colors.green,
                  subtitleBuilder: (d) => '${_formatDay(d)}  00:00',
                ),
                const SizedBox(height: 12),

                _buildDayTile(
                  label: '엔트리 마감 날짜',
                  day: _entryEndDay,
                  context: context,
                  onSelect: (pickedDay) =>
                      setState(() => _entryEndDay = _stripToDay(pickedDay)),
                  leadingIcon: Icons.stop_circle_outlined,
                  leadingColor: Colors.green,
                  subtitleBuilder: (d) => '${_formatDay(d)}  23:59',
                ),
                const SizedBox(height: 16),

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

  // =========================
  // ✅ 날짜 타일(날짜만)
  // =========================
  Widget _buildDayTile({
    required String label,
    required DateTime? day,
    required BuildContext context,
    required Function(DateTime pickedDay) onSelect,
    required IconData leadingIcon,
    required Color leadingColor,
    String Function(DateTime d)? subtitleBuilder,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: leadingColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(leadingIcon, color: leadingColor, size: 26),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            day != null
                ? (subtitleBuilder?.call(day) ?? _formatDay(day))
                : '탭하여 날짜 선택',
            style: TextStyle(
              fontSize: 15,
              color: day != null ? Colors.black87 : Colors.grey[500],
            ),
          ),
        ),
        trailing: Icon(
          Icons.calendar_today,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: () async {
          final now = DateTime.now();
          final initial = day ?? now;

          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(initial.year, initial.month, initial.day),
            firstDate: DateTime(now.year - 1),
            lastDate: DateTime(now.year + 3),
          );

          if (picked != null) onSelect(picked);
        },
      ),
    );
  }

  // =========================
  // ✅ 시간 타일(시간만) - 알람휠 바텀시트
  // =========================
  Widget _buildTimeTile({
    required String label,
    required TimeOfDay? time,
    required BuildContext context,
    required Function(TimeOfDay pickedTime) onSelect,
    required IconData leadingIcon,
    required Color leadingColor,
    required TimeOfDay defaultTime,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: leadingColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(leadingIcon, color: leadingColor, size: 26),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            time != null ? _formatTimeOfDay(time) : '탭하여 시간 선택',
            style: TextStyle(
              fontSize: 15,
              color: time != null ? Colors.black87 : Colors.grey[500],
            ),
          ),
        ),
        trailing:
        Icon(Icons.schedule, color: Theme.of(context).colorScheme.primary),
        onTap: () async {
          final initial = time ?? defaultTime;

          final picked = await _showAlarmStyleTimePicker(
            context,
            initial: initial,
            minuteInterval: 5,
            title: label,
          );

          if (picked != null) onSelect(picked);
        },
      ),
    );
  }

  // =========================
  // ✅ 포스터 영역 (네 코드 유지)
  // =========================
  Widget _buildPosterArea(ThemeData theme) {
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
                child: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: _pickPoster,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
}

/// 콤마 포매터
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

/// 공동주최자 이메일 입력 위젯
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
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: IconButton(
                  icon: Icon(Icons.add_circle, color: theme.colorScheme.primary),
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
                  label: Text(email, style: const TextStyle(fontSize: 14)),
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
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
    final isValid =
    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);

    final exists =
    _emails.any((e) => e.trim().toLowerCase() == email.toLowerCase());

    if (email.isNotEmpty && isValid && !exists) {
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
