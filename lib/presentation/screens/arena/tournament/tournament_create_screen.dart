// lib/presentation/screens/arena/tournament/tournament_create_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/services/storage_service.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class TournamentCreateScreen extends ConsumerStatefulWidget {
  const TournamentCreateScreen({super.key});

  @override
  ConsumerState<TournamentCreateScreen> createState() =>
      _TournamentCreateScreenState();
}

class _TournamentCreateScreenState extends ConsumerState<TournamentCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _hostNameCtrl = TextEditingController();
  final _hostPhoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  List<String> _coOrganizers = [];

  // ✅ 날짜/시간 분리
  DateTime? _eventDay;
  TimeOfDay? _eventTime;
  DateTime? _entryStartDay;
  DateTime? _entryEndDay;

  File? _posterFile;
  bool _isUploading = false;

  bool get _canSubmit =>
      _titleCtrl.text.trim().isNotEmpty &&
          _locationCtrl.text.trim().isNotEmpty &&
          _hostNameCtrl.text.trim().isNotEmpty &&
          _hostPhoneCtrl.text.trim().isNotEmpty &&
          _feeCtrl.text.trim().isNotEmpty &&
          _maxCtrl.text.trim().isNotEmpty &&
          _eventDay != null &&
          _eventTime != null &&
          _entryStartDay != null &&
          _entryEndDay != null;

  @override
  void initState() {
    super.initState();

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

  DateTime _today0() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _clampToToday(DateTime d) {
    final today = _today0();
    return d.isBefore(today) ? today : d;
  }

  // =========================
  // ✅ 알람 스타일(휠) 시간 선택기
  // =========================
  Future<TimeOfDay?> _showAlarmStyleTimePicker(
      BuildContext context, {
        required TimeOfDay initial,
        int minuteInterval = 5,
        String title = '대회 시간',
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
                              (i * minuteInterval).toString().padLeft(2, '0'),
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
    if (_isUploading) return;
    if (!_formKey.currentState!.validate()) return;

    if (_eventDay == null ||
        _eventTime == null ||
        _entryStartDay == null ||
        _entryEndDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('대회 날짜/시간과 엔트리 시작/마감 날짜를 모두 선택해주세요'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = sl<FirebaseAuth>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 후 대회 개설이 가능합니다'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final eventDateTime = _combineDayTime(_eventDay!, _eventTime!);
    final entryStart = _entryStartDateTime();
    final entryEnd = _entryEndDateTime();

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

    setState(() => _isUploading = true);

    try {
      String? posterUrl;
      if (_posterFile != null) {
        posterUrl = await sl<StorageService>().uploadFile(
          _posterFile!.path,
          'tournaments/posters',
        );
      }

      final repo = sl<ArenaRepository>();

      final maxText = _maxCtrl.text.replaceAll(',', '').trim().toLowerCase();
      final int maxParticipants = (maxText == '무제한' || maxText == '0')
          ? 9999
          : (int.tryParse(maxText) ?? 64);

      final int entryFee =
          int.tryParse(_feeCtrl.text.replaceAll(',', '').trim()) ?? 0;

      // organizerEmails: 유효한 이메일만 + 중복 제거
      final List<String> organizerEmails = <String>[
        if ((user.email ?? '').trim().isNotEmpty) (user.email!).trim(),
        ..._coOrganizers.map((e) => e.trim()).where((e) => e.isNotEmpty),
      ].toSet().toList();

      final tournament = TournamentModel(
        title: _titleCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        maxParticipants: maxParticipants,
        posterUrl: posterUrl,
        entryFee: entryFee,

        eventDate: Timestamp.fromDate(eventDateTime),
        entryStartDate: Timestamp.fromDate(entryStart),
        entryEndDate: Timestamp.fromDate(entryEnd),

        createdByUid: user.uid,
        organizerEmails: organizerEmails,
        hostName: _hostNameCtrl.text.trim(),
        hostPhone: _hostPhoneCtrl.text.trim(),
        createdAt: Timestamp.now(),

        // ✅ Cloud Functions / UI 호환 필드들
        entrySummarySent: false,
        entryCount: 0,
        isCanceled: false,
      );

      // ✅ id 반환 받기 (나중에 바로 상세로 보내거나 디버깅에 유용)
      final newId = await repo.createTournament(tournament);

      if (!mounted) return;

      // ✅ pop 전에 먼저 안내 (context 안정)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('대회 개설 완료!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, newId);
    } catch (e) {
      if (!mounted) return;
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
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickPoster,
                  child: _posterFile != null
                      ? _buildPosterPreview(theme)
                      : _buildPosterPlaceholder(theme),
                ),
                const SizedBox(height: 24),

                // 기본 정보
                AppCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('기본 정보'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: '대회명',
                          hintText: '예: SUPER LEAGUE SEASON 9',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? '대회명을 입력해주세요'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _locationCtrl,
                        decoration: const InputDecoration(
                          labelText: '장소',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? '장소를 입력해주세요' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _hostNameCtrl,
                        decoration: const InputDecoration(
                          labelText: '담당자 이름',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? '담당자 이름을 입력해주세요'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _hostPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: '담당자 연락처',
                          hintText: '예: 010-1234-5678',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? '담당자 연락처를 입력해주세요'
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '※ 참가자 문의는 이 연락처로 안내됩니다.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 참가 설정
                AppCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('참가 설정'),
                      const SizedBox(height: 12),
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
                                  vertical: 14,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return '필수 입력';
                                }
                                final fee =
                                int.tryParse(v.replaceAll(',', '').trim());
                                if (fee == null || fee < 0) return '0원 이상';
                                if (fee > 0 && fee % 1000 != 0) return '1,000원 단위로 입력';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _maxCtrl,
                              // ✅ "무제한" 입력을 위해 텍스트 키보드로
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                labelText: '최대 인원',
                                hintText: '예: 64 또는 무제한',
                                prefixIcon: Icon(Icons.groups_outlined),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return '필수 입력';
                                final cleaned =
                                v.replaceAll(',', '').trim().toLowerCase();
                                if (cleaned == '무제한') return null;
                                final n = int.tryParse(cleaned);
                                if (n == null || n < 2) return '2명 이상 또는 "무제한"';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 날짜 설정
                AppCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('날짜 설정'),
                      const SizedBox(height: 8),
                      Text(
                        '✅ 대회는 날짜/시간을 따로 선택합니다.\n'
                            '✅ 엔트리 시작은 00:00, 마감은 23:59로 자동 처리됩니다.\n'
                            '📩 엔트리 마감 시, 참가자 정보 요약이 주최자(공동주최자 포함) 이메일로 자동 전송됩니다.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildDayTile(
                        label: '대회 날짜',
                        day: _eventDay,
                        leadingColor: Colors.orange,
                        leadingIcon: Icons.calendar_month,
                        onSelect: (pickedDay) {
                          setState(() {
                            _eventDay = _stripToDay(pickedDay);
                            _eventTime ??= const TimeOfDay(hour: 9, minute: 0);

                            // ✅ 자동 추천: 과거로 떨어지지 않게 today로 clamp
                            final d = _eventDay!;
                            final start = _clampToToday(d.subtract(const Duration(days: 10)));
                            final end = _clampToToday(d.subtract(const Duration(days: 3)));

                            _entryStartDay = _stripToDay(start);

                            // end가 start보다 과거면 start로 끌어올림
                            final safeEnd = end.isBefore(start) ? start : end;
                            _entryEndDay = _stripToDay(safeEnd);
                          });
                        },
                      ),
                      const SizedBox(height: 8),

                      _buildTimeTile(
                        label: '대회 시간',
                        time: _eventTime,
                        leadingColor: Colors.orange,
                        leadingIcon: Icons.access_time,
                        defaultTime: const TimeOfDay(hour: 9, minute: 0),
                        onSelect: (t) => setState(() => _eventTime = t),
                      ),
                      const SizedBox(height: 8),

                      _buildDayTile(
                        label: '엔트리 시작 날짜',
                        day: _entryStartDay,
                        leadingColor: Colors.green,
                        leadingIcon: Icons.play_circle_outline,
                        subtitleBuilder: (d) => '${_formatDay(d)}  00:00',
                        onSelect: (d) => setState(() => _entryStartDay = _stripToDay(d)),
                      ),
                      const SizedBox(height: 8),

                      _buildDayTile(
                        label: '엔트리 마감 날짜',
                        day: _entryEndDay,
                        leadingColor: Colors.green,
                        leadingIcon: Icons.stop_circle_outlined,
                        subtitleBuilder: (d) => '${_formatDay(d)}  23:59',
                        onSelect: (d) => setState(() => _entryEndDay = _stripToDay(d)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 상세 안내
                AppCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('상세 안내'),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descCtrl,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText: '대회 규칙, 상금, 경기 방식, 시상, 유의사항 등을 자세히 작성해주세요',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13.5,
                          ),
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
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 공동주최자
                AppCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: _CoOrganizerInput(
                    onChanged: (list) => _coOrganizers = list,
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),

      // 하단 버튼
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmit && !_isUploading ? _submit : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                '대회 개설하기',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────── helper widgets ─────────────────

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16.5,
      ),
    );
  }

  Widget _buildDayTile({
    required String label,
    required DateTime? day,
    required Color leadingColor,
    required IconData leadingIcon,
    required Function(DateTime pickedDay) onSelect,
    String Function(DateTime d)? subtitleBuilder,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: leadingColor.withOpacity(0.1),
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
              fontSize: 14.5,
              color: day != null ? Colors.black87 : Colors.grey[500],
            ),
          ),
        ),
        trailing: Icon(
          Icons.calendar_today,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: () async {
          final base = day ?? DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: base,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) onSelect(picked);
        },
      ),
    );
  }

  Widget _buildTimeTile({
    required String label,
    required TimeOfDay? time,
    required Color leadingColor,
    required IconData leadingIcon,
    required TimeOfDay defaultTime,
    required Function(TimeOfDay picked) onSelect,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: leadingColor.withOpacity(0.1),
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
              fontSize: 14.5,
              color: time != null ? Colors.black87 : Colors.grey[500],
            ),
          ),
        ),
        trailing: Icon(
          Icons.schedule,
          color: Theme.of(context).colorScheme.primary,
        ),
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
            '포스터 추가하기',
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

  Widget _buildPosterPreview(ThemeData theme) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            _posterFile!,
            width: double.infinity,
            height: 280,
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
                children: [
                  Icon(
                    Icons.photo_library,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
        const SizedBox(height: 12),
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            hintText: 'example@gmail.com',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.add_circle, color: theme.colorScheme.primary),
              onPressed: _addEmail,
            ),
          ),
          onSubmitted: (_) => _addEmail(),
        ),
        const SizedBox(height: 12),
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
    );
  }

  void _addEmail() {
    final email = _ctrl.text.trim();
    final isValid =
    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);

    if (email.isNotEmpty && isValid && !_emails.contains(email)) {
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
